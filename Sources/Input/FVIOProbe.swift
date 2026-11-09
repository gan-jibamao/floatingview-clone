// FVIOProbe.swift —— IOHID 原始事件探测
//
// 骨架里 x/y 用的是 0x10000 / 0x10001，相位用 0x10002，全是猜的。
// 这个探测在 10 秒内把每个 digitizer 子事件的原始字段摊开写盘，
// 你在屏幕上划几下，就能看出哪个字段真的在动。

import Foundation
import UIKit

public final class FVIOProbe {
    public static let shared = FVIOProbe()

    private var client: IOHIDEventSystemClient?
    private var lines: [String] = []
    private var started = Date()
    private var running = false
    private var timer: Timer?

    private let queue = DispatchQueue(label: "fv.iohid.probe")

    public func stop() {
        guard running else { return }
        running = false
        timer?.invalidate()
        timer = nil
        if let c = client {
            IOHIDEventSystemClientUnregisterEventCallback(c, nil, nil)
        }
        client = nil
        let head = """
        # IOHID 原始事件转储
        # 开始 \(Self.fmt.string(from: started))  时长 \(String(format: "%.1f", Date().timeIntervalSince(started)))s
        # 字段说明：t=相对秒  type=IOHIDEventGetType  n=子事件数
        #          x=0x10000  y=0x10001  f2=0x10002  f3=0x10003  f4=0x10004
        """
        FVFileManager.write(([head] + lines).joined(separator: "\n"), name: "iohid-probe.txt")
        FVLog.info("IOHID 探测结束，共 \(lines.count) 条")
    }

    public func start(seconds: Double = 10) {
        guard !running else { return }
        running = true
        lines.removeAll()
        started = Date()

        guard let c = IOHIDEventSystemClientCreate(kCFAllocatorDefault) else {
            lines.append("# IOHIDEventSystemClientCreate 失败")
            running = false
            FVFileManager.write(lines.joined(separator: "\n"), name: "iohid-probe.txt")
            return
        }
        client = c

        let cb: IOHIDEventSystemClientEventCallback = { _, _, _, _, event, _ in
            guard let event else { return }
            FVIOProbe.shared.record(event)
        }
        IOHIDEventSystemClientRegisterEventCallback(c, cb, nil, nil)
        let rl = CFRunLoopGetMain()
        IOHIDEventSystemClientScheduleWithRunLoop(
            c, rl, CFRunLoopMode.defaultMode.rawValue as CFString)

        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            FVIOProbe.shared.stop()
        }
        FVLog.info("IOHID 探测开始 \(Int(seconds))s")
    }

    fileprivate func record(_ event: IOHIDEvent) {
        guard running else { return }
        let t = Date().timeIntervalSince(started)
        let type = IOHIDEventGetType(event)
        let children = (IOHIDEventGetChildren(event) as? [AnyObject]) ?? []

        if children.isEmpty {
            let x = IOHIDEventGetFloatValue(event, IOHIDEventField(0x10000))
            let y = IOHIDEventGetFloatValue(event, IOHIDEventField(0x10001))
            let f2 = IOHIDEventGetIntegerValue(event, IOHIDEventField(0x10002))
            lines.append(String(format: "%.3f type=%u n=0 x=%.2f y=%.2f f2=%ld", t, type, x, y, f2))
            return
        }
        for (i, raw) in children.enumerated() {
            guard let child = raw as? IOHIDEvent else { continue }
            let x = IOHIDEventGetFloatValue(child, IOHIDEventField(0x10000))
            let y = IOHIDEventGetFloatValue(child, IOHIDEventField(0x10001))
            let f2 = IOHIDEventGetIntegerValue(child, IOHIDEventField(0x10002))
            let f3 = IOHIDEventGetIntegerValue(child, IOHIDEventField(0x10003))
            let f4 = IOHIDEventGetIntegerValue(child, IOHIDEventField(0x10004))
            lines.append(String(format: "%.3f type=%u n=%d i=%d x=%.2f y=%.2f f2=%ld f3=%ld f4=%ld",
                                t, type, children.count, i, x, y, f2, f3, f4))
        }
        // 防止手一直按着把文件撑爆
        if lines.count > 4000 { lines.removeFirst(1000) }
    }

    static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()
}
