//
//  MainWindowComponents.swift
//  FocusCue
//

import SwiftUI

struct FCWindowBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        ZStack {
            LinearGradient(
                colors: [
                    theme.color(.bgCanvasTop),
                    theme.color(.bgCanvasBottom),
                    theme.color(.bgCanvas),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(theme.color(.accentInfo).opacity(colorScheme == .dark ? 0.10 : 0.14))
                .frame(width: 420, height: 420)
                .blur(radius: 80)
                .offset(x: -220, y: -180)

            Circle()
                .fill(theme.color(.accentPrimary).opacity(colorScheme == .dark ? 0.10 : 0.14))
                .frame(width: 460, height: 460)
                .blur(radius: 90)
                .offset(x: 240, y: 220)
        }
    }
}

struct FCGlassPanel<Content: View>: View {
    let emphasized: Bool
    let includePadding: Bool
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(emphasized: Bool = false, includePadding: Bool = true, @ViewBuilder content: () -> Content) {
        self.emphasized = emphasized
        self.includePadding = includePadding
        self.content = content()
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let corner = FCShapeToken.radius18.rawValue
        let fillToken: FCColorToken = emphasized ? .surfaceGlassStrong : .surfaceGlass

        Group {
            if includePadding {
                content
                    .padding(FCSpacingToken.s16.rawValue)
            } else {
                content
            }
        }
        .background(theme.material(.card))
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(theme.color(fillToken))
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.medium.rawValue)
        )
        .shadow(
            color: Color.black.opacity(FCEffectToken.shadowSoft.opacity),
            radius: FCEffectToken.shadowSoft.blur,
            y: FCEffectToken.shadowSoft.yOffset
        )
    }
}

struct FCWindowHeader: View {
    let subtitle: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                ZStack {
                    RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.color(.accentInfo), theme.color(.accentPrimary)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "text.word.spacing")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)
                .shadow(color: theme.color(.accentInfo).opacity(FCEffectToken.focusGlow.opacity), radius: 14, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("FocusCue")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.titleM)
                    Text(subtitle)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.bodyM)
                }
                Spacer()
            }
        }
    }
}

struct FCPageRailItemModel: Identifiable {
    let index: Int
    let isRead: Bool
    let isCurrent: Bool
    let preview: String

    var id: Int { index }
}

struct FCPageRail: View {
    let items: [FCPageRailItemModel]
    let canDelete: Bool
    let onSelect: (Int) -> Void
    let onDelete: (Int) -> Void
    let onAdd: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        FCGlassPanel {
            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                HStack {
                    Text("Pages")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.label)
                    Spacer()
                    Text("\(items.count)")
                        .foregroundStyle(theme.color(.textTertiary))
                        .fcTypography(.mono)
                }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: FCSpacingToken.s8.rawValue) {
                        ForEach(items) { item in
                            FCPageRailRow(
                                item: item,
                                canDelete: canDelete,
                                onSelect: { onSelect(item.index) },
                                onDelete: { onDelete(item.index) }
                            )
                        }
                    }
                }

                Button(action: onAdd) {
                    HStack(spacing: FCSpacingToken.s8.rawValue) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add Page")
                            .fcTypography(.label)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 34)
                    .foregroundStyle(theme.color(.accentPrimary))
                    .background(
                        RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                            .fill(theme.color(.accentPrimary).opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 172)
    }
}

private struct FCPageRailRow: View {
    let item: FCPageRailItemModel
    let canDelete: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let background = item.isCurrent
            ? theme.color(.accentInfo).opacity(0.24)
            : (isHovered ? theme.color(.surfaceGlassStrong).opacity(0.68) : theme.color(.surfaceGlass).opacity(0.42))

        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Text("Page \(item.index + 1)")
                        .foregroundStyle(item.isCurrent ? theme.color(.textPrimary) : theme.color(.textSecondary))
                        .fcTypography(.label)
                    Spacer(minLength: 0)
                    if item.isRead && !item.isCurrent {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.color(.stateSuccess))
                    }
                }
                if !item.preview.isEmpty {
                    Text(item.preview)
                        .foregroundStyle(theme.color(.textTertiary))
                        .lineLimit(1)
                        .fcTypography(.caption)
                }
            }
            .padding(.horizontal, FCSpacingToken.s12.rawValue)
            .padding(.vertical, FCSpacingToken.s8.rawValue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                    .stroke(
                        item.isCurrent ? theme.color(.borderFocus) : .clear,
                        lineWidth: item.isCurrent ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if canDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Page", systemImage: "trash")
                }
            }
        }
        .onHover { hovering in
            withAnimation(theme.animation(.fast)) {
                isHovered = hovering
            }
        }
    }
}

struct FCQuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: FCColorToken
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        Button(action: action) {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                ZStack {
                    RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                        .fill(theme.color(accent).opacity(0.20))
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.color(accent))
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.label)
                    Text(subtitle)
                        .foregroundStyle(theme.color(.textTertiary))
                        .lineLimit(1)
                        .fcTypography(.caption)
                }
                Spacer(minLength: 0)
            }
            .padding(FCSpacingToken.s12.rawValue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .fill(
                        isHovered
                            ? theme.color(.surfaceGlassStrong).opacity(0.86)
                            : theme.color(.surfaceGlass).opacity(0.62)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
            )
            .contentShape(RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(theme.animation(.fast)) {
                isHovered = hovering
            }
        }
    }
}

struct FCCommandCenter: View {
    let fileName: String?
    let hasUnsavedChanges: Bool
    let modeLabel: String
    let modeDescription: String
    let onOpenDocument: (() -> Void)?
    let onDraft: () -> Void
    let onAddPage: () -> Void
    let onSettings: () -> Void
    let onOpenOnboarding: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        FCGlassPanel {
            VStack(alignment: .leading, spacing: FCSpacingToken.s16.rawValue) {
                VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                    Text("Command Center")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.heading)
                    Text("Fast access to core actions and setup.")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.bodyM)
                }

                FCGlassPanel(emphasized: true) {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                        HStack(spacing: FCSpacingToken.s8.rawValue) {
                            Circle()
                                .fill(hasUnsavedChanges ? theme.color(.stateWarning) : theme.color(.stateSuccess))
                                .frame(width: 8, height: 8)
                            Text(fileName ?? "Untitled Script")
                                .foregroundStyle(theme.color(.textPrimary))
                                .lineLimit(1)
                                .fcTypography(.label)
                            Spacer()
                            if let onOpenDocument {
                                Button("Open") {
                                    onOpenDocument()
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(theme.color(.accentInfo))
                                .fcTypography(.caption)
                            }
                        }

                        Divider().overlay(theme.color(.borderSubtle))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(modeLabel)
                                .foregroundStyle(theme.color(.textPrimary))
                                .fcTypography(.label)
                            Text(modeDescription)
                                .foregroundStyle(theme.color(.textSecondary))
                                .fcTypography(.caption)
                        }
                    }
                }

                VStack(spacing: FCSpacingToken.s8.rawValue) {
                    FCQuickActionButton(
                        title: "Draft Script",
                        subtitle: "Record and refine with AI",
                        icon: "mic.badge.plus",
                        accent: .accentCTA,
                        action: onDraft
                    )
                    FCQuickActionButton(
                        title: "Add Page",
                        subtitle: "Append another script page",
                        icon: "plus.square.on.square",
                        accent: .accentPrimary,
                        action: onAddPage
                    )
                    FCQuickActionButton(
                        title: "Open Settings",
                        subtitle: "Tune guidance and teleprompter",
                        icon: "slider.horizontal.3",
                        accent: .accentInfo,
                        action: onSettings
                    )
                }

                FCGlassPanel(includePadding: false) {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                        Text("Getting Started")
                            .foregroundStyle(theme.color(.textPrimary))
                            .fcTypography(.label)
                        Text("Take the guided setup tour to configure permissions and workflow.")
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.caption)
                        Button {
                            onOpenOnboarding()
                        } label: {
                            HStack(spacing: FCSpacingToken.s8.rawValue) {
                                Image(systemName: "sparkles")
                                Text("Open Guided Setup")
                            }
                            .fcTypography(.label)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 34)
                            .background(
                                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
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
                    }
                    .padding(FCSpacingToken.s12.rawValue)
                }
            }
        }
        .frame(width: 280)
    }
}

struct FCRunDock: View {
    let isRunning: Bool
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let tint = isRunning ? theme.color(.stateError) : theme.color(.accentPrimary)

        Button(action: action) {
            HStack(spacing: FCSpacingToken.s8.rawValue) {
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                Text(isRunning ? "Stop" : "Start")
                    .fcTypography(.label)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, FCSpacingToken.s20.rawValue)
            .padding(.vertical, FCSpacingToken.s12.rawValue)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(isHovered ? 0.95 : 0.85), tint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: FCStrokeToken.thin.rawValue)
            )
            .shadow(color: tint.opacity(FCEffectToken.shadowFloat.opacity), radius: FCEffectToken.shadowFloat.blur, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(theme.spring(.snappy), value: isRunning)
        .animation(theme.animation(.fast), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .frame(minHeight: 36)
    }
}

struct FCDropZoneOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(spacing: FCSpacingToken.s12.rawValue) {
            ZStack {
                Circle()
                    .fill(theme.color(.accentInfo).opacity(0.16))
                    .frame(width: 68, height: 68)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(theme.color(.accentInfo))
            }

            VStack(spacing: FCSpacingToken.s4.rawValue) {
                Text("Drop your PowerPoint (.pptx)")
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.heading)
                Text("For Keynote or Google Slides, export to PPTX first.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.bodyM)
            }
        }
        .padding(FCSpacingToken.s32.rawValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: FCShapeToken.radius24.rawValue, style: .continuous)
                .fill(theme.material(.overlay))
                .overlay(
                    RoundedRectangle(cornerRadius: FCShapeToken.radius24.rawValue, style: .continuous)
                        .fill(theme.color(.surfaceOverlay))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: FCShapeToken.radius24.rawValue, style: .continuous)
                .stroke(theme.color(.accentInfo).opacity(pulse ? 1.0 : 0.66), style: StrokeStyle(lineWidth: 2, dash: [9, 7]))
        )
        .shadow(color: theme.color(.accentInfo).opacity(0.20), radius: 28, y: 10)
        .padding(FCSpacingToken.s16.rawValue)
        .onAppear {
            withAnimation(theme.animation(.slow, curve: .standard).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
