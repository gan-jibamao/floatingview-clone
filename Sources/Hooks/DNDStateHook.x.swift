// DNDStateHook.swift
// 对应原版：floatingView.DNDSHook : ClassHook<DNDState>
// 职责：勿扰模式状态同步到工具图标（arc 菜单里的勿扰按钮要反映真实状态）

import Orion

class DNDSHook: ClassHook<DNDState> {
    typealias Group = FVGroup

    func activeModeConfiguration() -> AnyObject? {
        let cfg = orig.activeModeConfiguration()
        let active = cfg != nil
        FVAmbient.shared.setDNDActive(active)
        return cfg
    }
}
