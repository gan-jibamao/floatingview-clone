// Tweak.swift
// Orion 入口。对应原版：floatingView 的 tweak 声明部分（FVTweakInit / CManager）。

import Orion
import UIKit

// 把 15 个 hook 归入同一组（组类型本身定义在 Hooks/SpringBoardHook.x.swift）
struct FloatingViewTweak: Tweak {

    init() {
        FVLog.info("floatingViewClone 已加载")

        // 设置面板发来的跨进程指令
        FVNotify.observe(.runDiagnostics) { _ in
            FVHookAudit.run(reason: "设置面板触发")
        }
        FVNotify.observe(.runIOHIDProbe) { _ in
            FVIOProbe.shared.start(seconds: 10)
        }

        // 启动后 3 秒等 SpringBoard 起来，再扫一遍钩子
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            FVHookAudit.run(reason: "launch+3s")
        }
    }

    func tweakDidActivate() {
        FVLog.info("Orion 组已激活")
        FVHookAudit.run(reason: "tweakDidActivate")
    }

    /// 默认实现是 handleErrorDefault，它会把整个进程干掉。
    /// 骨架的 selector 还没在真机校准过，一个失败不该带走 SpringBoard —— 只记录。
    static func handleError(_ error: OrionHookError) {
        FVLog.warn("Orion 钩子失败: \(error)")
    }
}
