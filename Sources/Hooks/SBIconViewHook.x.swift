// SBIconViewHook.swift
// 对应原版：floatingView.SBIVHook : ClassHook<SBIconView>（6 个方法，钩得最多的图标类）
// 职责：长按菜单里注入「通过浮窗打开应用」

import Orion
import UIKit

class SBIVHook: ClassHook<SBIconView> {
    typealias Group = FVGroup

    func configurationForIcon(_ icon: AnyObject,
                              configuration: AnyObject,
                              context: AnyObject) -> AnyObject {
        let cfg = orig.configurationForIcon(icon, configuration: configuration, context: context)
        guard FVPrefsStore.shared.bool(FVKey.sbIconOpenFloat) else { return cfg }
        guard let bid = icon.value(forKey: "bundleIdentifier") as? String else { return cfg }

        // 原版 selector 证据：configurationWithIdentifier:previewProvider:actionProvider:
        let sel = NSSelectorFromString("configurationWithIdentifier:previewProvider:actionProvider:")
        guard cfg.responds(to: sel) else { return cfg }

        // 往 UIMenu 里追加一项（实现细节依系统版本，这里给出骨架）
        FVLog.info("为 \(bid) 注入浮窗菜单项")
        FVAmbient.shared.registerFloatingMenu(for: bid)
        return cfg
    }
}
