//
//  MonetizationComponents.swift
//  FocusCue
//

import SwiftUI
import StoreKit

extension FeatureGate {
    var paywallTitle: String {
        switch self {
        case .generalAccess:
            return "Unlock FocusCue Pro"
        case .multiPageEditing:
            return "Unlimited Scripts Are Pro"
        case .multiPagePlayback:
            return "Multi-Page Playback Is Pro"
        case .autoNextPage:
            return "Auto Next Page Is Pro"
        case .wordTracking:
            return "Word Tracking Is Pro"
        case .deepgramBackend:
            return "Deepgram Is Pro"
        case .smartResync:
            return "Smart Resync Is Pro"
        case .aiRefinement:
            return "AI Refinement Is Pro"
        case .pptxImport:
            return "PPTX Import Is Pro"
        case .fullscreenOverlay:
            return "Fullscreen Mode Is Pro"
        case .externalDisplay:
            return "External Output Is Pro"
        case .browserRemote:
            return "Remote Browser Output Is Pro"
        }
    }

    var paywallBody: String {
        switch self {
        case .generalAccess:
            return "Unlock unlimited scripts and professional teleprompter workflows."
        case .multiPageEditing:
            return "Lite keeps one page editable at a time. Upgrade to edit, organize, and manage your full script library."
        case .multiPagePlayback:
            return "Lite plays the active page only. Upgrade to run complete multi-page sequences."
        case .autoNextPage:
            return "Automatic countdown page turns are available in FocusCue Pro."
        case .wordTracking:
            return "Real-time spoken-word highlighting is part of the Pro guidance toolkit."
        case .deepgramBackend:
            return "Cloud speech recognition and Pro-grade accuracy upgrades are unlocked in Pro."
        case .smartResync:
            return "Smart Resync keeps you aligned when you paraphrase and is reserved for Pro."
        case .aiRefinement:
            return "AI script cleanup and polishing are part of FocusCue Pro."
        case .pptxImport:
            return "Importing presenter notes from PowerPoint is a Pro productivity workflow."
        case .fullscreenOverlay:
            return "Fullscreen teleprompter output on any display is available in Pro."
        case .externalDisplay:
            return "External teleprompter and mirror-rig output are part of FocusCue Pro."
        case .browserRemote:
            return "Live browser viewer output for phones, TVs, and operator screens is unlocked in Pro."
        }
    }

    var paywallBullets: [String] {
        switch self {
        case .generalAccess:
            return [
                "Unlimited multi-page scripts",
                "Word Tracking",
                "External teleprompter and mirror outputs",
                "Remote browser viewer",
                "PPTX notes import",
                "AI sync and refinement",
            ]
        case .multiPageEditing:
            return [
                "Create and edit unlimited pages",
                "Reorder and archive scripts",
                "Keep full script libraries unlocked",
            ]
        case .multiPagePlayback:
            return [
                "Play full live sequences",
                "Advance across multiple pages",
                "Use countdown-based page turns",
            ]
        case .autoNextPage:
            return [
                "Hands-free page turns",
                "Countdown pacing",
                "Full multi-page delivery",
            ]
        case .wordTracking:
            return [
                "True spoken-word highlighting",
                "More natural delivery",
                "Best-fit for high-precision reads",
            ]
        case .deepgramBackend:
            return [
                "Higher-accuracy cloud recognition",
                "Better performance on complex reads",
                "Full Pro guidance stack",
            ]
        case .smartResync:
            return [
                "Recover after going off-script",
                "Smoother live delivery",
                "Advanced Pro guidance",
            ]
        case .aiRefinement:
            return [
                "Clean filler words",
                "Polish raw transcripts into scripts",
                "Faster draft-to-teleprompter workflow",
            ]
        case .pptxImport:
            return [
                "Convert presenter notes into pages",
                "Save setup time before sessions",
                "Keep slide workflows intact",
            ]
        case .fullscreenOverlay:
            return [
                "Dedicated fullscreen teleprompter",
                "Better studio and recording setups",
                "Pro delivery surfaces",
            ]
        case .externalDisplay:
            return [
                "Sidecar and external display output",
                "Mirror-rig support",
                "Professional multi-screen setups",
            ]
        case .browserRemote:
            return [
                "Phone or TV viewer on local Wi-Fi",
                "Operator-friendly monitoring",
                "More flexible production workflows",
            ]
        }
    }
}

struct FCTierBadge: View {
    let brandState: BrandState

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: FCColorToken {
        switch brandState {
        case .checking:
            return .accentInfo
        case .lite:
            return .stateWarning
        case .proTrial:
            return .accentCTA
        case .pro:
            return .stateSuccess
        }
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        Text(brandState.label)
            .foregroundStyle(theme.color(accent))
            .fcTypography(.caption)
            .padding(.horizontal, FCSpacingToken.s12.rawValue)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(theme.color(accent).opacity(0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(theme.color(accent).opacity(0.22), lineWidth: FCStrokeToken.thin.rawValue)
            )
    }
}

struct FCEntitlementStatusCard: View {
    @Bindable var entitlements: EntitlementService
    let onUpgrade: () -> Void
    let onRestore: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: FCColorToken {
        switch entitlements.brandState {
        case .checking:
            return .accentInfo
        case .lite:
            return .stateWarning
        case .proTrial:
            return .accentCTA
        case .pro:
            return .stateSuccess
        }
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        FCGlassPanel(emphasized: true) {
            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                HStack(alignment: .firstTextBaseline, spacing: FCSpacingToken.s12.rawValue) {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                        Text(entitlements.statusHeadline)
                            .foregroundStyle(theme.color(.textPrimary))
                            .fcTypography(.heading)
                        Text(entitlements.statusDetail)
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.bodyM)
                    }
                    Spacer()
                    FCTierBadge(brandState: entitlements.brandState)
                }

                if entitlements.tier == .trial {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule(style: .continuous)
                                .fill(theme.color(.accentCTA).opacity(0.14))
                            Capsule(style: .continuous)
                                .fill(theme.color(.accentCTA))
                                .frame(width: max(18, proxy.size.width * CGFloat(Double(entitlements.daysUsed) / 14.0)))
                        }
                    }
                    .frame(height: 8)
                }

                Text(entitlements.statusFootnote)
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.caption)

                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    if entitlements.tier != .pro {
                        Button(action: onUpgrade) {
                            Text("Upgrade to Pro")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    Button(action: onRestore) {
                        Text("Restore Purchases")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: FCShapeToken.radius18.rawValue, style: .continuous)
                .stroke(theme.color(accent).opacity(0.18), lineWidth: FCStrokeToken.thin.rawValue)
        )
    }
}

struct FCPaywallSheet: View {
    let feature: FeatureGate
    @Bindable var entitlements: EntitlementService
    let onPurchase: () -> Void
    let onRestore: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(feature.paywallTitle)
                        .font(.system(size: 24, weight: .bold))
                    Text(feature.paywallBody)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                FCTierBadge(brandState: entitlements.brandState)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(feature.paywallBullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(bullet)
                            .font(.system(size: 13))
                    }
                }
            }
            .padding(14)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let proProduct = entitlements.proProduct {
                Text("Lifetime unlock: \(proProduct.displayPrice)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            if let storeErrorMessage = entitlements.storeErrorMessage, !storeErrorMessage.isEmpty {
                Text(storeErrorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 12) {
                Button("Not now") {
                    onDismiss()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Restore Purchases") {
                    onRestore()
                }
                .buttonStyle(.bordered)
                .disabled(entitlements.isRestoring || entitlements.isPurchasing)

                Button(entitlements.isPurchasing ? "Purchasing…" : "Unlock Pro") {
                    onPurchase()
                }
                .buttonStyle(.borderedProminent)
                .disabled(entitlements.isRestoring || entitlements.isPurchasing)
            }
        }
        .padding(24)
        .frame(width: 500)
        .background(.regularMaterial)
    }
}

struct FCTrialOfferSheet: View {
    @Bindable var entitlements: EntitlementService
    let onStartTrial: () -> Void
    let onPurchase: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Start your 14-day Pro trial")
                .font(.system(size: 24, weight: .bold))
            Text("You’ll get full access to every Pro workflow for 14 days. After that, FocusCue stays usable in Lite with one active page.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Label("Unlimited multi-page scripts", systemImage: "checkmark.circle.fill")
                Label("Word Tracking and Smart Resync", systemImage: "checkmark.circle.fill")
                Label("External display and browser remote", systemImage: "checkmark.circle.fill")
                Label("PPTX import and AI refinement", systemImage: "checkmark.circle.fill")
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)

            if let storeErrorMessage = entitlements.storeErrorMessage, !storeErrorMessage.isEmpty {
                Text(storeErrorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 12) {
                Button("Not now") {
                    onSkip()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Unlock Pro") {
                    onPurchase()
                }
                .buttonStyle(.bordered)
                .disabled(entitlements.isPurchasing || entitlements.isRestoring)

                Button("Start 14-Day Trial") {
                    onStartTrial()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 500)
        .background(.regularMaterial)
    }
}

struct FCDowngradeSheet: View {
    @Bindable var entitlements: EntitlementService
    let onContinue: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your Pro trial has ended")
                .font(.system(size: 24, weight: .bold))
            Text("FocusCue is now in Lite. All of your scripts are still here, but only one page can be edited and played at a time.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Label("Keep one page active in Lite", systemImage: "doc.text")
                Label("Choose any visible page to make it your Lite page", systemImage: "arrow.left.arrow.right.circle")
                Label("Upgrade anytime to restore unlimited workflows", systemImage: "sparkles")
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Continue in Lite") {
                    onContinue()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Unlock Pro") {
                    onPurchase()
                }
                .buttonStyle(.borderedProminent)
                .disabled(entitlements.isPurchasing || entitlements.isRestoring)
            }
        }
        .padding(24)
        .frame(width: 500)
        .background(.regularMaterial)
    }
}

struct FCLitePageAccessSheet: View {
    let onUseThisPage: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("This page is locked in Lite")
                .font(.system(size: 22, weight: .bold))
            Text("Lite keeps one page editable and playable at a time. You can make this page your active Lite page, or unlock Pro to keep everything available at once.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Use This Page in Lite") {
                    onUseThisPage()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Upgrade to Pro") {
                    onUpgrade()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
        .background(.regularMaterial)
    }
}

struct FCProLockedRow<Content: View>: View {
    let title: String
    let isLocked: Bool
    let onUpgrade: () -> Void
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        title: String,
        isLocked: Bool,
        onUpgrade: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isLocked = isLocked
        self.onUpgrade = onUpgrade
        self.content = content()
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
            if !title.isEmpty || isLocked {
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    if !title.isEmpty {
                        Text(title)
                            .foregroundStyle(theme.color(.textPrimary))
                            .fcTypography(.label)
                    }
                    if isLocked {
                        Spacer()
                        Button(action: onUpgrade) {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("Pro")
                                    .fcTypography(.caption)
                            }
                            .padding(.horizontal, FCSpacingToken.s8.rawValue)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(theme.color(.stateWarning).opacity(0.14))
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(theme.color(.stateWarning))
                    }
                }
            }

            content
                .allowsHitTesting(!isLocked)
                .opacity(isLocked ? 0.55 : 1)
                .overlay {
                    if isLocked {
                        Button(action: onUpgrade) {
                            Color.clear
                        }
                        .buttonStyle(.plain)
                    }
                }
        }
    }
}
