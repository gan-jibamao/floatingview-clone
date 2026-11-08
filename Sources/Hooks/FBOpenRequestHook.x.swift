// FBOpenRequestHook.swift
// 对应原版：floatingView.FBSSOARHook : ClassHook<FBSystemServiceOpenApplicationRequest>
// 职责：拦截「打开应用」请求，改写为浮窗打开（通用链接场景）

import Orion

class FBSSOARHook: ClassHook<FBSystemServiceOpenApplicationRequest> {
    typealias Group = FVGroup

    func _setPresentationContext(_ ctx: AnyObject) {
        guard FVPrefsStore.shared.bool(FVKey.universeLinkOpenFloat) else {
            orig._setPresentationContext(ctx); return
        }
        if let bid = target.value(forKey: "bundleIdentifier") as? String,
           !FVPrefsStore.shared.array(FVKey.universeExcludedApps, as: String.self).contains(bid) {
            FVAmbient.shared.openInFloatingView(bundleIdentifier: bid)
            return
        }
        orig._setPresentationContext(ctx)
    }
}
