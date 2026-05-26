//
//  PermissionCenter.swift
//  FocusCue
//

import AVFoundation
import AppKit
import Combine
import Foundation
import Speech

enum FCPermissionStatus {
    case notDetermined
    case authorized
    case denied
    case restricted

    var title: String {
        switch self {
        case .notDetermined: return "Not Requested"
        case .authorized: return "Granted"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        }
    }

    var symbolName: String {
        switch self {
        case .notDetermined: return "minus.circle"
        case .authorized: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .restricted: return "lock.circle.fill"
        }
    }

    var colorToken: FCColorToken {
        switch self {
        case .authorized: return .stateSuccess
        case .denied: return .dangerText
        case .restricted: return .stateWarning
        case .notDetermined: return .textTertiary
        }
    }
}

@MainActor
final class PermissionCenter: ObservableObject {
    @Published private(set) var microphoneStatus: FCPermissionStatus = .notDetermined
    @Published private(set) var speechStatus: FCPermissionStatus = .notDetermined

    init() {
        refresh()
    }

    func refresh() {
        microphoneStatus = Self.mapMicStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        speechStatus = Self.mapSpeechStatus(SFSpeechRecognizer.authorizationStatus())
    }

    func requestMicrophoneAccess(completion: ((FCPermissionStatus) -> Void)? = nil) {
        let current = AVCaptureDevice.authorizationStatus(for: .audio)
        switch current {
        case .authorized:
            refresh()
            completion?(microphoneStatus)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.refresh()
                    completion?(self?.microphoneStatus ?? .notDetermined)
                }
            }
        case .denied, .restricted:
            openMicrophoneSettings()
            refresh()
            completion?(microphoneStatus)
        @unknown default:
            refresh()
            completion?(microphoneStatus)
        }
    }

    func requestSpeechAccess(completion: ((FCPermissionStatus) -> Void)? = nil) {
        let current = SFSpeechRecognizer.authorizationStatus()
        switch current {
        case .authorized:
            refresh()
            completion?(speechStatus)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { [weak self] _ in
                DispatchQueue.main.async {
                    self?.refresh()
                    completion?(self?.speechStatus ?? .notDetermined)
                }
            }
        case .denied, .restricted:
            openSpeechSettings()
            refresh()
            completion?(speechStatus)
        @unknown default:
            refresh()
            completion?(speechStatus)
        }
    }

    func openMicrophoneSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") else { return }
        NSWorkspace.shared.open(url)
    }

    func openSpeechSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") else { return }
        NSWorkspace.shared.open(url)
    }

    private static func mapMicStatus(_ status: AVAuthorizationStatus) -> FCPermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }

    private static func mapSpeechStatus(_ status: SFSpeechRecognizerAuthorizationStatus) -> FCPermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
}
