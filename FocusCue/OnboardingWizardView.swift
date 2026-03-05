//
//  OnboardingWizardView.swift
//  FocusCue
//

import AppKit
import Combine
import SwiftUI

enum FocusCueOnboardingStorage {
    static let completedKey = "focuscue.onboarding.completed"
    static let versionKey = "focuscue.onboarding.version"
    static let lastCompletedStepKey = "focuscue.onboarding.lastCompletedStep"
    static let currentVersion = 2
}

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
        case .modes: return "Choose Your Guidance Style"
        case .surfaces: return "Choose Where FocusCue Appears"
        case .microphone: return "Enable Microphone Access"
        case .speech: return "Enable Speech Recognition"
        case .ready: return "You're All Set"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "A teleprompter that keeps your script near the camera so you can stay natural, on pace, and on message."
        case .modes:
            return "Pick the reading mode that best matches how you present."
        case .surfaces:
            return "Start with the view that best fits how and where you present."
        case .microphone:
            return "FocusCue uses your microphone to follow your pacing in voice-driven modes."
        case .speech:
            return "Speech recognition lets FocusCue follow the exact words you say."
        case .ready:
            return "Try FocusCue with a ready-made script so you can feel how your setup works in practice."
        }
    }
}

enum OnboardingEntryContext {
    case firstRun
    case manual
}

enum OnboardingPermissionKind: String, Hashable {
    case microphone
    case speechRecognition
}

enum OnboardingExitReason: Equatable {
    case skippedForNow
    case continueInSettings
    case launchGuidedTemplate
    case upgradeToPro
}

struct OnboardingDraft {
    var listeningMode: ListeningMode
    var overlayMode: OverlayMode
    var lastVisitedStep: OnboardingStep
    var completedPermissions: Set<OnboardingPermissionKind>
    var selectedAdvancedDestination: SettingsTab?
    var shouldResumeAfterSettings: Bool

    init(
        listeningMode: ListeningMode = .wordTracking,
        overlayMode: OverlayMode = NotchSettings.shared.overlayMode,
        lastVisitedStep: OnboardingStep = .welcome,
        completedPermissions: Set<OnboardingPermissionKind> = [],
        selectedAdvancedDestination: SettingsTab? = nil,
        shouldResumeAfterSettings: Bool = false
    ) {
        self.listeningMode = listeningMode
        self.overlayMode = overlayMode
        self.lastVisitedStep = lastVisitedStep
        self.completedPermissions = completedPermissions
        self.selectedAdvancedDestination = selectedAdvancedDestination
        self.shouldResumeAfterSettings = shouldResumeAfterSettings
    }
}

struct OnboardingCompletion {
    let draft: OnboardingDraft
    let applyDraft: Bool
    let shouldStartTrial: Bool
    let shouldPresentUpgrade: Bool
    let launchGuidedTemplate: Bool
    let openedSettingsTab: SettingsTab?
    let completionReason: OnboardingExitReason
    let markOnboardingComplete: Bool
}

@MainActor
final class OnboardingSession: ObservableObject {
    @Published var draft: OnboardingDraft
    @Published var currentStep: OnboardingStep {
        didSet {
            var updated = draft
            updated.lastVisitedStep = currentStep
            draft = updated
            persistLastVisitedStep()
        }
    }
    @Published var direction: Edge = .trailing
    @Published var pendingDetourTab: SettingsTab?
    @Published var hasLaunchedGuidedTemplate = false

    let entryContext: OnboardingEntryContext

    init(initialStep: OnboardingStep, entryContext: OnboardingEntryContext) {
        self.entryContext = entryContext
        self.currentStep = initialStep
        self.draft = OnboardingDraft(lastVisitedStep: initialStep)
        persistLastVisitedStep()
    }

    func persistLastVisitedStep() {
        UserDefaults.standard.set(currentStep.rawValue, forKey: FocusCueOnboardingStorage.lastCompletedStepKey)
    }

    func clearLastVisitedStep() {
        UserDefaults.standard.set(0, forKey: FocusCueOnboardingStorage.lastCompletedStepKey)
    }
}

// MARK: - Onboarding Wizard View

struct OnboardingWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var permissions = PermissionCenter()
    @StateObject private var session: OnboardingSession
    @State private var entitlements = EntitlementService.shared
    @State private var showDetourSettings = false
    @State private var detourSettingsTab: SettingsTab = .display
    @State private var pendingPermission: OnboardingPermissionKind?

    let onComplete: (OnboardingCompletion) -> Void

    init(
        initialStep: OnboardingStep = .welcome,
        entryContext: OnboardingEntryContext = .firstRun,
        onComplete: @escaping (OnboardingCompletion) -> Void
    ) {
        _session = StateObject(wrappedValue: OnboardingSession(initialStep: initialStep, entryContext: entryContext))
        self.onComplete = onComplete
    }

    private var draft: OnboardingDraft {
        get { session.draft }
        nonmutating set { session.draft = newValue }
    }

    private var currentStep: OnboardingStep {
        get { session.currentStep }
        nonmutating set { session.currentStep = newValue }
    }

    private var direction: Edge {
        get { session.direction }
        nonmutating set { session.direction = newValue }
    }

    private var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    private var requiresMicrophone: Bool {
        draft.listeningMode != .classic
    }

    private var requiresSpeechRecognition: Bool {
        draft.listeningMode == .wordTracking
    }

    private var preferredSettingsTab: SettingsTab {
        switch currentStep {
        case .modes, .microphone, .speech:
            return .guidance
        case .surfaces:
            return .display
        case .welcome, .ready:
            return requiresSpeechRecognition || draft.listeningMode == .silencePaused ? .guidance : .display
        }
    }

    private enum ReadyStepEntitlementState {
        case eligibleForTrial
        case trialActive
        case pro
        case trialExpired
    }

    private var readyStepEntitlementState: ReadyStepEntitlementState {
        if entitlements.hasLifetimePurchase {
            return .pro
        }
        if entitlements.isTrialActive {
            return .trialActive
        }
        if entitlements.hasStartedTrial {
            return .trialExpired
        }
        return .eligibleForTrial
    }

    private var readyStepSubtitle: String {
        switch readyStepEntitlementState {
        case .eligibleForTrial:
            return "Start your 14-day Pro trial now."
        case .trialActive:
            return "Your Pro trial is active."
        case .pro:
            return "FocusCue Pro is already unlocked on this Apple ID."
        case .trialExpired:
            return "Your previous 14-day trial has ended. Continue in Lite or unlock Pro."
        }
    }

    private var readyStepNotice: (kind: FCSettingsNoticeKind, text: String) {
        switch readyStepEntitlementState {
        case .eligibleForTrial:
            return (.info, "We'll start your trial and switch guidance to Word Tracking automatically.")
        case .trialActive:
            return (.success, "Your trial is active, so all Pro features are available right now.")
        case .pro:
            return (.success, "You're already on Pro. Start the guided template to test your setup.")
        case .trialExpired:
            return (.warning, "You can continue in Lite or unlock Pro to restore all premium workflows.")
        }
    }

    private var primaryActionTitle: String {
        switch currentStep {
        case .welcome:
            return "Get Started"
        case .modes:
            return "Use This Mode"
        case .surfaces:
            return "Continue"
        case .microphone:
            return permissionPrimaryActionTitle(for: .microphone)
        case .speech:
            return permissionPrimaryActionTitle(for: .speechRecognition)
        case .ready:
            switch readyStepEntitlementState {
            case .eligibleForTrial:
                return "Start 14-Day Trial"
            case .trialActive, .pro:
                return "Start Guided Template"
            case .trialExpired:
                return "Continue in Lite"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        ZStack {
            FCWindowBackdrop()

            VStack(spacing: 0) {
                onboardingProgressBar(theme: theme)
                    .padding(.horizontal, FCSpacingToken.s24.rawValue)
                    .padding(.top, FCSpacingToken.s16.rawValue)

                Spacer(minLength: FCSpacingToken.s8.rawValue)

                stepContent(theme: theme)
                    .frame(maxWidth: 560)
                    .padding(.horizontal, FCSpacingToken.s32.rawValue)
                    .transition(stepTransition)
                    .animation(theme.spring(.emphasis), value: currentStep)

                Spacer(minLength: FCSpacingToken.s24.rawValue)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showDetourSettings, onDismiss: {
            var updated = draft
            updated.shouldResumeAfterSettings = false
            draft = updated
            session.pendingDetourTab = nil
        }) {
            SettingsView(
                settings: NotchSettings.shared,
                initialTab: detourSettingsTab,
                launchedFromOnboarding: true
            )
        }
        .onAppear {
            permissions.refresh()
            entitlements.handleAppLaunch()
            session.persistLastVisitedStep()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissions.refresh()
        }
    }

    // MARK: - Progress Bar

    private func onboardingProgressBar(theme: FCTheme) -> some View {
        VStack(spacing: FCSpacingToken.s8.rawValue) {
            HStack {
                Text("Step \(currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
                    .foregroundStyle(theme.color(.textTertiary))
                    .fcTypography(.caption)

                Spacer()

                Button {
                    handleSkipForNow()
                } label: {
                    Text("Skip for Now")
                        .fcTypography(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.color(.accentInfo))
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
            .frame(height: 4)
        }
    }

    // MARK: - Step Content Dispatcher

    @ViewBuilder
    private func stepContent(theme: FCTheme) -> some View {
        switch currentStep {
        case .welcome:
            welcomeStep(theme: theme)
        case .modes:
            modesStep(theme: theme)
        case .surfaces:
            surfacesStep(theme: theme)
        case .microphone:
            permissionStep(theme: theme, kind: .microphone)
        case .speech:
            permissionStep(theme: theme, kind: .speechRecognition)
        case .ready:
            readyStep(theme: theme)
        }
    }

    // MARK: - Welcome Step

    private func welcomeStep(theme: FCTheme) -> some View {
        VStack(spacing: FCSpacingToken.s16.rawValue) {
            Spacer(minLength: 0)

            FCBrandIconView(
                size: 64,
                cornerRadius: FCShapeToken.radius18.rawValue
            )

            VStack(spacing: FCSpacingToken.s8.rawValue) {
                Text(currentStep.title)
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.display)
                    .multilineTextAlignment(.center)

                Text("Read naturally while keeping eye contact. FocusCue keeps your script near the camera during meetings, demos, and recordings.")
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.bodyL)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: FCSpacingToken.s8.rawValue) {
                featurePill(theme: theme, icon: "waveform", text: "Voice Guidance")
                featurePill(theme: theme, icon: "macwindow", text: "Display Modes")
                featurePill(theme: theme, icon: "lock.shield", text: "Permissions")
            }

            Spacer(minLength: 0)

            VStack(spacing: FCSpacingToken.s12.rawValue) {
                onboardingCTAButton(theme: theme, title: primaryActionTitle) {
                    handlePrimaryAction()
                }

                Text("Setup takes about two minutes.")
                    .foregroundStyle(theme.color(.textTertiary))
                    .fcTypography(.caption)
            }
        }
    }

    // MARK: - Modes Step

    private func modesStep(theme: FCTheme) -> some View {
        VStack(spacing: FCSpacingToken.s12.rawValue) {
            VStack(spacing: FCSpacingToken.s4.rawValue) {
                Text(currentStep.title)
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.titleL)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(currentStep.subtitle)
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.bodyM)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: FCSpacingToken.s8.rawValue) {
                selectionCard(
                    theme: theme,
                    icon: ListeningMode.wordTracking.icon,
                    title: "Word Tracking",
                    description: "Highlights each word you say for precise alignment.",
                    accent: .accentInfo,
                    isSelected: draft.listeningMode == .wordTracking
                ) {
                    draft.listeningMode = .wordTracking
                }

                selectionCard(
                    theme: theme,
                    icon: ListeningMode.silencePaused.icon,
                    title: "Voice-Activated",
                    description: "Scrolls while you speak and pauses when you stop.",
                    accent: .accentPrimary,
                    isSelected: draft.listeningMode == .silencePaused
                ) {
                    draft.listeningMode = .silencePaused
                }

                selectionCard(
                    theme: theme,
                    icon: ListeningMode.classic.icon,
                    title: "Classic",
                    description: "Steady scrolling without listening to your voice.",
                    accent: .accentCTA,
                    isSelected: draft.listeningMode == .classic
                ) {
                    draft.listeningMode = .classic
                }
            }

            FCSettingsInlineNotice(kind: .info, text: "You can change this later in Guidance settings.")

            Spacer(minLength: 0)

            VStack(spacing: FCSpacingToken.s8.rawValue) {
                onboardingCTAButton(theme: theme, title: primaryActionTitle) {
                    handlePrimaryAction()
                }

                onboardingNavLinks(theme: theme)
            }
        }
    }

    // MARK: - Surfaces Step

    private func surfacesStep(theme: FCTheme) -> some View {
        VStack(spacing: FCSpacingToken.s12.rawValue) {
            VStack(spacing: FCSpacingToken.s4.rawValue) {
                Text(currentStep.title)
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.titleL)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(currentStep.subtitle)
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.bodyM)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: FCSpacingToken.s8.rawValue) {
                selectionCard(
                    theme: theme,
                    icon: "rectangle.topthird.inset.filled",
                    title: "Pinned to Notch",
                    description: "Keeps FocusCue near your camera for natural eye contact.",
                    accent: .accentInfo,
                    isSelected: draft.overlayMode == .pinned
                ) {
                    draft.overlayMode = .pinned
                }

                selectionCard(
                    theme: theme,
                    icon: "macwindow.on.rectangle",
                    title: "Floating Window",
                    description: "A movable always-on-top teleprompter you can place anywhere.",
                    accent: .accentPrimary,
                    isSelected: draft.overlayMode == .floating
                ) {
                    draft.overlayMode = .floating
                }

                selectionCard(
                    theme: theme,
                    icon: "rectangle.fill",
                    title: "Fullscreen",
                    description: "A dedicated fullscreen teleprompter for studio-style presentations.",
                    accent: .accentCTA,
                    isSelected: draft.overlayMode == .fullscreen
                ) {
                    draft.overlayMode = .fullscreen
                }
            }

            Text("External Display and Remote Browser are available in Settings.")
                .foregroundStyle(theme.color(.textTertiary))
                .fcTypography(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            VStack(spacing: FCSpacingToken.s8.rawValue) {
                onboardingCTAButton(theme: theme, title: primaryActionTitle) {
                    handlePrimaryAction()
                }

                onboardingNavLinks(theme: theme)
            }
        }
    }

    // MARK: - Permission Step

    private func permissionStep(theme: FCTheme, kind: OnboardingPermissionKind) -> some View {
        let currentStatus = status(for: kind)
        let required = isPermissionRequired(kind)
        let statusColor: FCColorToken = {
            switch currentStatus {
            case .authorized: return .stateSuccess
            case .denied: return .stateError
            case .restricted: return .stateWarning
            case .notDetermined: return .textTertiary
            }
        }()
        let statusIcon: String = {
            switch currentStatus {
            case .authorized: return "checkmark.shield.fill"
            case .denied: return "xmark.shield.fill"
            case .restricted: return "exclamationmark.shield.fill"
            case .notDetermined: return kind == .microphone ? "mic.fill" : "waveform.badge.magnifyingglass"
            }
        }()

        return VStack(spacing: FCSpacingToken.s16.rawValue) {
            Spacer(minLength: 0)

            ZStack {
                RoundedRectangle(cornerRadius: FCShapeToken.radius18.rawValue, style: .continuous)
                    .fill(theme.color(statusColor).opacity(0.16))
                Image(systemName: statusIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(theme.color(statusColor))
            }
            .frame(width: 64, height: 64)

            VStack(spacing: FCSpacingToken.s8.rawValue) {
                Text(currentStep.title)
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.titleL)
                    .multilineTextAlignment(.center)

                Text(permissionExplanation(for: kind))
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.bodyM)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: FCSpacingToken.s8.rawValue) {
                statusBadge(theme: theme, title: currentStatus.title, color: statusColor)
                statusBadge(theme: theme, title: required ? "Required" : "Optional", color: required ? .accentInfo : .textTertiary)
            }

            FCSettingsInlineNotice(kind: statusNoticeKind(for: kind), text: permissionSupportText(for: kind))

            Spacer(minLength: 0)

            VStack(spacing: FCSpacingToken.s8.rawValue) {
                onboardingCTAButton(theme: theme, title: primaryActionTitle) {
                    handlePrimaryAction()
                }

                onboardingNavLinks(theme: theme)
            }
        }
    }

    // MARK: - Ready Step

    private func readyStep(theme: FCTheme) -> some View {
        VStack(spacing: FCSpacingToken.s16.rawValue) {
            VStack(spacing: FCSpacingToken.s4.rawValue) {
                Text(currentStep.title)
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.titleL)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(readyStepSubtitle)
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.bodyM)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            summaryCard(theme: theme)

            FCSettingsInlineNotice(kind: readyStepNotice.kind, text: readyStepNotice.text)

            Spacer(minLength: 0)

            VStack(spacing: FCSpacingToken.s8.rawValue) {
                onboardingCTAButton(
                    theme: theme,
                    title: primaryActionTitle,
                    gradient: [.accentCTA, .accentPrimary]
                ) {
                    handlePrimaryAction()
                }

                HStack {
                    if currentStep != .welcome {
                        Button("Back") {
                            goBack()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(theme.color(.accentInfo))
                        .fcTypography(.bodyM)
                    }

                    Spacer()

                    Button("Continue in Settings") {
                        continueInSettings()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.color(.accentInfo))
                    .fcTypography(.bodyM)

                    if readyStepEntitlementState == .trialExpired {
                        Text("•")
                            .foregroundStyle(theme.color(.textTertiary))
                            .fcTypography(.bodyM)

                        Button("Unlock Pro") {
                            openUpgradeFromReadyStep()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(theme.color(.accentCTA))
                        .fcTypography(.bodyM)
                    }
                }
                .frame(height: 32)
            }
        }
    }

    // MARK: - Shared Components

    private func onboardingCTAButton(
        theme: FCTheme,
        title: String,
        gradient: [FCColorToken] = [.accentInfo, .accentPrimary],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .foregroundStyle(.white)
                .fcTypography(.heading)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: gradient.map { theme.color($0) },
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(
                    color: theme.color(gradient[0]).opacity(0.30),
                    radius: 12,
                    y: 4
                )
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.plain)
    }

    private func onboardingNavLinks(theme: FCTheme) -> some View {
        HStack {
            if currentStep != .welcome {
                Button("Back") {
                    goBack()
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.color(.accentInfo))
                .fcTypography(.bodyM)
            }

            Spacer()
        }
        .frame(height: 32)
    }

    private func selectionCard(
        theme: FCTheme,
        icon: String,
        title: String,
        description: String,
        accent: FCColorToken,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                ZStack {
                    RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                        .fill(theme.color(accent).opacity(0.16))
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.color(accent))
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.label)
                    Text(description)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.caption)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(theme.color(accent))
                }
            }
            .padding(FCSpacingToken.s12.rawValue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .fill(isSelected ? theme.color(accent).opacity(0.14) : theme.color(.surfaceOverlay).opacity(0.66))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .stroke(
                        isSelected ? theme.color(.borderFocus) : theme.color(.borderSubtle).opacity(0.56),
                        lineWidth: isSelected ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(theme.animation(.fast), value: isSelected)
    }

    private func featurePill(theme: FCTheme, icon: String, text: String) -> some View {
        HStack(spacing: FCSpacingToken.s4.rawValue) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.color(.accentInfo))
            Text(text)
                .foregroundStyle(theme.color(.textSecondary))
                .fcTypography(.caption)
        }
        .padding(.horizontal, FCSpacingToken.s12.rawValue)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(theme.color(.surfaceOverlay).opacity(0.72))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(theme.color(.borderSubtle).opacity(0.55), lineWidth: FCStrokeToken.thin.rawValue)
        )
    }

    private func statusBadge(theme: FCTheme, title: String, color: FCColorToken) -> some View {
        Text(title)
            .foregroundStyle(theme.color(color))
            .fcTypography(.caption)
            .padding(.horizontal, FCSpacingToken.s8.rawValue)
            .padding(.vertical, FCSpacingToken.s4.rawValue)
            .background(
                Capsule(style: .continuous)
                    .fill(theme.color(color).opacity(0.14))
            )
    }

    private func summaryCard(theme: FCTheme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your setup")
                .foregroundStyle(theme.color(.textPrimary))
                .fcTypography(.label)

            summaryRow(theme: theme, label: "Guidance Mode", value: draft.listeningMode.label)
            summaryRow(theme: theme, label: "Display Style", value: overlayModeTitle(draft.overlayMode))
            summaryRow(theme: theme, label: "Microphone", value: permissions.microphoneStatus.title)
            summaryRow(theme: theme, label: "Speech Recognition", value: permissions.speechStatus.title)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                .fill(theme.color(.surfaceOverlay).opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                .stroke(theme.color(.borderSubtle).opacity(0.58), lineWidth: FCStrokeToken.thin.rawValue)
        )
    }

    private func summaryRow(theme: FCTheme, label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(theme.color(.textSecondary))
                .fcTypography(.caption)
            Spacer()
            Text(value)
                .foregroundStyle(theme.color(.textPrimary))
                .fcTypography(.caption)
        }
    }

    // MARK: - Permission Helpers

    private func overlayModeTitle(_ mode: OverlayMode) -> String {
        switch mode {
        case .pinned:
            return "Pinned to Notch"
        case .floating:
            return "Floating Window"
        case .fullscreen:
            return "Fullscreen"
        }
    }

    private func status(for kind: OnboardingPermissionKind) -> FCPermissionStatus {
        switch kind {
        case .microphone:
            return permissions.microphoneStatus
        case .speechRecognition:
            return permissions.speechStatus
        }
    }

    private func permissionHeadline(for kind: OnboardingPermissionKind) -> String {
        switch kind {
        case .microphone:
            return "Let FocusCue hear your pace."
        case .speechRecognition:
            return "Let FocusCue follow your exact words."
        }
    }

    private func permissionExplanation(for kind: OnboardingPermissionKind) -> String {
        switch kind {
        case .microphone:
            return "If you chose Voice-Activated or Word Tracking, microphone access lets FocusCue respond to your speech in real time."
        case .speechRecognition:
            return "This is what powers Word Tracking. It helps FocusCue keep your place by matching your spoken words to the script in real time."
        }
    }

    private func permissionSupportText(for kind: OnboardingPermissionKind) -> String {
        if pendingPermission == kind {
            return "We're checking access now. This updates as soon as macOS finishes the permission prompt."
        }

        let currentStatus = status(for: kind)

        switch currentStatus {
        case .notDetermined:
            if isPermissionRequired(kind) {
                return "You'll see a standard macOS permission prompt the first time you enable this."
            }
            return "This is optional for your current setup, so you can continue now and enable it later."
        case .authorized:
            switch kind {
            case .microphone:
                return "Microphone access is already enabled. You're ready for voice-driven guidance."
            case .speechRecognition:
                return "Speech recognition is ready for precise word-by-word tracking."
            }
        case .denied:
            if isPermissionRequired(kind) {
                switch kind {
                case .microphone:
                    return "FocusCue cannot follow your voice until access is enabled in System Settings."
                case .speechRecognition:
                    return "Word Tracking needs Speech Recognition to stay aligned with what you say."
                }
            }
            return "You can continue with your current mode and enable this later in Settings."
        case .restricted:
            switch kind {
            case .microphone:
                return "This Mac is restricting microphone access. Classic mode will still work."
            case .speechRecognition:
                return "Word Tracking may be unavailable on this Mac while this restriction is active."
            }
        }
    }

    private func statusNoticeKind(for kind: OnboardingPermissionKind) -> FCSettingsNoticeKind {
        switch status(for: kind) {
        case .authorized:
            return .success
        case .denied, .restricted:
            return .warning
        case .notDetermined:
            return isPermissionRequired(kind) ? .info : .success
        }
    }

    private func isPermissionRequired(_ kind: OnboardingPermissionKind) -> Bool {
        switch kind {
        case .microphone:
            return requiresMicrophone
        case .speechRecognition:
            return requiresSpeechRecognition
        }
    }

    private func permissionPrimaryActionTitle(for kind: OnboardingPermissionKind) -> String {
        if pendingPermission == kind {
            return "Checking Access..."
        }

        let currentStatus = status(for: kind)
        let required = isPermissionRequired(kind)

        switch currentStatus {
        case .authorized, .restricted:
            return "Continue"
        case .denied:
            return required ? "Open System Settings" : "Continue"
        case .notDetermined:
            if !required {
                return "Continue"
            }
            switch kind {
            case .microphone:
                return "Enable Microphone"
            case .speechRecognition:
                return "Enable Speech Recognition"
            }
        }
    }

    // MARK: - Transitions & Navigation

    private var stepTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: direction).combined(with: .opacity),
            removal: .move(edge: direction == .trailing ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func handlePrimaryAction() {
        switch currentStep {
        case .welcome, .modes, .surfaces:
            goNext()
        case .microphone:
            handlePermissionPrimaryAction(.microphone)
        case .speech:
            handlePermissionPrimaryAction(.speechRecognition)
        case .ready:
            handleReadyPrimaryAction()
        }
    }

    private func handleReadyPrimaryAction() {
        switch readyStepEntitlementState {
        case .eligibleForTrial:
            launchGuidedTemplate(shouldStartTrial: true)
        case .trialActive, .pro, .trialExpired:
            launchGuidedTemplate(shouldStartTrial: false)
        }
    }

    private func handlePermissionPrimaryAction(_ kind: OnboardingPermissionKind) {
        guard pendingPermission == nil else { return }

        let currentStatus = status(for: kind)
        let required = isPermissionRequired(kind)

        switch currentStatus {
        case .authorized, .restricted:
            goNext()
        case .denied:
            if required {
                openSystemSettings(for: kind)
            } else {
                goNext()
            }
        case .notDetermined:
            if required {
                requestPermission(for: kind)
            } else {
                goNext()
            }
        }
    }

    private func requestPermission(for kind: OnboardingPermissionKind) {
        pendingPermission = kind

        switch kind {
        case .microphone:
            permissions.requestMicrophoneAccess { status in
                pendingPermission = nil
                handlePermissionResolution(for: kind, status: status)
            }
        case .speechRecognition:
            permissions.requestSpeechAccess { status in
                pendingPermission = nil
                handlePermissionResolution(for: kind, status: status)
            }
        }
    }

    private func openSystemSettings(for kind: OnboardingPermissionKind) {
        switch kind {
        case .microphone:
            permissions.openMicrophoneSettings()
        case .speechRecognition:
            permissions.openSpeechSettings()
        }
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

    private func handlePermissionResolution(for kind: OnboardingPermissionKind, status: FCPermissionStatus) {
        if status == .authorized {
            var updated = draft
            updated.completedPermissions.insert(kind)
            draft = updated

            if isPermissionRequired(kind) {
                goNext()
            }
        }
    }

    private func handleSkipForNow() {
        finish(
            OnboardingCompletion(
                draft: draft,
                applyDraft: false,
                shouldStartTrial: false,
                shouldPresentUpgrade: false,
                launchGuidedTemplate: false,
                openedSettingsTab: nil,
                completionReason: .skippedForNow,
                markOnboardingComplete: false
            )
        )
    }

    private func continueInSettings() {
        finish(
            OnboardingCompletion(
                draft: draft,
                applyDraft: true,
                shouldStartTrial: false,
                shouldPresentUpgrade: false,
                launchGuidedTemplate: false,
                openedSettingsTab: preferredSettingsTab,
                completionReason: .continueInSettings,
                markOnboardingComplete: true
            )
        )
    }

    private func launchGuidedTemplate(shouldStartTrial: Bool = false) {
        session.hasLaunchedGuidedTemplate = true
        finish(
            OnboardingCompletion(
                draft: draft,
                applyDraft: true,
                shouldStartTrial: shouldStartTrial,
                shouldPresentUpgrade: false,
                launchGuidedTemplate: true,
                openedSettingsTab: nil,
                completionReason: .launchGuidedTemplate,
                markOnboardingComplete: true
            )
        )
    }

    private func openUpgradeFromReadyStep() {
        finish(
            OnboardingCompletion(
                draft: draft,
                applyDraft: true,
                shouldStartTrial: false,
                shouldPresentUpgrade: true,
                launchGuidedTemplate: false,
                openedSettingsTab: nil,
                completionReason: .upgradeToPro,
                markOnboardingComplete: true
            )
        )
    }

    private func presentSettingsDetour(tab: SettingsTab) {
        var updated = draft
        updated.selectedAdvancedDestination = tab
        updated.shouldResumeAfterSettings = true
        draft = updated
        session.pendingDetourTab = tab
        detourSettingsTab = tab
        showDetourSettings = true
    }

    private func finish(_ completion: OnboardingCompletion) {
        if completion.markOnboardingComplete {
            session.clearLastVisitedStep()
        } else {
            session.persistLastVisitedStep()
        }

        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onComplete(completion)
        }
    }
}
