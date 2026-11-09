// FVNotificationCenter.swift
// 对应原版：floatingView.FVNotificationCenter（NSObject，3 个方法）
//
// 6 个通知名（cstring 表实证）：
//   fv_openFloatingView / fv_openFloatingView_toSide / fv_openFloatingView_lastRun
//   fv_closeMainFloatingApp / fv_toggleMainFloatingAppDisplay
//
// 这是所有「打开浮窗」入口的汇聚点：桌面图标菜单、底部横条、通知横幅、
// 通用链接最终都 post 到这里，由 handleNotification: 统一分派。
//
// 跨进程走 Darwin notify（Shared/FVNotify），同进程也收一份。

import Foundation

public final class FVNotificationCenter: NSObject {
    public static let shared = FVNotificationCenter()

    public typealias Event = FVNotificationEvent

    public enum UserInfoKey {
        public static let bundleIdentifier = "bundleIdentifier"
        public static let positionType     = "positionType"
    }

    private override init() {
        super.init()
        for e in Event.allCases {
            FVNotify.observe(e) { [weak self] payload in
                self?.handle(e, bid: payload)
            }
        }
        FVLog.info("FVNotificationCenter 已注册 \(Event.allCases.count) 个观察者")
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// 原版：handleNotification:（63 行，按 notification.name 分派）
    /// 这里载荷只有 bundleIdentifier —— Darwin 带不了复杂 userInfo。
    private func handle(_ e: Event, bid: String?) {
        switch e {
        case .openFloatingView:
            guard let bid else { return }
            FVAmbient.shared.openInFloatingView(bundleIdentifier: bid)

        case .openFloatingViewToSide:
            guard let bid else { return }
            FVAmbient.shared.openInFloatingView(bundleIdentifier: bid, asSide: true)

        case .openFloatingViewLastRun:
            FVAmbient.shared.reopenLastFloating()

        case .closeMainFloatingApp:
            FVAmbient.shared.closeMainFloating()

        case .toggleMainFloatingAppDisplay:
            FVAmbient.shared.toggleMainFloating()

        case .runDiagnostics:
            FVHookAudit.run(reason: "FVNotificationCenter")

        case .runIOHIDProbe:
            FVIOProbe.shared.start(seconds: 10)
        }
    }

    // MARK: - 发送端（原版各处调用）

    public static func post(_ e: Event, _ bid: String? = nil) {
        FVNotify.post(e, payload: bid)
    }

    public static func open(_ bundleIdentifier: String, toSide: Bool = false) {
        post(toSide ? .openFloatingViewToSide : .openFloatingView, bundleIdentifier)
    }
}
