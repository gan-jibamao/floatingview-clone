// Tweak.swift
// Orion 入口。对应原版：floatingView 的 tweak 声明部分（FVTweakInit / CManager）。
//
// Orion 的约定：
//   1. 所有 hook 类会被自动发现（同 module 内的 ClassHook<T> 子类）
//   2. 用 @_cdecl 的构造函数声明 tweak 组
//   3. 若需显式注册，可用 Orion.register(...)

import Orion

// 把 16 个 hook 归入同一组
struct FloatingViewTweak: Tweak {
    init() {
        FVLog.info("floatingViewClone 已加载")
    }
}
