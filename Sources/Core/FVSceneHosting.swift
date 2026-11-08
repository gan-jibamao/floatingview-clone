// FVSceneHosting.swift
// 全项目最核心的一段：把真实 App 的 FBScene 嵌进浮窗。
//
// 关键私有 API 链（逐行来自反编译 method.floatingView.FVHostingView.func.00035e5c）：
//
//   1. NSClassFromString("_UISceneLayerHostContainerView")
//        -alloc -initWithScene:debugDescription:   (debugDescription 传 nil)
//   2. NSClassFromString("UIScenePresentationContext")
//        -alloc -_initWithDefaultValues            ← ★ 这是「呈现上下文」对象
//   3. containerView -_setPresentationContext:(ctx)  ← ★ 参数是 Context，不是 UIView
//   4. scene.settings -mutableCopy → setForeground: / setUserInterfaceStyle:
//        -updateSettings:withTransitionContext:completion:
//   5. host -addSubview:(containerView)
//
// ⚠️ 私有 API 随系统版本变化，全部包在 responds(to:) + 可选绑定里；
//    拿不到就降级为快照占位（见 FVSnapshotView）。

import UIKit

public enum FVSceneHosting {

    private static var workspaceCache: AnyObject?

    // MARK: - Step 1：拿 FBSceneWorkspace

    /// 不同系统版本 ivar 名不同，逐个试
    public static func workspace() -> AnyObject? {
        if let c = workspaceCache { return c }
        guard let cls = NSClassFromString("FBSceneManager") as? NSObject.Type,
              let mgrAny = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let mgr = mgrAny.takeUnretainedValue() as? NSObject
        else { return nil }

        for key in ["_workspace", "workspace"] {
            if let v = mgr.value(forKey: key) as AnyObject? {
                workspaceCache = v
                return v
            }
        }
        return nil
    }

    // MARK: - Step 2：按 bundleIdentifier 找 FBScene

    public static func scene(for bundleIdentifier: String) -> FBScene? {
        guard let ws = workspace() as? NSObject else { return nil }

        // 场景 ID 通常形如 "com.apple.mobilesafari-<uuid>"，用前缀匹配
        if let dict = ws.value(forKey: "_allScenesByID") as? [String: Any] {
            for (k, v) in dict where k.hasPrefix(bundleIdentifier) {
                if let s = v as? FBScene { return s }
            }
        }
        // 兜底：SBApplication -> _scene
        if let app = FVAppHelper.sbApplication(bundleIdentifier),
           let sel = FVAppHelper.selIfResponds(app, "_scene"),
           let any = app.perform(sel),
           let s = any.takeUnretainedValue() as? FBScene {
            return s
        }
        return nil
    }

    // MARK: - Step 3：核心 —— 把 scene 挂到 host 上

    /// 返回值：承载 App 画面的容器视图（后续用于尺寸同步）
    /// outSettings：回传 mutableSettings，供开启时同步深色模式
    @discardableResult
    public static func attach(_ scene: FBScene,
                              to host: UIView,
                              size: CGSize,
                              outSettings: inout UIMutableApplicationSceneSettings?) -> UIView? {

        // ---- 1) 创建图层宿主容器 ----
        guard let containerCls = NSClassFromString("_UISceneLayerHostContainerView"),
              let allocAny = (containerCls as AnyObject).perform(NSSelectorFromString("alloc"))
        else {
            FVLog.warn("_UISceneLayerHostContainerView 不可用")
            return nil
        }
        let initSel = NSSelectorFromString("initWithScene:debugDescription:")
        guard (containerCls as AnyObject).responds(to: initSel) else {
            FVLog.warn("initWithScene:debugDescription: 不可用")
            return nil
        }
        guard let containerAny = (allocAny.takeUnretainedValue() as AnyObject)
                                    .perform(initSel, with: scene, with: nil),
              let container = containerAny.takeUnretainedValue() as? UIView
        else { return nil }

        // ---- 2) 创建 UIScenePresentationContext 并交给容器（★ 易错点）----
        if let ctxCls = NSClassFromString("UIScenePresentationContext"),
           let ctxAlloc = (ctxCls as AnyObject).perform(NSSelectorFromString("alloc")),
           let ctxAny = (ctxAlloc.takeUnretainedValue() as AnyObject)
                        .perform(NSSelectorFromString("_initWithDefaultValues")),
           let ctx = ctxAny.takeUnretainedValue() as? NSObject {

            let setCtx = NSSelectorFromString("_setPresentationContext:")
            if container.responds(to: setCtx) {
                _ = container.perform(setCtx, with: ctx)
            } else {
                FVLog.warn("容器不支持 _setPresentationContext:")
            }
        } else {
            FVLog.warn("UIScenePresentationContext 不可用（系统版本差异）")
        }

        // ---- 3) 更新场景设置 ----
        if scene.responds(to: NSSelectorFromString("settings")),
           let settingsAny = scene.perform(NSSelectorFromString("settings")),
           let mutableAny = (settingsAny.takeUnretainedValue() as AnyObject)
                                .perform(NSSelectorFromString("mutableCopy")),
           let mutable = mutableAny.takeUnretainedValue() as? UIMutableApplicationSceneSettings {

            mutable.frame = CGRect(origin: .zero, size: size)
            mutable.userInterfaceStyle = host.traitCollection.userInterfaceStyle
            outSettings = mutable

            let upSel = NSSelectorFromString("updateSettings:withTransitionContext:completion:")
            if scene.responds(to: upSel) {
                scene.updateSettings(mutable, withTransitionContext: nil, completion: nil)
            }
        }

        // ---- 4) 挂上去 ----
        container.frame = CGRect(origin: .zero, size: size)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(container)
        return container
    }

    // MARK: - Step 4：解绑

    /// 关闭浮窗时必须调，否则 App 画面挂在一个已释放的容器上（会黑屏/崩溃）
    public static func detach(_ scene: FBScene?, container: UIView?) {
        container?.removeFromSuperview()
        guard let scene else { return }
        // 清掉呈现上下文
        if scene.responds(to: NSSelectorFromString("_setPresentationContext:")) {
            _ = scene.perform(NSSelectorFromString("_setPresentationContext:"), with: nil)
        }
    }
}
