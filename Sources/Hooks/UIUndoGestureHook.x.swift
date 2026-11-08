// UIUndoGestureHook.swift
// 对应原版：floatingView.UIUGIHook : ClassHook<UIUndoGestureInteraction>
// 职责：复用摇一摇/撤销手势通道做快捷动作

import Orion

class UIUGIHook: ClassHook<UIUndoGestureInteraction> {
    typealias Group = FVGroup

    func _handlePan(_ g: AnyObject) {
        // 原版在这里判定是否交给浮窗处理，否则走原逻辑
        if FVAmbient.shared.shouldConsumeUndoGesture(g) { return }
        orig._handlePan(g)
    }
}
