// FVIOEvent.swift
// 对应原版：floatingView.FVIOEvent
// 字段与原版一一对应（顺序也有意义，方便对照内存布局）：
//   ioHIDClient, ioHIDRunLoopSchedule, mainBounds, width, height,
//   isTouchCustomSize, isTouchRight, isTouchLeft, abs_x, abs_y,
//   right_move_status, left_move_status, isInit,
//   touchType_arc, touchType_console, eligibleTouchIndex,
//   lastTouchObjPoint, cancelGestureStatus
//
// 为什么必须走 IOHID：SpringBoard 里的 UIKit 边缘手势会被系统先吃掉，
// 只有在事件进入系统之前读取原始触摸，才能实现「刘海/角落唤出」。

import UIKit

public final class FVIOEvent {

    public var ioHIDClient: IOHIDEventSystemClient?
    public var ioHIDRunLoopSchedule: CFRunLoop?
    public var mainBounds: CGRect?
    public var width: CGFloat = 0
    public var height: CGFloat = 0

    public var isTouchCustomSize = false
    public var isTouchRight = false
    public var isTouchLeft = false
    public var abs_x: CGFloat = 0
    public var abs_y: CGFloat = 0
    public var right_move_status = false
    public var left_move_status = false
    public var isInit = false

    public var touchType_arc = false
    public var touchType_console = false
    public var eligibleTouchIndex: Int32 = -1
    public var lastTouchObjPoint: [Int32: CGPoint] = [:]
    public var cancelGestureStatus = false

    // MARK: - 回调

    /// 触摸相位：0=began, 1=moved, 2=ended
    public var onTouchPhase: ((_ phase: Int, _ point: CGPoint, _ index: Int32) -> Void)?

    private var isRunning = false

    public init() {
        mainBounds = UIScreen.main.bounds
        width = mainBounds?.width ?? 0
        height = mainBounds?.height ?? 0
    }

    // MARK: - 生命周期

    public func start() {
        guard !isRunning else { return }
        guard let client = IOHIDEventSystemClientCreate(kCFAllocatorDefault) else {
            FVLog.warn("IOHIDEventSystemClientCreate 失败")
            return
        }
        ioHIDClient = client

        let callback: IOHIDEventSystemClientEventCallback = { ctx, _, _, _, event, _ in
            guard let ctx, let event else { return }
            let me = Unmanaged<FVIOEvent>.fromOpaque(ctx).takeUnretainedValue()
            me.handle(event: event)
        }
        IOHIDEventSystemClientRegisterEventCallback(
            client, callback, Unmanaged.passUnretained(self).toOpaque(), nil)

        let runloop = CFRunLoopGetMain()
        ioHIDRunLoopSchedule = runloop
        IOHIDEventSystemClientScheduleWithRunLoop(
            client, runloop, CFRunLoopMode.defaultMode.rawValue as CFString)
        isRunning = true
        FVLog.info("IOHID 已启动")
    }

    public func stop() {
        guard isRunning, let client = ioHIDClient else { return }
        IOHIDEventSystemClientUnregisterEventCallback(client, nil, nil)
        if let rl = ioHIDRunLoopSchedule {
            IOHIDEventSystemClientUnscheduleWithRunLoop(
                client, rl, CFRunLoopMode.defaultMode.rawValue as CFString)
        }
        ioHIDClient = nil
        isRunning = false
    }

    deinit { stop() }

    // MARK: - 事件解析

    private func handle(event: IOHIDEvent) {
        // 手指事件类型 = 11 (kIOHIDEventTypeDigitizer)，这里保守只处理带 X/Y 的
        let types = IOHIDEventGetType(event)
        _ = types

        // 递归取子事件（每个手指一个 child）
        guard let children = IOHIDEventGetChildren(event) as? [AnyObject], !children.isEmpty else {
            return
        }
        for (idx, raw) in children.enumerated() {
            guard let child = raw as? IOHIDEvent else { continue }
            // 0x10000/0x10001 是 digitizer 的 X/Y 字段（不同系统版本需实测校准）
            let x = CGFloat(IOHIDEventGetFloatValue(child, IOHIDEventField(0x10000)))
            let y = CGFloat(IOHIDEventGetFloatValue(child, IOHIDEventField(0x10001)))
            guard x != 0 || y != 0 else { continue }

            let index = Int32(idx)
            lastTouchObjPoint[index] = CGPoint(x: x, y: y)
            abs_x = x; abs_y = y

            switch FVGestureUtils.phase(of: child) {
            case .began:
                eligibleTouchIndex = index
                FVGestureUtils.shared.begin(at: CGPoint(x: x, y: y), index: index, io: self)
            case .moved:
                FVGestureUtils.shared.move(to: CGPoint(x: x, y: y), index: index, io: self)
            case .ended, .cancelled:
                FVGestureUtils.shared.end(at: CGPoint(x: x, y: y), index: index, io: self)
            default: break
            }
        }
    }

    // MARK: - 抢断系统触摸

    /// 阻止 Home 指示条/系统手势被我们误触发
    public func cancelSystemTouches() {
        guard !cancelGestureStatus else { return }
        cancelGestureStatus = true
        BKSHIDServicesCancelTouchesOnAllDisplays()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.cancelGestureStatus = false
        }
    }

    // MARK: - 热区判定

    /// 原版判定：左右两侧 + 上下角；corner 宽高来自偏好
    public func hitZone(_ p: CGPoint,
                        topCornerWidth: CGFloat,
                        topCornerHeight: CGFloat,
                        bottomCornerHeight: CGFloat) -> FVHotZone {
        let w = mainBounds?.width ?? width
        let h = mainBounds?.height ?? height

        // 左上 / 右上角 → arc
        if p.y <= topCornerHeight {
            if p.x <= topCornerWidth { return .leftTopArc }
            if p.x >= w - topCornerWidth { return .rightTopArc }
        }
        // 左下 / 右下角 → arc
        if p.y >= h - bottomCornerHeight {
            if p.x <= topCornerWidth { return .leftBottomArc }
            if p.x >= w - topCornerWidth { return .rightBottomArc }
        }
        // 底部中心 → console
        if p.y >= h - 34, abs(p.x - w / 2) <= w * 0.15 {
            return .bottomCenterConsole
        }
        return .none
    }
}

public enum FVHotZone {
    case none
    case leftTopArc, rightTopArc, leftBottomArc, rightBottomArc
    case bottomCenterConsole

    public var isArc: Bool {
        switch self {
        case .leftTopArc, .rightTopArc, .leftBottomArc, .rightBottomArc: return true
        default: return false
        }
    }
    public var positionType: Int {   // 0=左 1=右（原版字段语义）
        switch self {
        case .leftTopArc, .leftBottomArc: return 0
        case .rightTopArc, .rightBottomArc: return 1
        default: return 0
        }
    }
}
