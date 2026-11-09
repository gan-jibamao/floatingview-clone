// FVHookAudit.swift —— 真机自检
//
// 骨架里的 selector 是按反编译推的，谁都不敢保证在这个系统版本上还在。
// 这个模块在 SpringBoard 里逐个去问运行时：
//   这个类存在吗？这个方法存在吗？挂在哪个父类上？
// 结果写到 /var/mobile/Library/FloatingViewInfo/hook-audit.txt，设置面板直接读。

import Foundation
import UIKit
import ObjectiveC

public enum FVHookAudit {

    public struct Spec {
        public let cls: String
        public let sels: [String]
        public init(_ cls: String, _ sels: [String]) {
            self.cls = cls
            self.sels = sels
        }
    }

    /// 与 Sources/Hooks/*.x.swift 一一对应。
    /// 改钩子时这张表必须一起改，否则报告会在骗自己。
    public static let specs: [Spec] = [
        Spec("SpringBoard", ["applicationDidFinishLaunching:"]),
        Spec("SBApplication", ["invalidate"]),
        Spec("SBIconView", ["configurationForIcon:configuration:context:"]),
        Spec("SBMainWorkspace", ["_addAppLayoutToFront:", "_removeAppLayout:forReason:"]),
        Spec("SBLockStateAggregator", ["lockStateAggregate:"]),
        Spec("SBFluidSwitcherGestureManager",
             ["grabberTongueCanceledPulling:withDistance:andVelocity:andGesture:"]),
        Spec("FBScene", ["invalidate", "_setPresentationContext:"]),
        Spec("FBSystemServiceOpenApplicationRequest", ["_setPresentationContext:"]),
        Spec("DNDState", ["activeModeConfiguration"]),
        Spec("BNContentViewController", ["viewWillAppear:"]),
        Spec("NCNotificationShortLookViewController", ["viewWillAppear:"]),
        Spec("UIRootSceneWindow", ["didAddSubview:"]),
        Spec("_UIKeyboardLayerHostView", ["setFrame:"]),
        Spec("UIKeyboardSceneDelegate", ["keyboardFrameDidChange"]),
        Spec("UIUndoGestureInteraction", ["_handlePan:"]),
    ]

    public private(set) static var lastSummary = "尚未运行"

    private static func pad(_ s: String, _ width: Int) -> String {
        if s.count >= width { return s }
        return s + String(repeating: " ", count: width - s.count)
    }

    @discardableResult
    public static func run(reason: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var lines: [String] = []
        var hit = 0, missClass = 0, missSel = 0

        for spec in specs {
            guard let cls: AnyClass = NSClassFromString(spec.cls) else {
                missClass += 1
                lines.append("[缺类  ] \(pad(spec.cls, 38)) 这个进程里没有这个类")
                continue
            }
            let sup = class_getSuperclass(cls).map { NSStringFromClass($0) } ?? "-"
            for sel in spec.sels {
                let s = NSSelectorFromString(sel)
                let inst = class_getInstanceMethod(cls, s) != nil
                let meta = class_getClassMethod(cls, s) != nil
                if inst || meta {
                    hit += 1
                    lines.append("[命中  ] \(pad(spec.cls, 38)) \(pad(sel, 62)) <- \(sup)")
                } else {
                    missSel += 1
                    lines.append("[缺方法] \(pad(spec.cls, 38)) \(pad(sel, 62)) <- \(sup)")
                }
            }
        }

        let total = specs.reduce(0) { $0 + $1.sels.count }
        let summary = "命中 \(hit)/\(total)  缺类 \(missClass)  缺方法 \(missSel)"

        let report = """
        # floatingViewClone 自检报告

        时间      : \(fmt.string(from: Date()))
        原因      : \(reason)
        进程      : \(ProcessInfo.processInfo.processName) (pid \(getpid()))
        系统      : \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
        机型      : \(UIDevice.current.model)
        汇总      : \(summary)

        ## 逐项

        \(lines.joined(separator: "\n"))

        ## 字段含义

        [命中  ]  类在、方法在 -> Orion 能挂钩
        [缺方法]  类在、方法不在 -> selector 名字或参数个数猜错了，需要按 class-dump 校准
        [缺类  ]  类都不在 -> 该框架没加载，或类名猜错
        """

        FVFileManager.write(report, name: "hook-audit.txt")
        lastSummary = summary
        FVLog.info("自检(\(reason)): \(summary)")
        return report
    }
}
