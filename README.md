# floatingViewClone

[![build](https://github.com/gan-jibamao/floatingview-clone/actions/workflows/build.yml/badge.svg)](https://github.com/gan-jibamao/floatingview-clone/actions/workflows/build.yml)

`floatingView 1.6.0-6`（`com.be-huge.floating-view`）的**同构复刻工程**。
不是原作者源码——原始二进制被 strip 了全部自定义符号，本工程由 Mach-O 元数据 + 反编译产物重建。

目标：**能真编译、能出 .deb 的工程**，而不是只读得爽的分析文档。

## 现状

| 模块 | 状态 |
|---|---|
| 编译 / 打包 | ✅ CI 全绿，产出 arm64+arm64e 胖二进制 deb |
| 偏好层（键 / 默认值 / Darwin 热重载） | 完整 |
| 环形菜单 / 侧边栏 / 浮窗卡片 | 完整 |
| 三层窗口 / IOHID 采集 / FBScene 嵌入 | 完整 |
| 15 个 Orion hook | 骨架 + 关键逻辑 |
| 设置面板 | 框架 + 26 页结构 |
| 私有 API | `stubs/FVPrivate.h` 提供编译期声明 |

规模：**69 个 Swift 文件 / 5976 行**。

> 注：行文中常被引用的「16 个钩子」实际是 15 个——第 16 项是把 `Tweak` 协议里的
> `typealias Group` 误当钩子数进去的，那行本身在 Orion 里不成立，已删。

## 构建

依赖 **Orion**（Swift hook DSL）与 theos。

```sh
git clone --recursive --depth 1 https://github.com/theos/theos.git "$THEOS"
git clone --depth 1 https://github.com/theos/sdks.git "$THEOS/sdks"
git clone --depth 1 --branch 1.0.2 https://github.com/theos/orion.git "$THEOS/vendor/orion"
# Linux 还需要宿主 Swift 5.8 交叉工具链（macOS 用 Xcode 自带的）
make package FINALPACKAGE=1
```

CI 见 `.github/workflows/build.yml`。

**为什么是 ubuntu 而不是 macos runner**：这个账号上 `runs-on: macos-14` 的任务会在
启动后 0 步被直接 cancelled（配额/计费），`ubuntu-22.04` 正常。Orion 官方支持 Linux
构建，代价是要装宿主 Swift 工具链（`swift-5.8-ubuntu20.04.tar.xz`）。

## 为什么需要 `stubs/`

骨架要引 15 个系统私有类（`SBMainWorkspace`、`FBScene`、`SBIconView`…），
而 iPhoneOS SDK 只给 `.tbd` 不给头文件。

`stubs/FVPrivate.h` 只做**声明**，不产生类符号——运行时用的仍是系统框架里的真类，
所以不会出现 `Class X is implemented in both …`。两类例外要留心：

- `_UIKeyboardLayerHostView` / `UIKeyboardSceneDelegate`：SDK 的 UIKit 私有头里已经有了，
  我们不能再声明（否则 `duplicate interface definition`）。
- `PSButtonCell` / `PSLinkCell` 等：`Preferences.tbd` **没有导出**这些类，
  `.self` 引用会在链接期报 undefined symbol → 改走 `NSClassFromString` + 回退 `PSTableCell`。

门禁：`python3 tools/check_stubs.py`，每个 `ClassHook<T>` 与 `orig.sel(` 都必须能在桩头里找到。

## 目录

```
Sources/            主 dylib（Orion hook 在 Hooks/*.x.swift）
Shared/             主 dylib 与设置 bundle 共用（通知事件、颜色解析）
prefs/              设置面板 bundle
stubs/FVPrivate.h   私有 API 编译期桩头
tools/              桩头门禁
layout/             安装布局
```

## 许可

复刻产物，仅用于学习与研究。原作者 `be-huge`，原包 `com.be-huge.floating-view`。
