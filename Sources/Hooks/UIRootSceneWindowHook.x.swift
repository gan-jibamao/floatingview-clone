// UIRootSceneWindowHook.swift
// 对应原版：floatingView.USWHook : ClassHook<UIRootSceneWindow>（2 个方法）
// 职责：在 RootScene 层级插入侧边栏容器，确保在 Alert 之下、普通窗口之上

import Orion
import UIKit

class USWHook: ClassHook<UIRootSceneWindow> {
    typealias Group = FVGroup

    func didAddSubview(_ view: UIView) {
        orig.didAddSubview(view)
        FVAmbient.shared.attachSideBarIfNeeded(in: target)
    }
}
