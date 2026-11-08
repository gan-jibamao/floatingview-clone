# floatingViewClone

`floatingView 1.6.0-6`（`com.be-huge.floating-view`）的**同构复刻工程**。
不是原作者源码——原始二进制被 strip 了全部自定义符号，本工程由 Mach-O 元数据 + 反编译产物重建。

目标：**能真编译、能出 .deb 的工程**，而不是只读得爽的分析文档。

## 现状

| 模块 | 状态 |
|---|---|
| 偏好层（键 / 默认值 / Darwin 热重载） | 完整 |
| 环形菜单 / 侧边栏 / 浮窗卡片 | 完整 |
| 三层窗口 / IOHID 采集 / FBScene 嵌入 | 完整 |
| 15 个 Orion hook | 骨架 + 关键逻辑 |
| 设置面板 | 框架 + 26 页结构 |
| 私有 API | `stubs/FVPrivate.h` 提供编译期声明 |

## 构建

依赖 **Orion**（Swift hook DSL）与 theos。

```sh
git clone --recursive --depth 1 https://github.com/theos/theos.git "$THEOS"
curl -fsSL https://github.com/theos/sdks/tarball/master | tar -xz -C "$THEOS/sdks" --strip-components=1
git clone --depth 1 --branch 1.0.2 https://github.com/theos/orion.git "$THEOS/vendor/orion"
brew install ldid xz          # Linux: sudo apt install ldid xz-utils
make package FINALPACKAGE=1
```

CI 见 `.github/workflows/build.yml`（macos-14）。

## 为什么需要 `stubs/`

骨架要引 15 个系统私有类（`SBMainWorkspace`、`FBScene`、`SBIconView`…），
而 iPhoneOS SDK 只给 `.tbd` 不给头文件。

`stubs/FVPrivate.h` 只做**声明**，不产生类符号——运行时用的仍是系统框架里的真类，
所以不会出现 `Class X is implemented in both …`。

门禁：`python3 tools/check_stubs.py`，每个 `ClassHook<T>` 与 `orig.sel(` 都必须能在桩头里找到。

## 目录

```
Sources/            主 dylib（Orion hook 在 Hooks/*.x.swift）
prefs/              设置面板 bundle
stubs/FVPrivate.h   私有 API 编译期桩头
tools/              桩头门禁
layout/             安装布局
```

## 许可

复刻产物，仅用于学习与研究。原作者 `be-huge`，原包 `com.be-huge.floating-view`。
