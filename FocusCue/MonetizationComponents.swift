//
//  MonetizationComponents.swift
//  FocusCue
//

import SwiftUI

struct FCTierBadge: View {
    let brandState: BrandState

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        Text(brandState.label)
            .foregroundStyle(theme.color(.stateSuccess))
            .fcTypography(.caption)
            .padding(.horizontal, FCSpacingToken.s12.rawValue)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(theme.color(.stateSuccess).opacity(0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(theme.color(.stateSuccess).opacity(0.22), lineWidth: FCStrokeToken.thin.rawValue)
            )
    }
}

struct FCInlineEntitlementWidget: View {
    @Bindable var entitlements: EntitlementService

    var body: some View {
        FCTierBadge(brandState: entitlements.brandState)
    }
}

struct FCProLockedRow<Content: View>: View {
    let title: String
    let isLocked: Bool
    let onUpgrade: () -> Void
    @ViewBuilder let content: Content

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
        let _ = isLocked
        let _ = onUpgrade

        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
            if !title.isEmpty {
                Text(title)
                    .fcTypography(.label)
            }
            content
        }
    }
}
