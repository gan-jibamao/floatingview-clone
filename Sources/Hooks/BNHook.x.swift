// BNHook.swift
// 对应原版：floatingView.BNCVCHook : ClassHook<BNContentViewController>
// 职责：通知横幅容器 —— 记录通知，供「下拉/点击横幅打开浮窗」使用

import Orion
import UIKit

class BNCVCHook: ClassHook<BNContentViewController> {
    typealias Group = FVGroup

    func viewWillAppear(_ animated: Bool) {
        orig.viewWillAppear(animated)
        guard FVPrefsStore.shared.bool(FVKey.notifOpenFloat) else { return }
        FVAmbient.shared.registerBanner(target)
    }
}
