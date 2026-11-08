// SBApplicationHook.swift
// 对应原版：floatingView.SBAHook : ClassHook<SBApplication>
// 职责：跟踪当前正在浮窗化的应用（读 bundleIdentifier 登记/移除）

import Orion

class SBAHook: ClassHook<SBApplication> {
    typealias Group = FVGroup

    func invalidate() {
        // 应用被系统回收时，清掉对应浮窗
        if let bid = target.bundleIdentifier {
            FVAmbient.shared.closeFloatingView(for: bid)
        }
        orig.invalidate()
    }
}
