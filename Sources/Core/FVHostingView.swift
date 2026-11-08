// FVHostingView.swift
// 对应原版：floatingView.FVHostingView（UIView）
// 字段（名字必须一致，外部逻辑依赖）：
//   currentActivityApp: SBApplication?
//   hostingView: UIView?
//   isDisplay: Bool
//   appScene: FBScene?
//   appSetting: UIMutableApplicationSceneSettings?
//   isDynamicView: Bool
//   snapshotView: FVSnapshotView

import UIKit

public class FVHostingView: UIView {
    public var currentActivityApp: NSObject?
    public var hostingView: UIView?
    public var isDisplay: Bool = false
    public var appScene: FBScene?
    public var appSetting: UIMutableApplicationSceneSettings?
    public var isDynamicView: Bool = false
    public let snapshotView = FVSnapshotView()

    private var bundleIdentifier: String = ""

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
        layer.masksToBounds = true

        snapshotView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(snapshotView)
        NSLayoutConstraint.activate([
            snapshotView.topAnchor.constraint(equalTo: topAnchor),
            snapshotView.leadingAnchor.constraint(equalTo: leadingAnchor),
            snapshotView.trailingAnchor.constraint(equalTo: trailingAnchor),
            snapshotView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        applyShadowFromPrefs()
    }

    // MARK: - 阴影（偏好：shadowOpacity / shadowRange）

    public func applyShadowFromPrefs() {
        let store = FVPrefsStore.shared
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = Float(store.double(FVKey.shadowOpacity))
        layer.shadowRadius  = CGFloat(store.double(FVKey.shadowRange))
        layer.masksToBounds = false
        clipsToBounds = false
    }

    // MARK: - 绑定应用

    public func setApp(bundleIdentifier bid: String, dynamic: Bool = false) {
        self.bundleIdentifier = bid
        self.isDynamicView = dynamic
        self.currentActivityApp = FVAppHelper.sbApplication(bid)
        snapshotView.load(bundleIdentifier: bid)
        snapshotView.show(true)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let scene = FVSceneHosting.scene(for: bid) else {
                FVLog.warn("scene 未找到: \(bid)，降级为快照")
                return
            }
            self.appScene = scene
            let size = self.bounds.size == .zero ? UIScreen.main.bounds.size : self.bounds.size
            var settings: UIMutableApplicationSceneSettings?
            if let container = FVSceneHosting.attach(scene, to: self, size: size,
                                                     outSettings: &settings) {
                self.hostingView = container
                self.appSetting = settings
                self.snapshotView.show(false)
                self.isDisplay = true
            }
        }
    }

    public func reset() {
        FVSceneHosting.detach(appScene, container: hostingView)
        hostingView?.removeFromSuperview()
        hostingView = nil
        appScene = nil
        isDisplay = false
        snapshotView.show(true)
    }

    // MARK: - 动画（原版：animateWithDuration:animations:）

    public func showWithAnimation(_ visible: Bool, duration: TimeInterval = 0.25) {
        UIView.animate(withDuration: duration) {
            self.alpha = visible ? 1 : 0
            self.isHidden = !visible
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        hostingView?.frame = bounds
        if appScene != nil, let settings = appSetting {
            settings.frame = CGRect(origin: .zero, size: bounds.size)
            appScene?.updateSettings(settings, withTransitionContext: nil, completion: nil)
        }
    }
}
