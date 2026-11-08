// FVFeedback.swift
// 对应原版：floatingView.FVFeedback（NSObject）
// 字段：audioPlayer: AVAudioPlayer?、generator: UIImpactFeedbackGenerator?

import UIKit
import AVFAudio

public final class FVFeedback {
    public static let shared = FVFeedback()

    public var audioPlayer: AVAudioPlayer?
    public var generator: UIImpactFeedbackGenerator?

    private let soundPath = "/Library/PreferenceBundles/floatingViewClonePrefs.bundle/Sounds/arc_sound.aif"

    private init() {
        generator = UIImpactFeedbackGenerator(style: .light)
        generator?.prepare()
        // rootless 兼容：/var/jb 前缀
        var path = soundPath
        if FileManager.default.fileExists(atPath: "/var/jb" + soundPath) {
            path = "/var/jb" + soundPath
        }
        if let url = URL(string: "file://" + path) {
            audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        }
    }

    public enum ImpactStyle { case light, medium, heavy }

    public func impact(_ style: ImpactStyle) {
        switch style {
        case .light:  generator = UIImpactFeedbackGenerator(style: .light)
        case .medium: generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:  generator = UIImpactFeedbackGenerator(style: .heavy)
        }
        generator?.impactOccurred()
    }

    public func playSound() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
}
