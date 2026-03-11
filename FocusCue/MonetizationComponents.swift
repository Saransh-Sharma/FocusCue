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
            return "Unlock Unlimited Scripts"
        case .multiPagePlayback:
            return "Unlock Multi-Page Playback"
        case .autoNextPage:
            return "Unlock Auto Page Turns"
        case .wordTracking:
            return "Unlock Word Tracking"
        case .deepgramBackend:
#if APP_STORE_BUILD
            return "Unlock FocusCue Pro"
#else
            return "Unlock Cloud Recognition"
#endif
        case .smartResync:
#if APP_STORE_BUILD
            return "Unlock FocusCue Pro"
#else
            return "Unlock Smart Resync"
#endif
        case .aiRefinement:
#if APP_STORE_BUILD
            return "Unlock FocusCue Pro"
#else
            return "Unlock AI Refinement"
#endif
        case .pptxImport:
            return "Unlock PPTX Import"
        case .fullscreenOverlay:
            return "Unlock Fullscreen Mode"
        case .externalDisplay:
            return "Unlock External Output"
        case .browserRemote:
            return "Unlock Browser Remote"
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
#if APP_STORE_BUILD
            return "Browser remote, fullscreen playback, and multi-page delivery are unlocked in FocusCue Pro."
#else
            return "Cloud speech recognition and Pro-grade accuracy upgrades are unlocked in Pro."
#endif
        case .smartResync:
#if APP_STORE_BUILD
            return "Browser remote, fullscreen playback, and multi-page delivery are unlocked in FocusCue Pro."
#else
            return "Smart Resync keeps you aligned when you paraphrase and is reserved for Pro."
#endif
        case .aiRefinement:
#if APP_STORE_BUILD
            return "PPTX import, automatic page turns, and multi-page delivery are unlocked in FocusCue Pro."
#else
            return "AI script cleanup and polishing are part of FocusCue Pro."
#endif
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
                "Automatic page turns",
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
#if APP_STORE_BUILD
            return [
                "Word Tracking",
                "Remote browser viewer",
                "External display output",
            ]
#else
            return [
                "Higher-accuracy cloud recognition",
                "Better performance on complex reads",
                "Full Pro guidance stack",
            ]
#endif
        case .smartResync:
#if APP_STORE_BUILD
            return [
                "Word Tracking",
                "Automatic page turns",
                "Full Pro guidance",
            ]
#else
            return [
                "Recover after going off-script",
                "Smoother live delivery",
                "Advanced Pro guidance",
            ]
#endif
        case .aiRefinement:
#if APP_STORE_BUILD
            return [
                "Unlimited multi-page scripts",
                "PPTX notes import",
                "Faster prompt preparation",
            ]
#else
            return [
                "Clean filler words",
                "Polish raw transcripts into scripts",
                "Faster draft-to-teleprompter workflow",
            ]
#endif
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
            return .accentPrimary
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

struct FCInlineEntitlementWidget: View {
    @Bindable var entitlements: EntitlementService
    let onUpgrade: () -> Void
    let onRestore: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        switch entitlements.brandState {
        case .lite:
            liteWidget(theme: theme)
        case .proTrial(let daysRemaining):
            trialWidget(theme: theme, daysRemaining: daysRemaining)
        case .checking, .pro:
            FCTierBadge(brandState: entitlements.brandState)
        }
    }

    @ViewBuilder
    private func liteWidget(theme: FCTheme) -> some View {
        HStack(spacing: FCSpacingToken.s8.rawValue) {
            FCTierBadge(brandState: .lite)
            upgradePill(theme: theme)
            Button(action: onRestore) {
                Text("Restore")
                    .fcTypography(.caption)
                    .foregroundStyle(theme.color(.textTertiary))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func trialWidget(theme: FCTheme, daysRemaining: Int) -> some View {
        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
            HStack(alignment: .firstTextBaseline) {
                Text("Pro Trial")
                    .fcTypography(.label)
                    .foregroundStyle(theme.color(.textPrimary))
                Spacer()
                Text("\(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining")
                    .fcTypography(.caption)
                    .foregroundStyle(theme.color(.accentPrimary))
            }

            GeometryReader { proxy in
                let progress = CGFloat(Double(entitlements.daysUsed) / 14.0)
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(theme.color(.accentPrimary).opacity(0.12))
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.color(.accentPrimary), theme.color(.accentInfo)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, proxy.size.width * progress))
                }
            }
            .frame(height: 5)
            .clipShape(Capsule(style: .continuous))

            HStack(spacing: FCSpacingToken.s8.rawValue) {
                upgradePill(theme: theme)

                Button(action: onRestore) {
                    Text("Restore")
                        .fcTypography(.caption)
                        .foregroundStyle(theme.color(.textTertiary))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FCSpacingToken.s12.rawValue)
        .padding(.vertical, FCSpacingToken.s8.rawValue)
        .frame(width: 240)
        .background(
            RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                .fill(theme.material(.card))
        )
        .background(
            RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                .fill(theme.color(.surfaceGlass))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                .stroke(theme.color(.accentPrimary).opacity(0.16), lineWidth: FCStrokeToken.thin.rawValue)
        )
    }

    @ViewBuilder
    private func upgradePill(theme: FCTheme) -> some View {
        Button(action: onUpgrade) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))
                Text("Upgrade to Pro")
                    .fcTypography(.caption)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, FCSpacingToken.s12.rawValue)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.color(.accentPrimary), theme.color(.accentInfo)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct FCPaywallSheet: View {
    let feature: FeatureGate
    @Bindable var entitlements: EntitlementService
    let onPurchase: () -> Void
    let onRestore: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(alignment: .leading, spacing: FCSpacingToken.s20.rawValue) {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                FCBrandIconView(size: 36, cornerRadius: FCShapeToken.radius10.rawValue, shadowRadius: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.paywallTitle)
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.titleM)
                    Text(feature.paywallBody)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.bodyM)
                }
                Spacer()
                FCTierBadge(brandState: entitlements.brandState)
            }

            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                ForEach(feature.paywallBullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: FCSpacingToken.s8.rawValue) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.color(.stateSuccess))
                        Text(bullet)
                            .foregroundStyle(theme.color(.textPrimary))
                            .fcTypography(.label)
                    }
                }
            }
            .padding(FCSpacingToken.s16.rawValue)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .fill(theme.color(.surfaceGlass))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
            )

            if let proProduct = entitlements.proProduct {
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Text("One-time purchase")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.caption)
                    Text(proProduct.displayPrice)
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.heading)
                }
                .padding(.horizontal, FCSpacingToken.s16.rawValue)
                .padding(.vertical, FCSpacingToken.s12.rawValue)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                        .fill(theme.color(.stateSuccess).opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                        .stroke(theme.color(.stateSuccess).opacity(0.20), lineWidth: FCStrokeToken.thin.rawValue)
                )
            }

            if let storeErrorMessage = entitlements.storeErrorMessage, !storeErrorMessage.isEmpty {
                Text(storeErrorMessage)
                    .fcTypography(.caption)
                    .foregroundStyle(theme.color(.stateError))
            }

            HStack(spacing: FCSpacingToken.s12.rawValue) {
                Button(action: onDismiss) {
                    Text("Maybe later")
                        .fcTypography(.label)
                        .foregroundStyle(theme.color(.textTertiary))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onRestore) {
                    Text("Restore Purchases")
                        .fcTypography(.label)
                        .foregroundStyle(theme.color(.textSecondary))
                        .padding(.horizontal, FCSpacingToken.s16.rawValue)
                        .padding(.vertical, FCSpacingToken.s12.rawValue)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.color(.surfaceGlass))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(entitlements.isRestoring || entitlements.isPurchasing)

                Button(action: onPurchase) {
                    HStack(spacing: FCSpacingToken.s8.rawValue) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                        Text(entitlements.isPurchasing ? "Purchasing\u{2026}" : "Unlock Pro")
                            .fcTypography(.label)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, FCSpacingToken.s20.rawValue)
                    .padding(.vertical, FCSpacingToken.s12.rawValue)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.color(.accentPrimary).opacity(0.90),
                                        theme.color(.accentInfo),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.20), lineWidth: FCStrokeToken.thin.rawValue)
                    )
                    .shadow(
                        color: theme.color(.accentPrimary).opacity(FCEffectToken.shadowSoft.opacity),
                        radius: FCEffectToken.shadowSoft.blur,
                        y: FCEffectToken.shadowSoft.yOffset
                    )
                }
                .buttonStyle(.plain)
                .disabled(entitlements.isRestoring || entitlements.isPurchasing)
            }
        }
        .padding(FCSpacingToken.s24.rawValue)
        .frame(width: 520)
        .background(theme.material(.sheet))
        .background(theme.color(.surfaceGlassStrong).opacity(0.92))
    }
}

struct FCTrialOfferSheet: View {
    @Bindable var entitlements: EntitlementService
    let onStartTrial: () -> Void
    let onPurchase: () -> Void
    let onSkip: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(alignment: .leading, spacing: FCSpacingToken.s20.rawValue) {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                FCBrandIconView(size: 36, cornerRadius: FCShapeToken.radius10.rawValue, shadowRadius: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Try FocusCue Pro free for 14 days")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.titleM)
                    Text("Full access to every Pro workflow. After that, FocusCue continues in Lite with one active page.")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.bodyM)
                }
            }

            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                trialBullet(theme: theme, text: "Unlimited multi-page scripts")
                trialBullet(theme: theme, text: "Word Tracking")
                trialBullet(theme: theme, text: "External display and browser remote")
                trialBullet(theme: theme, text: "PPTX import and automatic page turns")
            }
            .padding(FCSpacingToken.s16.rawValue)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .fill(theme.color(.surfaceGlass))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
            )

            if let proProduct = entitlements.proProduct {
                Text("Or unlock Pro permanently for \(proProduct.displayPrice)")
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.caption)
            }

            if let storeErrorMessage = entitlements.storeErrorMessage, !storeErrorMessage.isEmpty {
                Text(storeErrorMessage)
                    .fcTypography(.caption)
                    .foregroundStyle(theme.color(.stateError))
            }

            HStack(spacing: FCSpacingToken.s12.rawValue) {
                Button(action: onSkip) {
                    Text("Maybe later")
                        .fcTypography(.label)
                        .foregroundStyle(theme.color(.textTertiary))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onPurchase) {
                    Text("Unlock Pro")
                        .fcTypography(.label)
                        .foregroundStyle(theme.color(.textSecondary))
                        .padding(.horizontal, FCSpacingToken.s16.rawValue)
                        .padding(.vertical, FCSpacingToken.s12.rawValue)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.color(.surfaceGlass))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(entitlements.isPurchasing || entitlements.isRestoring)

                Button(action: onStartTrial) {
                    HStack(spacing: FCSpacingToken.s8.rawValue) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Start 14-Day Trial")
                            .fcTypography(.label)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, FCSpacingToken.s20.rawValue)
                    .padding(.vertical, FCSpacingToken.s12.rawValue)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.color(.accentPrimary).opacity(0.90),
                                        theme.color(.accentInfo),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.20), lineWidth: FCStrokeToken.thin.rawValue)
                    )
                    .shadow(
                        color: theme.color(.accentPrimary).opacity(FCEffectToken.shadowSoft.opacity),
                        radius: FCEffectToken.shadowSoft.blur,
                        y: FCEffectToken.shadowSoft.yOffset
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FCSpacingToken.s24.rawValue)
        .frame(width: 520)
        .background(theme.material(.sheet))
        .background(theme.color(.surfaceGlassStrong).opacity(0.92))
    }

    @ViewBuilder
    private func trialBullet(theme: FCTheme, text: String) -> some View {
        HStack(alignment: .top, spacing: FCSpacingToken.s8.rawValue) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.color(.stateSuccess))
            Text(text)
                .foregroundStyle(theme.color(.textPrimary))
                .fcTypography(.label)
        }
    }
}

struct FCProUnlockedSheet: View {
    let source: ProUnlockSource
    let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sourceDetail: String {
        switch source {
        case .purchase:
            return "Your purchase is complete. Word Tracking is now active."
        case .restore:
            return "Your purchase has been restored. Word Tracking is now active."
        }
    }

    private let unlockedFeatures = [
        "Unlimited scripts",
        "Word Tracking",
        "Fullscreen mode",
        "External display",
        "Browser remote",
        "PPTX import",
        "Automatic page turns",
    ]

    private let gridColumns = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible(), alignment: .leading),
    ]

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(spacing: FCSpacingToken.s16.rawValue) {
            VStack(spacing: FCSpacingToken.s8.rawValue) {
                FCBrandIconView(size: 48, cornerRadius: FCShapeToken.radius14.rawValue, shadowRadius: 8)
                    .padding(.bottom, FCSpacingToken.s4.rawValue)

                FCTierBadge(brandState: .pro)

                Text("FocusCue Pro is unlocked")
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.titleM)

                Text("Every professional teleprompter workflow is now available.")
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.bodyM)

                Text(sourceDetail)
                    .foregroundStyle(theme.color(.textTertiary))
                    .fcTypography(.caption)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                ForEach(unlockedFeatures, id: \.self) { feature in
                    HStack(spacing: FCSpacingToken.s8.rawValue) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.color(.stateSuccess))
                        Text(feature)
                            .foregroundStyle(theme.color(.textPrimary))
                            .fcTypography(.label)
                    }
                }
            }
            .padding(FCSpacingToken.s16.rawValue)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .fill(theme.color(.surfaceGlass))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
            )

            Button(action: onContinue) {
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Start Using Pro")
                        .fcTypography(.label)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.color(.accentPrimary).opacity(0.90),
                                    theme.color(.accentInfo),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: FCStrokeToken.thin.rawValue)
                )
                .shadow(
                    color: theme.color(.accentPrimary).opacity(FCEffectToken.shadowSoft.opacity),
                    radius: FCEffectToken.shadowSoft.blur,
                    y: FCEffectToken.shadowSoft.yOffset
                )
            }
            .buttonStyle(.plain)
        }
        .padding(FCSpacingToken.s24.rawValue)
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
        .background(theme.material(.sheet))
        .background(theme.color(.surfaceGlassStrong).opacity(0.92))
    }
}

struct FCDowngradeSheet: View {
    @Bindable var entitlements: EntitlementService
    let onContinue: () -> Void
    let onPurchase: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(alignment: .leading, spacing: FCSpacingToken.s20.rawValue) {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                FCBrandIconView(size: 36, cornerRadius: FCShapeToken.radius10.rawValue, shadowRadius: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Pro trial has ended")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.titleM)
                    Text("FocusCue continues in Lite. All your scripts are safe \u{2014} one page stays editable and playable at a time.")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.bodyM)
                }
            }

            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                downgradeBullet(theme: theme, icon: "doc.text", text: "Keep one page active in Lite")
                downgradeBullet(theme: theme, icon: "arrow.left.arrow.right.circle", text: "Choose any visible page to make it your Lite page")
                downgradeBullet(theme: theme, icon: "sparkles", text: "Upgrade anytime to restore unlimited workflows")
            }
            .padding(FCSpacingToken.s16.rawValue)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .fill(theme.color(.surfaceGlass))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
            )

            HStack(spacing: FCSpacingToken.s12.rawValue) {
                Button(action: onContinue) {
                    Text("Continue with Lite")
                        .fcTypography(.label)
                        .foregroundStyle(theme.color(.textSecondary))
                        .padding(.horizontal, FCSpacingToken.s16.rawValue)
                        .padding(.vertical, FCSpacingToken.s12.rawValue)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.color(.surfaceGlass))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onPurchase) {
                    HStack(spacing: FCSpacingToken.s8.rawValue) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Unlock Pro")
                            .fcTypography(.label)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, FCSpacingToken.s20.rawValue)
                    .padding(.vertical, FCSpacingToken.s12.rawValue)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.color(.accentPrimary).opacity(0.90),
                                        theme.color(.accentInfo),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.20), lineWidth: FCStrokeToken.thin.rawValue)
                    )
                    .shadow(
                        color: theme.color(.accentPrimary).opacity(FCEffectToken.shadowSoft.opacity),
                        radius: FCEffectToken.shadowSoft.blur,
                        y: FCEffectToken.shadowSoft.yOffset
                    )
                }
                .buttonStyle(.plain)
                .disabled(entitlements.isPurchasing || entitlements.isRestoring)
            }
        }
        .padding(FCSpacingToken.s24.rawValue)
        .frame(width: 520)
        .background(theme.material(.sheet))
        .background(theme.color(.surfaceGlassStrong).opacity(0.92))
    }

    @ViewBuilder
    private func downgradeBullet(theme: FCTheme, icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: FCSpacingToken.s8.rawValue) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.color(.accentInfo))
            Text(text)
                .foregroundStyle(theme.color(.textSecondary))
                .fcTypography(.label)
        }
    }
}

struct FCLitePageAccessSheet: View {
    let onUseThisPage: () -> Void
    let onUpgrade: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(alignment: .leading, spacing: FCSpacingToken.s20.rawValue) {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                FCBrandIconView(size: 36, cornerRadius: FCShapeToken.radius10.rawValue, shadowRadius: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text("This page is locked in Lite")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.titleM)
                    Text("Lite keeps one page editable and playable at a time. You can make this page your active Lite page, or unlock Pro to keep everything available at once.")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.bodyM)
                }
            }

            HStack(spacing: FCSpacingToken.s12.rawValue) {
                Button(action: onUseThisPage) {
                    Text("Use This Page in Lite")
                        .fcTypography(.label)
                        .foregroundStyle(theme.color(.textSecondary))
                        .padding(.horizontal, FCSpacingToken.s16.rawValue)
                        .padding(.vertical, FCSpacingToken.s12.rawValue)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.color(.surfaceGlass))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onUpgrade) {
                    HStack(spacing: FCSpacingToken.s8.rawValue) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Upgrade to Pro")
                            .fcTypography(.label)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, FCSpacingToken.s20.rawValue)
                    .padding(.vertical, FCSpacingToken.s12.rawValue)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.color(.accentPrimary).opacity(0.90),
                                        theme.color(.accentInfo),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.20), lineWidth: FCStrokeToken.thin.rawValue)
                    )
                    .shadow(
                        color: theme.color(.accentPrimary).opacity(FCEffectToken.shadowSoft.opacity),
                        radius: FCEffectToken.shadowSoft.blur,
                        y: FCEffectToken.shadowSoft.yOffset
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FCSpacingToken.s24.rawValue)
        .frame(width: 500)
        .background(theme.material(.sheet))
        .background(theme.color(.surfaceGlassStrong).opacity(0.92))
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
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("Pro")
                                    .fcTypography(.caption)
                            }
                            .foregroundStyle(theme.color(.accentPrimary))
                            .padding(.horizontal, FCSpacingToken.s8.rawValue)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                theme.color(.accentPrimary).opacity(0.14),
                                                theme.color(.accentInfo).opacity(0.10),
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(theme.color(.accentPrimary).opacity(0.20), lineWidth: FCStrokeToken.thin.rawValue)
                            )
                        }
                        .buttonStyle(.plain)
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
