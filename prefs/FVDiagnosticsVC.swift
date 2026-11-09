// FVDiagnosticsVC.swift —— 真机校准页
//
// 报告由 SpringBoard 侧写盘（FVHookAudit），这里只负责「喊它扫」和「读结果」。
// 跨进程用 Darwin notify，见 Shared/FVShared.swift。

import UIKit

public final class FVDiagnosticsVC: UIViewController {

    private let textView = UITextView()

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "钩子自检"
        view.backgroundColor = .systemGroupedBackground

        textView.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        textView.isEditable = false
        textView.alwaysBounceVertical = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "重扫", style: .done, target: self, action: #selector(rescan))
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "IOHID 10s", style: .plain, target: self, action: #selector(probe))

        load(placeholder: "正在让 SpringBoard 重扫…")
        rescan()
    }

    @objc private func rescan() {
        FVNotify.post(.runDiagnostics)
        // 给它 1.2 秒落盘
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.load(placeholder: "报告为空。SpringBoard 里可能没加载这个 tweak。")
        }
    }

    @objc private func probe() {
        FVNotify.post(.runIOHIDProbe)
        let alert = UIAlertController(
            title: "开始 10 秒采集",
            message: "现在去屏幕上划几下，10 秒后回来按「重扫」旁的报告刷新。\n结果在 iohid-probe.txt。",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
                self?.loadIOHID()
            }
        })
        present(alert, animated: true)
    }

    private func load(placeholder: String) {
        let path = "\(FVFileManager.infoDir)/hook-audit.txt"
        if let s = try? String(contentsOfFile: path, encoding: .utf8), !s.isEmpty {
            textView.text = s
        } else {
            textView.text = "\(placeholder)\n\n期望路径：\n\(path)"
        }
    }

    private func loadIOHID() {
        let path = "\(FVFileManager.infoDir)/iohid-probe.txt"
        if let s = try? String(contentsOfFile: path, encoding: .utf8), !s.isEmpty {
            textView.text = s
        } else {
            textView.text = "没有探测结果。\n\n期望路径：\n\(path)"
        }
    }
}
