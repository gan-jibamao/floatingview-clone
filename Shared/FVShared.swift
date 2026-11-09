// FVShared.swift —— 主 dylib 与设置 bundle 共用的最小层
//
// 设置面板是独立进程（Settings.app 里），不能链接 floatingView.dylib，
// 又需要发同样的通知、读同样的 plist、用同样的颜色解析。
// 这里只放「两边都要、且不依赖 FVAmbient」的东西。

import Foundation
import UIKit

// MARK: - 通知事件（两端共用同一套 name）

public enum FVNotificationEvent: String, CaseIterable {
    case openFloatingView             = "fv_openFloatingView"
    case openFloatingViewToSide       = "fv_openFloatingView_toSide"
    case openFloatingViewLastRun      = "fv_openFloatingView_lastRun"
    case closeMainFloatingApp         = "fv_closeMainFloatingApp"
    case toggleMainFloatingAppDisplay = "fv_toggleMainFloatingAppDisplay"
}

public enum FVNotify {
    /// 只发不收。设置面板用这个；SpringBoard 侧的接收在 FVNotificationCenter。
    public static func post(_ e: FVNotificationEvent, userInfo: [String: Any]? = nil) {
        NotificationCenter.default.post(
            name: Notification.Name(e.rawValue), object: nil, userInfo: userInfo)
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
