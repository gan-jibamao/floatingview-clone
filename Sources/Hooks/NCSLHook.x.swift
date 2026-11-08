// NCSLHook.swift
// 对应原版：floatingView.NCNSLCHook : ClassHook<NCNotificationShortLookViewController>
// 职责：短横幅上的浮窗化入口（点击/下拉据此改道）

import Orion

class NCNSLCHook: ClassHook<NCNotificationShortLookViewController> {
    typealias Group = FVGroup

    func viewWillAppear(_ animated: Bool) {
        orig.viewWillAppear(animated)
        guard FVPrefsStore.shared.bool(FVKey.notifOpenFloat) else { return }
        FVAmbient.shared.registerShortLook(target)
    }
}
