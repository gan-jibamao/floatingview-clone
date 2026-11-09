# 真机校准手册

这个包是**按反编译重建的骨架**：能编译、能装、能在 SpringBoard 里加载，
但**钩子的 selector 和 IOHID 的字段号都还没在真机上验证过**。
这一页就是把它验出来的流程。

---

## 0. 前置

- 越狱设备（rootless / `/var/jb` 也可以，路径会自动适配）
- 已装 `dev.theos.orion` 运行时（≥ 1.0.0）
- 已装 `mobilesubstrate`（或 libhooker）、`preferenceloader`

## 1. 装包

```sh
dpkg -i com.example.floatingviewclone_0.1.1_iphoneos-arm64.deb
killall -9 SpringBoard
```

装完先别急着用功能——**第一步是看它有没有真的挂上**。

## 2. 第一次自检

打开 **设置 → floatingViewClone → 钩子自检**。

页面打开时会自动发一条 Darwin 通知让 SpringBoard 重扫，1.2 秒后读结果。
看到的是这样三态：

```
[命中  ] SBMainWorkspace    _addAppLayoutToFront:     <- NSObject
[缺方法] SBIconView         configurationForIcon:…    <- UIView
[缺类  ] DNDState           这个进程里没有这个类
```

含义：

| 标记 | 意思 | 怎么办 |
|---|---|---|
| `[命中]` | 类在、方法在 | Orion 能挂钩，可以往下测功能 |
| `[缺方法]` | 类在，但这个方法不在 | selector 名字或**参数个数**猜错了 → 见 §3 |
| `[缺类]` | 类都不在 | 框架没加载，或类名写错 → 见 §4 |

**先把这一页整体截图或把文件拷出来**，这是后面所有改动的依据。

文件路径：

```
/var/mobile/Library/FloatingViewInfo/hook-audit.txt
rootless: /var/jb/var/mobile/Library/FloatingViewInfo/hook-audit.txt
```

## 3. 校准 selector

`[缺方法]` 基本都是参数个数不对。最典型的三个：

| 类 | 骨架里写的 | 常见真身 |
|---|---|---|
| `SBFluidSwitcherGestureManager` | `grabberTongueCanceledPulling:` | `grabberTongueCanceledPulling:withDistance:andVelocity:andGesture:` |
| `SBMainWorkspace` | `_removeAppLayout:forReason:` | `_removeAppLayout:forReason:`（`reason` 是 `unsigned long long`） |
| `SBIconView` | `configurationForIcon:configuration:context:` | `configurationForIcon:configuration:context:`（签名对，但返回值可能是 `id<ISIconConfiguration>`） |

**查真身的办法**（任选）：

1. 本仓库上游那份逆向包里有 `floatingView_objc_dump_with_addr.txt` 与
   `floatingView_selectors.txt`——原版调用过的 selector 全在里面，按类名 grep。
2. 设备上装 `flexdecrypt` / `class-dump`，dump 目标二进制：
   ```sh
   class-dump -H /System/Library/PrivateFrameworks/FrontBoard.framework/FrontBoard -o /tmp/hdr
   ```
3. 直接在页面里看 `[命中]` 行的父类，反推该去哪找。

改完两处即可：`Sources/Hooks/xxx.x.swift` 的函数签名 + `stubs/FVPrivate.h` 的声明
（**两个必须同时改**，否则 `orig.` 会报没有这个成员）。

## 4. 校准 IOHID 字段

点页面左上 **IOHID 10s**，然后在屏幕上：

1. 从屏幕**左边缘**往右划一下
2. 从**底部**往上划一下
3. 正常点一下屏幕中间

10 秒后回来，页面会显示原始转储：

```
# 字段说明：t=相对秒  type=IOHIDEventGetType  n=子事件数
#          x=0x10000  y=0x10001  f2=0x10002  f3=0x10003  f4=0x10004
0.532 type=11 n=1 i=0 x=12.50 y=838.00 f2=1 f3=0 f4=0
0.548 type=11 n=1 i=0 x=18.75 y=836.50 f2=2 f3=0 f4=0
```

读法：

- **哪个字段跟着手指动** → 那就是 x / y（骨架假设 `0x10000` / `0x10001`）
- **哪个字段在按下/移动/抬起时变 1/2/3** → 那是相位（骨架假设 `0x10002`）
- 如果 `n=0` 一直出现，说明事件在**根事件**上，得把取子事件那段去掉

把这三行贴回来就能定字段号。

## 5. 已知的、大概率要改的地方

| 位置 | 现状 | 风险 |
|---|---|---|
| `FVIOEvent.handle` | `x=0x10000 y=0x10001 相位=0x10002` | 高，字段号是猜的 |
| `FVGestureUtils.phase` | 1/2/3/4 映射 began/moved/ended/cancelled | 高，同上 |
| `FVSceneHosting.attach` | `_setPresentationContext:` + `settings` | 中，私有 API 版本差异大 |
| `FVSmallComponents` | 窗口层级 27 / 28 | 低，常量来自二进制 |
| 15 个钩子 | 全部 | 见 §2 报告 |

## 6. 出问题时

**SpringBoard 崩了** → 看 `/var/mobile/Library/Logs/CrashReporter/SpringBoard-*.ips`，
最近那个就是。钩子失败已经被 `Tweak.handleError` 拦成日志，不会再带崩进程；
真崩基本是 `orig.` 调到了不存在的 selector。

**设置页打不开** → `killall -9 Preferences`，或看 Settings 的崩溃日志。
设置 bundle 不依赖主 dylib，崩了自己也能起来。

**完全没反应** → 先确认 dylib 有没有加载：

```sh
ls -l /var/jb/Library/MobileSubstrate/DynamicLibraries/floatingViewClone.dylib
```

再看 `hook-audit.txt` 的时间戳有没有更新——没更新说明 `Tweak.init` 都没跑到。

---

## 把结果发回来

最省事的方式：把 `hook-audit.txt` 和 `iohid-probe.txt` 两个文件内容贴出来。
有这两个，selector 和字段号就能定死，剩下的都是照表改。
