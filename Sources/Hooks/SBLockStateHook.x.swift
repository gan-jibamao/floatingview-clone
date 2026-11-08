// SBLockStateHook.swift
// 对应原版：floatingView.SBLSAHook : ClassHook<SBLockStateAggregator>
// 职责：锁屏时隐藏所有浮窗，解锁恢复（原版用 valueForKey: 读状态）

import Orion

class SBLSAHook: ClassHook<SBLockStateAggregator> {
    typealias Group = FVGroup

    func lockStateAggregate(_ agg: AnyObject) {
        orig.lockStateAggregate(agg)
        let locked = (agg.value(forKey: "isUserLocked") as? NSNumber)?.boolValue ?? false
        FVAmbient.shared.setAllHidden(locked)
    }
}
