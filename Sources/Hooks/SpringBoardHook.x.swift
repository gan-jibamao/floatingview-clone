// SpringBoardHook.swift
// 对应原版：floatingView.SBHook : ClassHook<SpringBoard>（3 个方法）
// 职责：应用启动完成 → 初始化全套子系统

import Orion
import UIKit

struct FVGroup: HookGroup {}

class SpringBoardHook: ClassHook<SpringBoard> {
    typealias Group = FVGroup

    func applicationDidFinishLaunching(_ application: UIApplication) {
        orig.applicationDidFinishLaunching(application)
        FVBootstrap.shared.start()
    }
}
