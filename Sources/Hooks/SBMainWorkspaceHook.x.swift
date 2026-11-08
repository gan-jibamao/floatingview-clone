// SBMainWorkspaceHook.swift
// 对应原版：floatingView.SBMWHook : ClassHook<SBMainWorkspace>
// 职责：拦截应用布局变化（启动/关闭），决定全屏还是浮窗

import Orion

class SBMWHook: ClassHook<SBMainWorkspace> {
    typealias Group = FVGroup

    func _addAppLayoutToFront(_ layout: AnyObject) {
        orig._addAppLayoutToFront(layout)
        FVAmbient.shared.onAppLayoutAdded(layout)
    }

    func _removeAppLayout(_ layout: AnyObject, forReason reason: Int64) {
        orig._removeAppLayout(layout, forReason: reason)
        FVAmbient.shared.onAppLayoutRemoved(layout)
    }
}
