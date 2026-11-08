// FBSceneHook.swift
// 对应原版：floatingView.FBSHook : ClassHook<FBScene>（2 个方法）
// 职责：场景生命周期跟踪，确保解绑时不留僵尸容器

import Orion

class FBSHook: ClassHook<FBScene> {
    typealias Group = FVGroup

    func invalidate() {
        FVAmbient.shared.onSceneInvalidated(target)
        orig.invalidate()
    }
}
