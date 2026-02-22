//
//  OnboardingWizardView.swift
//  FocusCue
//

import AppKit
import SwiftUI

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case modes
    case surfaces
    case microphone
    case speech
    case ready

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Welcome to FocusCue"
        case .modes: return "Choose the Right Guidance Mode"
        case .surfaces: return "Present Anywhere"
        case .microphone: return "Microphone Permission"
        case .speech: return "Speech Recognition Permission"
        case .ready: return "You're Ready"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Camera-adjacent confidence for calls, demos, and recordings."
        case .modes:
            return "FocusCue supports natural speech-based and classic pacing workflows."
        case .surfaces:
            return "Switch between notch, floating, fullscreen, external, and remote views."
        case .microphone:
            return "Required for voice-activated and word-tracking guidance."
        case .speech:
            return "Required for real-time spoken-word highlighting."
        case .ready:
            return "Launch with a guided template or continue to detailed settings."
        }
    }
}

struct OnboardingWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var permissions = PermissionCenter()
    @State private var currentStep: OnboardingStep = .welcome
    @State private var direction: Edge = .trailing

    let onStartTemplate: () -> Void
    let onOpenSettings: () -> Void
    let onFinish: () -> Void

    private var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        ZStack {
            FCWindowBackdrop()

            FCGlassPanel {
                VStack(alignment: .leading, spacing: FCSpacingToken.s20.rawValue) {
                    header(theme: theme)
                    stepContent(theme: theme)
                    footer(theme: theme)
                }
                .padding(FCSpacingToken.s4.rawValue)
            }
            .frame(width: 680, height: 520)
            .padding(FCSpacingToken.s24.rawValue)
        }
        .onAppear {
            permissions.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissions.refresh()
        }
    }

    private func header(theme: FCTheme) -> some View {
        VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentStep.title)
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.titleL)
                    Text(currentStep.subtitle)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.bodyM)
                }

                Spacer()

                Button("Skip") {
                    completeAndDismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.color(.accentInfo))
                .fcTypography(.label)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(theme.color(.borderSubtle))
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.color(.accentInfo), theme.color(.accentPrimary)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(theme.animation(.base), value: progress)
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private func stepContent(theme: FCTheme) -> some View {
        Group {
            switch currentStep {
            case .welcome:
                welcomeStep(theme: theme)
            case .modes:
                modesStep(theme: theme)
            case .surfaces:
                surfacesStep(theme: theme)
            case .microphone:
                permissionStep(
                    theme: theme,
                    title: "Microphone",
                    detail: "FocusCue listens for your speech to match pacing and highlights.",
                    status: permissions.microphoneStatus,
                    requestAction: { permissions.requestMicrophoneAccess() },
                    settingsAction: { permissions.openMicrophoneSettings() }
                )
            case .speech:
                permissionStep(
                    theme: theme,
                    title: "Speech Recognition",
                    detail: "FocusCue uses speech recognition to follow your spoken words in real time.",
                    status: permissions.speechStatus,
                    requestAction: { permissions.requestSpeechAccess() },
                    settingsAction: { permissions.openSpeechSettings() }
                )
            case .ready:
                readyStep(theme: theme)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .transition(stepTransition)
        .animation(theme.spring(.emphasis), value: currentStep)
    }

    private func footer(theme: FCTheme) -> some View {
        HStack {
            Button("Back") {
                goBack()
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.color(currentStep == .welcome ? .textTertiary : .accentInfo))
            .fcTypography(.label)
            .disabled(currentStep == .welcome)

            Spacer()

            Button(currentStep == .ready ? "Finish" : "Next") {
                if currentStep == .ready {
                    completeAndDismiss()
                } else {
                    goNext()
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .fcTypography(.label)
            .padding(.horizontal, FCSpacingToken.s20.rawValue)
            .padding(.vertical, FCSpacingToken.s8.rawValue)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.color(.accentInfo), theme.color(.accentPrimary)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
    }

    private func welcomeStep(theme: FCTheme) -> some View {
        FCGlassPanel(emphasized: true) {
            VStack(alignment: .leading, spacing: FCSpacingToken.s16.rawValue) {
                HStack(spacing: FCSpacingToken.s12.rawValue) {
                    Image(systemName: "video.bubble.left.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(theme.color(.accentInfo))
                    Text("Stay on script while maintaining eye contact.")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.heading)
                }

                Text("FocusCue keeps your script near the camera for natural delivery across meetings, webinars, and tutorials.")
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.bodyL)

                HStack(spacing: FCSpacingToken.s12.rawValue) {
                    onboardingFeaturePill(theme: theme, icon: "text.word.spacing", text: "Word Tracking")
                    onboardingFeaturePill(theme: theme, icon: "waveform.path.ecg", text: "Voice Activated")
                    onboardingFeaturePill(theme: theme, icon: "rectangle.on.rectangle", text: "External Display")
                }
            }
        }
    }

    private func modesStep(theme: FCTheme) -> some View {
        VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
            onboardingModeCard(
                theme: theme,
                title: "Word Tracking",
                detail: "Highlights each spoken word for precise alignment.",
                icon: "text.word.spacing",
                accent: .accentInfo
            )
            onboardingModeCard(
                theme: theme,
                title: "Voice-Activated",
                detail: "Scrolls while you speak and pauses when silent.",
                icon: "waveform",
                accent: .accentPrimary
            )
            onboardingModeCard(
                theme: theme,
                title: "Classic",
                detail: "Constant-speed scroll without microphone input.",
                icon: "arrow.down.circle",
                accent: .accentCTA
            )
        }
    }

    private func surfacesStep(theme: FCTheme) -> some View {
        FCGlassPanel {
            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                Text("Output Surfaces")
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.heading)

                Text("Use notch-pinned mode for calls, floating for flexible placement, fullscreen for recording, and external/remote surfaces for production setups.")
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.bodyM)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: FCSpacingToken.s8.rawValue) {
                    onboardingFeaturePill(theme: theme, icon: "rectangle.topthird.inset.filled", text: "Pinned")
                    onboardingFeaturePill(theme: theme, icon: "macwindow", text: "Floating")
                    onboardingFeaturePill(theme: theme, icon: "rectangle.fill", text: "Fullscreen")
                    onboardingFeaturePill(theme: theme, icon: "antenna.radiowaves.left.and.right", text: "Remote Browser")
                }
            }
        }
    }

    private func permissionStep(
        theme: FCTheme,
        title: String,
        detail: String,
        status: FCPermissionStatus,
        requestAction: @escaping () -> Void,
        settingsAction: @escaping () -> Void
    ) -> some View {
        FCGlassPanel(emphasized: true) {
            VStack(alignment: .leading, spacing: FCSpacingToken.s16.rawValue) {
                HStack(spacing: FCSpacingToken.s12.rawValue) {
                    Image(systemName: status.symbolName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(theme.color(status.colorToken))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .foregroundStyle(theme.color(.textPrimary))
                            .fcTypography(.heading)
                        Text(detail)
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.bodyM)
                    }
                }

                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Text("Status")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.caption)
                    Text(status.title)
                        .foregroundStyle(theme.color(status.colorToken))
                        .fcTypography(.label)
                        .padding(.horizontal, FCSpacingToken.s8.rawValue)
                        .padding(.vertical, FCSpacingToken.s4.rawValue)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.color(status.colorToken).opacity(0.14))
                        )
                }

                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Button {
                        requestAction()
                    } label: {
                        Text("Grant Access")
                            .foregroundStyle(.white)
                            .fcTypography(.label)
                            .padding(.horizontal, FCSpacingToken.s16.rawValue)
                            .padding(.vertical, FCSpacingToken.s8.rawValue)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(theme.color(.accentPrimary))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        settingsAction()
                    } label: {
                        Text("Open System Settings")
                            .foregroundStyle(theme.color(.accentInfo))
                            .fcTypography(.label)
                            .padding(.horizontal, FCSpacingToken.s16.rawValue)
                            .padding(.vertical, FCSpacingToken.s8.rawValue)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(theme.color(.accentInfo).opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func readyStep(theme: FCTheme) -> some View {
        FCGlassPanel(emphasized: true) {
            VStack(alignment: .leading, spacing: FCSpacingToken.s16.rawValue) {
                Text("FocusCue is configured and ready.")
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.heading)
                Text("You can start with a guided template immediately or review advanced options in Settings.")
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.bodyM)

                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Button {
                        onStartTemplate()
                        completeAndDismiss()
                    } label: {
                        Label("Start with Guided Template", systemImage: "doc.text.fill")
                            .foregroundStyle(.white)
                            .fcTypography(.label)
                            .padding(.horizontal, FCSpacingToken.s16.rawValue)
                            .padding(.vertical, FCSpacingToken.s8.rawValue)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.color(.accentInfo), theme.color(.accentPrimary)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onOpenSettings()
                        completeAndDismiss()
                    } label: {
                        Label("Open Settings", systemImage: "slider.horizontal.3")
                            .foregroundStyle(theme.color(.accentInfo))
                            .fcTypography(.label)
                            .padding(.horizontal, FCSpacingToken.s16.rawValue)
                            .padding(.vertical, FCSpacingToken.s8.rawValue)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(theme.color(.accentInfo).opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func onboardingFeaturePill(theme: FCTheme, icon: String, text: String) -> some View {
        HStack(spacing: FCSpacingToken.s8.rawValue) {
            Image(systemName: icon)
                .foregroundStyle(theme.color(.accentInfo))
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .foregroundStyle(theme.color(.textSecondary))
                .fcTypography(.caption)
        }
        .padding(.horizontal, FCSpacingToken.s12.rawValue)
        .padding(.vertical, FCSpacingToken.s8.rawValue)
        .background(
            Capsule(style: .continuous)
                .fill(theme.color(.surfaceGlassStrong).opacity(0.70))
        )
    }

    private func onboardingModeCard(
        theme: FCTheme,
        title: String,
        detail: String,
        icon: String,
        accent: FCColorToken
    ) -> some View {
        FCGlassPanel {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                ZStack {
                    RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                        .fill(theme.color(accent).opacity(0.18))
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.color(accent))
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.label)
                    Text(detail)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.bodyM)
                }
                Spacer()
            }
        }
    }

    private var stepTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: direction).combined(with: .opacity),
            removal: .move(edge: direction == .trailing ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func goNext() {
        guard let index = OnboardingStep.allCases.firstIndex(of: currentStep),
              index + 1 < OnboardingStep.allCases.count else { return }
        direction = .trailing
        currentStep = OnboardingStep.allCases[index + 1]
    }

    private func goBack() {
        guard let index = OnboardingStep.allCases.firstIndex(of: currentStep),
              index > 0 else { return }
        direction = .leading
        currentStep = OnboardingStep.allCases[index - 1]
    }

    private func completeAndDismiss() {
        onFinish()
        dismiss()
    }
}
