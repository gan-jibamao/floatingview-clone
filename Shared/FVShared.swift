// FVShared.swift —— 主 dylib 与设置 bundle 共用的最小层
//
// 设置面板跑在 Settings.app 进程里，SpringBoard 在另一个进程。
// NotificationCenter.default 跨不了进程，所以这里走 Darwin notify：
//   - 名字就是事件名
//   - 字符串载荷放 object（Darwin 会把它塞进 userInfo["object"] 带过去）
//   - 发送端同时在本进程 post 一份，方便同进程观察者

import Foundation
import UIKit

// MARK: - 通知事件（两端共用同一套 name）

public enum FVNotificationEvent: String, CaseIterable {
    case openFloatingView             = "fv_openFloatingView"
    case openFloatingViewToSide       = "fv_openFloatingView_toSide"
    case openFloatingViewLastRun      = "fv_openFloatingView_lastRun"
    case closeMainFloatingApp         = "fv_closeMainFloatingApp"
    case toggleMainFloatingAppDisplay = "fv_toggleMainFloatingAppDisplay"

    /// 诊断：让 SpringBoard 重新扫一遍钩子并把报告落盘
    case runDiagnostics               = "fv_runDiagnostics"
    /// 诊断：10 秒 IOHID 原始事件转储
    case runIOHIDProbe                = "fv_runIOHIDProbe"
}

public enum FVNotify {

    private final class Box {
        let handler: (String?) -> Void
        init(_ h: @escaping (String?) -> Void) { handler = h }
    }

    private static var boxes: [String: Box] = [:]

    /// 往 Darwin 通知总线发一条；同进程的观察者另走 NotificationCenter。
    /// 注意：Darwin 带不了复杂 userInfo，payload 只在同进程内有效。
    public static func post(_ e: FVNotificationEvent, payload: String? = nil) {
        FVPostDarwin(e.rawValue)
        NotificationCenter.default.post(name: Notification.Name(e.rawValue), object: payload)
    }

    public static func observe(_ e: FVNotificationEvent, _ handler: @escaping (String?) -> Void) {
        boxes[e.rawValue] = Box(handler)          // 保活
        FVObserveDarwin(e.rawValue) { name in
            FVNotify.dispatch(String(cString: name))
        }
        // 本进程内也收一份（带 payload）
        NotificationCenter.default.addObserver(
            forName: Notification.Name(e.rawValue), object: nil, queue: .main
        ) { n in handler(n.object as? String) }
    }

    fileprivate static func dispatch(_ name: String) {
        boxes[name]?.handler(nil)
    }
}

// MARK: - UIColor <-> "#RRGGBB"

public extension UIColor {
    /// 原版颜色格式：`#RRGGBB` 或 `#RRGGBBAA`，也吃不带 `#` 的
    convenience init?(fvHex: String) {
        var h = fvHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6 || h.count == 8, let v = UInt64(h, radix: 16) else { return nil }
        let r, g, b, a: CGFloat
        if h.count == 8 {
            r = CGFloat((v >> 24) & 0xFF) / 255
            g = CGFloat((v >> 16) & 0xFF) / 255
            b = CGFloat((v >> 8) & 0xFF) / 255
            a = CGFloat(v & 0xFF) / 255
        } else {
            r = CGFloat((v >> 16) & 0xFF) / 255
            g = CGFloat((v >> 8) & 0xFF) / 255
            b = CGFloat(v & 0xFF) / 255
            a = 1
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    var fvHex: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return "#000000" }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
