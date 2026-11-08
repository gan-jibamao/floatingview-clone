// UIKeyboardLayerHook.swift
// 对应原版：floatingView._UIKLHVHook : ClassHook<_UIKeyboardLayerHostView>
// 职责：拿到 sceneLayer，让浮窗内容跟随键盘层移动

import Orion
import UIKit

class _UIKLHVHook: ClassHook<_UIKeyboardLayerHostView> {
    typealias Group = FVGroup

    func setFrame(_ frame: CGRect) {
        orig.setFrame(frame)
        FVAmbient.shared.onKeyboardLayerFrameChanged(frame)
    }
}
