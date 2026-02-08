import AppKit
import AVFoundation
import Combine
import Foundation

/// Permission status enum
enum PermissionStatus: String {
    case unknown
    case notDetermined
    case granted
    case denied
}

/// Centralized permission manager for all system permissions
@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    // MARK: - Published Properties

    @Published var microphoneStatus: PermissionStatus = .unknown
    @Published var accessibilityStatus: PermissionStatus = .unknown
    @Published var screenRecordingStatus: PermissionStatus = .unknown

    // MARK: - Computed Properties

    /// All required permissions (mic + accessibility) are granted
    var allRequiredPermissionsGranted: Bool {
        microphoneStatus == .granted && accessibilityStatus == .granted
    }

    // MARK: - System Settings URLs

    static let microphoneSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
    static let accessibilitySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    static let screenRecordingSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!

    // MARK: - Initialization

    private init() {
        // Log bundle path for diagnostics (multiple versions on disk = TCC confusion)
        print("[PermissionManager] Bundle path: \(Bundle.main.bundlePath)")
        print("[PermissionManager] Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        checkAllPermissions()
    }

    // MARK: - Check All Permissions

    /// Check status of all permissions
    func checkAllPermissions() {
        checkMicrophonePermission()
        checkAccessibilityPermission()
        checkScreenRecordingPermission()
    }

    // MARK: - Microphone

    /// Check current microphone permission status
    func checkMicrophonePermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            microphoneStatus = .granted
        case .notDetermined:
            microphoneStatus = .notDetermined
        case .denied, .restricted:
            microphoneStatus = .denied
        @unknown default:
            microphoneStatus = .unknown
        }
    }

    /// Request microphone access (async, shows system dialog if not determined)
    func requestMicrophoneAccess() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            microphoneStatus = .granted
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            microphoneStatus = granted ? .granted : .denied
            return granted
        case .denied, .restricted:
            microphoneStatus = .denied
            return false
        @unknown default:
            microphoneStatus = .unknown
            return false
        }
    }

    /// Open microphone settings in System Settings
    func openMicrophoneSettings() {
        NSWorkspace.shared.open(Self.microphoneSettingsURL)
    }

    // MARK: - Accessibility

    /// Check current accessibility permission status
    func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        accessibilityStatus = trusted ? .granted : .denied
    }

    /// Request accessibility access (shows system prompt if first time, otherwise opens settings)
    func requestAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        accessibilityStatus = trusted ? .granted : .denied
    }

    /// Open accessibility settings in System Settings
    func openAccessibilitySettings() {
        NSWorkspace.shared.open(Self.accessibilitySettingsURL)
    }

    // MARK: - Screen Recording

    /// Check current screen recording permission status
    func checkScreenRecordingPermission() {
        let hasPermission = CGPreflightScreenCaptureAccess()
        screenRecordingStatus = hasPermission ? .granted : .denied
    }

    /// Request screen recording access (shows system dialog)
    func requestScreenRecordingAccess() {
        CGRequestScreenCaptureAccess()
        // Re-check after request
        checkScreenRecordingPermission()
    }

    /// Open screen recording settings in System Settings
    func openScreenRecordingSettings() {
        NSWorkspace.shared.open(Self.screenRecordingSettingsURL)
    }
}
