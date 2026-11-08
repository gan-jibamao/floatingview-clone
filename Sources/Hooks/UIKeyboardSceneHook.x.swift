// UIKeyboardSceneHook.swift
// 对应原版：floatingView.UIKSDHook : ClassHook<UIKeyboardSceneDelegate>
// 职责：键盘场景切换（内/外置键盘）时通知浮窗做尺寸/位置调整

import Orion
import UIKit

class UIKSDHook: ClassHook<UIKeyboardSceneDelegate> {
    typealias Group = FVGroup

    func keyboardFrameDidChange() {
        orig.keyboardFrameDidChange()
        FVAmbient.shared.onKeyboardFrameChanged()
    }
}
