# floatingView 1.6.0-6 逆向成果包

**包名**：`com.be-huge.floating-view`，作者 be-huge，Tweak 段 `Library/MobileSubstrate/DynamicLibraries`
**架构**：`iphoneos-arm64e`，二进制为 `arm64 + arm64e` 胖二进制
**最低系统**：iOS 12.2（`LC_BUILD_VERSION` MinOS 15.0，SDK 16.4，ld 857.1）
**依赖**：`dev.theos.orion`（Orion，Swift hook 框架）

> 说明：**没有原始源码**可还原。作者编译时 strip 了绝大多数 Swift 符号名与方法名，
> 本目录是由 Mach-O 元数据 + 反编译产物重建的**可考证接口骨架**与**分析索引**，
> 能给出类结构、字段、方法列表、钩子目标、偏好键、UI 文案与逐函数反编译，但**不含原始实现代码**。

## 目录

| 文件 | 内容 |
|---|---|
| `orion_hooks.md` | 16 个 Orion 钩子类 → 被挂钩的 SpringBoard/FrontBoard/UIKit 私有类 |
| `class_index.md` | 70 个 ObjC 可见类 + 181 个 ObjC 方法（含 dylib 内偏移地址） |
| `prefs_class_index.md` | 设置面板 34 个 ObjC 类 + 271 个方法 |
| `swift_types_index.md` | 130 个 Swift 类型的字段/方法/枚举用例 |
| `reconstructed_floatingView_interfaces.swift` | 重建的 Swift 接口骨架（可直接对照汇编阅读） |
| `floatingView_objc_dump_with_addr.txt` | 完整 ObjC 类转储（ivar 偏移 + 方法地址） |
| `floatingView_swift_metadata.txt` | 原始 Swift 元数据转储（含被剥离方法占位） |
| `floatingView_selectors.txt` | 601 条 ObjC selector（即调用了哪些系统 API） |
| `floatingView_ui_strings_zh.txt` | dylib 内中文字面量（功能开关名/提示语） |
| `prefs_ui_strings_zh.txt` | 设置面板 244 条中文文案（即完整功能清单） |
| `prefs_keys.txt` | 308 个偏好键（`com.be-huge.floating-view-prefs.plist` 的 schema） |
| `decompiled_floatingView.pdc.txt` | **3607 个函数**的 r2 pdc 反编译（6.1 MB，按 `method.floatingView.类名.` 检索） |
| `decompiled_prefs.pdc.txt` | 设置 bundle `floatingViewPrefs` 1242 个函数反编译 |
| `decompiled_keyboard.pdc.txt` / `decompiled_camera.pdc.txt` | 键盘与相机两个小 dylib 的反编译 |
| `ARCHITECTURE.md` | 架构、窗口层级、调用链、事件采集（含 6 张 Mermaid 图） |
| **`DEEP_DIVE_INDEX.md`** | **★★ 深度报告总索引**：算法级 + 26 页 + 30 组件（3672 行） |
| `DEEP_DIVE_ALGORITHMS.md` | 6 个核心算法到汇编级 + 全部数值常量（526 行） |
| `DEEP_DIVE_SETTINGS.md` | 26 个设置页逐个实现 + 控件矩阵（1994 行） |
| `DEEP_DIVE_COMPONENTS.md` | 30+ UI 组件逐个实现 + 难度分级（1152 行） |
| `DEEP_DIVE_DISPATCH.md` | FVAppDispatchView 17 方法逐字节解剖（711 行） |
| **`DEEP_DIVE_ORION_PITFALLS.md`** | **★★ Orion 5 个致命坑**（447 行，写错能编译但不生效） |
| **`FEATURE_HANDBOOK_INDEX.md`** | **★★ 功能级实现手册总索引**：60+ 功能，每功能四段式（实现什么/逆向怎么找/证据/怎么实现+坑） |
| `FEATURE_HANDBOOK_PART1.md` | 逆向方法论 + 基础设施（618 行） |
| `FEATURE_HANDBOOK_PART2.md` | 浮窗核心：FBScene 嵌入 / 手势 / 持久化（590 行） |
| `FEATURE_HANDBOOK_PART3.md` | 输入层 + 环形菜单 + 侧边栏（480 行） |
| `FEATURE_HANDBOOK_PART4.md` | 三屏调度 + 32 个系统功能（537 行） |
| `FEATURE_HANDBOOK_PART5.md` | 16 个钩子 + 26 页设置面板（565 行） |
| `IMPLEMENTATION.md` | 11 个机制的浓缩版概览 |
| `SETTINGS_TREE.md` | **设置面板完整结构树**：26 个页面 + 10 个 cell 类型 + 94 个键 + 32 个动作 |
| `AI_REPLICATION_PROMPT.md` | **给 AI 的复刻任务书**：12 个任务的详细规格 + 验收清单 |
| `skeleton/` | **可编译工程骨架**：61 个 Swift 文件 / 4200 行 |
| `FEATURES.md` | 功能清单（由设置面板 244 条中文文案 + 308 个偏好键反推） |
| `bin/` | 瘦身后的 arm64e 二进制、filter plist、control、原始 deb |
| `raw/` | 未整理的原始转储（含地址版 ObjC dump、全 selector 表） |

## 二进制规模

- `floatingView.dylib`：1.65 MB（fat）→ arm64e 835 KB / arm64 786 KB
- 函数：**3607**（其中 309 个外部导入、350 个 ObjC 方法、2925 个 Swift 内部函数）
- ObjC 类 70 / Swift 类型 145（索引列出 130 个可读类型，另 17 组为 Orion `_Glue` 自动生成）/ Swift 协议 3 / ObjC selector 601 / C 字符量 608
- `FloatingViewKeyboard.dylib`：16 KB，37 个函数，仅监听 Darwin 通知 `com.be-huge.floating-view-keyboard.dismiss`
- `floatingViewCamera.dylib`：68 KB，162 个函数，注入 `mediaserverd`，判断相机权限 + 读取 `SystemVersion.plist`
- `floatingViewPrefs.bundle/floatingViewPrefs`：943 KB，34 个 ObjC 类 + 47 个 Swift 类型，其中 26 个 `PSListController` 子类

## 如何继续深挖

```sh
# 找某个类的方法实现
grep -n "method.floatingView.FVAppDispatchItem" decompiled_floatingView.pdc.txt

# 在真机上跳到某个地址（相对 dylib 基址）
r2 -e bin.relocs.apply=true -c "aa; s 0x3d938; pdf" floatingView.arm64e
```

注意：作者保留了 `__TEXT,__swift5_types/fieldmd/protos/capture` 段，
所以**类/字段/方法签名/协议一致性**可完整恢复；但 `__objc_methname` 只暴露了系统 selector，
自定义方法名已在 `swift5` 元数据中被 strip（转储里显示为 `<stripped>` 或 `sub_xxxx`）。
若要恢复控制流，需对 `sub_xxxx` 按 xref 手工还原（本包已给出全部反编译与 xref 标注）。

## 附带的最大疑点：`wlist/ssssvpbmd.txt`

设置 bundle 里带了一个 330 KB 的 `wlist/ssssvpbmd.txt`，内容是 JSON 数组，共 **1062** 项，格式为

```
["<32位hex>:<64位hex>", ...]
```

即「标识 : 哈希」对。主 dylib 与 prefs 二进制的字符串表里都**没有** `wlist` / `ssssvpbmd` 路径字样（`strings` 与 `rabin2 -z` 均无命中），因此它不太可能由代码拼接路径读取，更像是安装时随包分发的数据文件。
从形态（1062 个 32 位 ID 各自对应一个 64 位哈希）看，最可能是作者的**授权/白名单校验表**（32 位可能是设备标识或业务码指纹，64 位是摘要）。
若你关心隐私与授权逻辑，这一项值得单独深挖；本包仅做结构确认与解码，未做逆向破解。
