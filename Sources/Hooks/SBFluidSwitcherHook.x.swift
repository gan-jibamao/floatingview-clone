// SBFluidSwitcherHook.swift
// 对应原版：floatingView.SBFSGMHook : ClassHook<SBFluidSwitcherGestureManager>（3 个方法）
// 职责：底部横条手势结束后，把前台应用浮窗化

import Orion

class SBFSGMHook: ClassHook<SBFluidSwitcherGestureManager> {
    typealias Group = FVGroup

    func grabberTongueCanceledPulling(_ tongue: AnyObject,
                                      withDistance distance: Double,
                                      andVelocity velocity: Double,
                                      andGesture gesture: AnyObject) {
        orig.grabberTongueCanceledPulling(tongue, withDistance: distance,
                                          andVelocity: velocity, andGesture: gesture)
        guard FVPrefsStore.shared.bool(FVKey.switcherEndedEvent) else { return }
        FVAmbient.shared.floatFrontApplication()
    }
}
