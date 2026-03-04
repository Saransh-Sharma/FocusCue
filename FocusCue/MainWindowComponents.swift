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
        let panelShape = RoundedRectangle(cornerRadius: corner, style: .continuous)

        Group {
            if includePadding {
                content
                    .padding(FCSpacingToken.s16.rawValue)
            } else {
                content
            }
        }
        .background(theme.material(.card), in: panelShape)
        .background(theme.color(fillToken), in: panelShape)
        .clipShape(panelShape)
        .overlay(
            panelShape
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
    let brandState: BrandState
    var compact: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                FCBrandIconView(
                    size: 42,
                    cornerRadius: FCShapeToken.radius14.rawValue,
                    shadowRadius: 14
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("FocusCue")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.titleM)
                        .lineLimit(1)
                    if !compact {
                        Text(subtitle)
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.bodyM)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }
                .layoutPriority(1)
                Spacer()
                FCTierBadge(brandState: brandState)
            }
        }
    }
}

struct FCPageRail: View {
    let livePages: [SidebarPageRowModel]
    let archivePages: [SidebarPageRowModel]
    let canAddPages: Bool
    let canDeletePages: Bool
    let selectedModule: PageModule?
    let onSelectPage: (UUID) -> Void
    let onSelectLockedPage: (UUID) -> Void
    let onRenamePage: (UUID, String) -> Void
    let onSavePage: (UUID) -> Void
    let onDeletePage: (UUID) -> Void
    let onAddLivePage: () -> Void
    let onAddLocked: () -> Void
    let onMovePageUp: (UUID, PageModule) -> Void
    let onMovePageDown: (UUID, PageModule) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editingPageID: UUID?
    @State private var draftTitle = ""

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        FCGlassPanel {
            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                HStack {
                    Text("Pages")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.label)
                    Spacer()
                    Text("\(livePages.count + archivePages.count)")
                        .foregroundStyle(theme.color(.textTertiary))
                        .fcTypography(.mono)
                }

                addPageButton(theme: theme)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                        moduleSection(
                            title: "Live Transcripts",
                            subtitle: "Plays in sequence on Start",
                            emptyMessage: "No live pages yet",
                            module: .liveTranscripts,
                            pages: livePages
                        )

                        moduleSection(
                            title: "Archive",
                            subtitle: "Stored only • not in sequence",
                            emptyMessage: "No archived pages",
                            module: .archive,
                            pages: archivePages
                        )
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contextMenu {
            Button("Add Page", action: canAddPages ? onAddLivePage : onAddLocked)
        }
    }

    @ViewBuilder
    private func addPageButton(theme: FCTheme) -> some View {
        Button(action: canAddPages ? onAddLivePage : onAddLocked) {
            HStack(spacing: FCSpacingToken.s8.rawValue) {
                Image(systemName: canAddPages ? "plus.circle.fill" : "lock.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(canAddPages ? "Add Page" : "Add Page (Pro)")
                    .fcTypography(.label)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, FCSpacingToken.s12.rawValue)
            .padding(.vertical, FCSpacingToken.s8.rawValue)
            .foregroundStyle(theme.color(canAddPages ? .accentPrimary : .stateWarning))
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                    .fill(theme.color(canAddPages ? .accentPrimary : .stateWarning).opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                    .stroke(
                        theme.color(canAddPages ? .accentPrimary : .stateWarning).opacity(0.24),
                        lineWidth: FCStrokeToken.thin.rawValue
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func moduleSection(
        title: String,
        subtitle: String,
        emptyMessage: String,
        module: PageModule,
        pages: [SidebarPageRowModel]
    ) -> some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let isSelectedModule = selectedModule == module

        if pages.isEmpty {
            VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                HStack(alignment: .firstTextBaseline, spacing: FCSpacingToken.s8.rawValue) {
                    Text(title)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.label)
                    Spacer()
                    Text("0")
                        .foregroundStyle(theme.color(.textTertiary))
                        .fcTypography(.mono)
                }

                Text(emptyMessage)
                    .foregroundStyle(theme.color(.textTertiary))
                    .fcTypography(.caption)
            }
            .padding(.horizontal, FCSpacingToken.s8.rawValue)
            .padding(.vertical, FCSpacingToken.s4.rawValue)
        } else {
            VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                HStack(alignment: .firstTextBaseline, spacing: FCSpacingToken.s8.rawValue) {
                    Text(title)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.label)
                    Spacer()
                    Text("\(pages.count)")
                        .foregroundStyle(theme.color(.textTertiary))
                        .fcTypography(.mono)
                }

                Text(subtitle)
                    .foregroundStyle(theme.color(.textTertiary))
                    .fcTypography(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)

                pageList(pages: pages, module: module)
            }
            .padding(.horizontal, FCSpacingToken.s12.rawValue)
            .padding(.vertical, FCSpacingToken.s12.rawValue)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .fill(theme.color(.surfaceGlassStrong).opacity(isSelectedModule ? 0.64 : 0.52))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .stroke(
                        isSelectedModule ? theme.color(.borderFocus) : theme.color(.borderSubtle),
                        lineWidth: isSelectedModule ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
                    )
            )
        }
    }

    private func pageList(pages: [SidebarPageRowModel], module: PageModule) -> some View {
        VStack(spacing: FCSpacingToken.s8.rawValue) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { pageIndex, page in
                FCSidebarPageRow(
                    row: page,
                    canDelete: canDeletePages,
                    isEditing: editingPageID == page.id,
                    draftTitle: $draftTitle,
                    onSelect: { onSelectPage(page.id) },
                    onSelectLocked: { onSelectLockedPage(page.id) },
                    onBeginRename: {
                        editingPageID = page.id
                        draftTitle = page.baseTitle
                    },
                    onCommitRename: {
                        editingPageID = nil
                        onRenamePage(page.id, draftTitle)
                    },
                    onCancelRename: {
                        editingPageID = nil
                    },
                    onSave: { onSavePage(page.id) },
                    onDelete: { onDeletePage(page.id) },
                    onMoveUp: { onMovePageUp(page.id, module) },
                    onMoveDown: { onMovePageDown(page.id, module) },
                    canMoveUp: pageIndex > 0,
                    canMoveDown: pageIndex < pages.count - 1
                )
            }
        }
    }

}

private struct FCSidebarPageRow: View {
    let row: SidebarPageRowModel
    let canDelete: Bool
    let isEditing: Bool
    @Binding var draftTitle: String
    let onSelect: () -> Void
    let onSelectLocked: () -> Void
    let onBeginRename: () -> Void
    let onCommitRename: () -> Void
    let onCancelRename: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let canMoveUp: Bool
    let canMoveDown: Bool

    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let background = row.isLocked
            ? theme.color(.stateWarning).opacity(row.isSelected ? 0.14 : 0.08)
            : row.isSelected
            ? theme.color(.accentInfo).opacity(0.24)
            : (isHovered ? theme.color(.surfaceGlassStrong).opacity(0.72) : theme.color(.surfaceGlass).opacity(0.45))

        VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
            HStack(spacing: FCSpacingToken.s8.rawValue) {
                if isEditing {
                    Text("\(row.localIndex).")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.label)
                    TextField("Page title", text: $draftTitle)
                        .textFieldStyle(.plain)
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.label)
                        .onSubmit(onCommitRename)
                        .onExitCommand(perform: onCancelRename)
                } else {
                    HStack(spacing: FCSpacingToken.s4.rawValue) {
                        Text("\(row.localIndex). \(row.baseTitle)")
                            .foregroundStyle(
                                row.isLocked
                                ? theme.color(.textTertiary)
                                : (row.isSelected ? theme.color(.textPrimary) : theme.color(.textSecondary))
                            )
                            .lineLimit(1)
                            .fcTypography(.label)
                            .onTapGesture(count: 2) {
                                guard row.canRename else { return }
                                onBeginRename()
                            }

                        if row.isLiteActive {
                            tag(theme: theme, title: "Lite Active", color: .accentInfo)
                        } else if row.isLocked {
                            tag(theme: theme, title: "Pro", color: .stateWarning)
                        } else if row.needsSave || row.saveFailed {
                            Circle()
                                .fill(theme.color(.stateWarning))
                                .frame(width: 6, height: 6)
                        }
                    }
                }

                Spacer(minLength: 0)
                if row.canSave && (row.needsSave || row.saveFailed) && !isEditing && (isHovered || row.isSelected) {
                    Button("Save", action: onSave)
                        .buttonStyle(.plain)
                        .foregroundStyle(theme.color(.accentInfo))
                        .fcTypography(.caption)
                        .padding(.horizontal, FCSpacingToken.s8.rawValue)
                        .padding(.vertical, FCSpacingToken.s4.rawValue)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.color(.accentInfo).opacity(0.16))
                        )
                }
                if row.isRead && !row.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.color(.stateSuccess))
                }
            }

            if !row.preview.isEmpty {
                Text(row.preview)
                    .foregroundStyle(row.isLocked ? theme.color(.textTertiary).opacity(0.8) : theme.color(.textTertiary))
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
                    row.isSelected ? theme.color(.borderFocus) : .clear,
                    lineWidth: row.isSelected ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous))
        .onTapGesture {
            if !isEditing {
                if row.isLocked {
                    onSelectLocked()
                } else {
                    onSelect()
                }
            }
        }
        .onHover { hovering in
            withAnimation(theme.animation(.fast)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            if row.isLocked {
                Button("Use This Page in Lite", action: onSelectLocked)
            } else {
                if row.canSave && (row.needsSave || row.saveFailed) {
                    Button("Save", action: onSave)
                }
                if row.canRename {
                    Button("Rename", action: onBeginRename)
                }
                if row.canMove {
                    Button("Move Up", action: onMoveUp)
                        .disabled(!canMoveUp)
                    Button("Move Down", action: onMoveDown)
                        .disabled(!canMoveDown)
                }
                if row.canDelete && canDelete {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Page", systemImage: "trash")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tag(theme: FCTheme, title: String, color: FCColorToken) -> some View {
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
}

struct FCActionBar: View {
    let isRunning: Bool
    let startAvailabilityReason: FocusCueService.StartAvailabilityReason
    let accessTier: AccessTier
    @Bindable var settings: NotchSettings
    let hasDirtyPages: Bool
    let showOnboardingPrompt: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onOpenDocument: () -> Void
    let onSaveAllDirtyPages: () -> Void
    let onDraft: () -> Void
    let onAddPage: () -> Void
    let onSettings: () -> Void
    let onOpenOnboarding: () -> Void
    let onBlockedFeature: (FeatureGate) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var entitlements = EntitlementService.shared
    @State private var isStartHovered = false

    private var canStart: Bool {
        !isRunning && startAvailabilityReason == .ready
    }

    private var helperText: String {
        if isRunning {
            return "Live sequence is running. Stop playback to return to editing."
        }
        switch startAvailabilityReason {
        case .ready:
            if accessTier == .lite {
                return "Starts from the active Lite page only. Upgrade to play full multi-page sequences."
            }
            return "Starts from the selected live page and continues through remaining pages."
        case .noSelection:
            return "Select a page in Live Transcripts to enable Start."
        case .selectedPageInArchive:
            return "Archive pages do not play. Move this page to Live Transcripts."
        case .selectedLivePageEmpty:
            return "Add script text to this live transcript page to enable Start."
        case .noNonEmptyLivePages:
            return "Add script to a live transcript page to start."
        }
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let accent = isRunning ? theme.color(.stateError) : theme.color(.accentPrimary)

        FCGlassPanel {
            VStack(spacing: FCSpacingToken.s16.rawValue) {
                Button {
                    if isRunning { onStop() } else { onStart() }
                } label: {
                    HStack(spacing: FCSpacingToken.s8.rawValue) {
                        Image(systemName: isRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text(isRunning ? "Stop Sequence" : "Start Live Sequence")
                            .fcTypography(.heading)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accent.opacity(isStartHovered ? 0.95 : 0.85),
                                        isRunning ? theme.color(.stateError) : theme.color(.accentInfo)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: FCStrokeToken.thin.rawValue)
                    )
                    .shadow(color: accent.opacity(FCEffectToken.shadowFloat.opacity), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(!(isRunning || canStart))
                .opacity((isRunning || canStart) ? 1 : 0.45)
                .animation(theme.animation(.fast), value: isStartHovered)
                .onHover { isStartHovered = $0 }
                .help(helperText)

                VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                    Text("Listening Mode")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.label)

                    listeningModePicker(theme: theme)

                    Text(settings.listeningMode.description)
                        .foregroundStyle(theme.color(.textTertiary))
                        .fcTypography(.caption)
                }

                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    FCActionTile(title: "Open", icon: "folder", accent: .accentInfo, action: onOpenDocument)
                    FCActionTile(title: "Save", icon: "square.and.arrow.down", accent: .accentInfo, enabled: hasDirtyPages, action: onSaveAllDirtyPages)
                    FCActionTile(title: "Draft", icon: "mic.badge.plus", accent: .accentCTA, action: onDraft)
                    FCActionTile(
                        title: "Add Page",
                        icon: accessTier == .lite ? "lock.fill" : "plus.square.on.square",
                        accent: accessTier == .lite ? .stateWarning : .accentPrimary,
                        badge: accessTier == .lite ? "Pro" : nil,
                        action: onAddPage
                    )
                    FCActionTile(title: "Settings", icon: "slider.horizontal.3", accent: .accentInfo, action: onSettings)
                    if showOnboardingPrompt {
                        FCActionTile(title: "Setup", icon: "sparkles", accent: .accentCTA, action: onOpenOnboarding)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func listeningModePicker(theme: FCTheme) -> some View {
        let allowedModes = Set(entitlements.availableListeningModes(current: settings.listeningMode))

        HStack(spacing: 0) {
            ForEach(ListeningMode.allCases) { mode in
                let isSelected = settings.listeningMode == mode
                let isLocked = !allowedModes.contains(mode)

                Button {
                    if isLocked {
                        onBlockedFeature(.wordTracking)
                    } else {
                        settings.listeningMode = mode
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(mode.label)
                            .lineLimit(1)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(
                        isSelected
                        ? Color.white
                        : theme.color(isLocked ? .stateWarning : .textSecondary)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                            .fill(
                                isSelected
                                ? theme.color(isLocked ? .stateWarning : .accentInfo)
                                : .clear
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                .fill(theme.color(.surfaceGlassStrong).opacity(0.7))
        )
    }
}

private struct FCActionTile: View {
    let title: String
    let icon: String
    let accent: FCColorToken
    var enabled: Bool = true
    var badge: String?
    let action: () -> Void

    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        Button(action: action) {
            VStack(spacing: FCSpacingToken.s4.rawValue) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color(accent))
                Text(title)
                    .fcTypography(.caption)
                    .foregroundStyle(theme.color(accent))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                    .fill(theme.color(accent).opacity(isHovered ? 0.24 : 0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                    .stroke(theme.color(accent).opacity(isHovered ? 0.32 : 0), lineWidth: FCStrokeToken.thin.rawValue)
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .fcTypography(.caption)
                        .foregroundStyle(theme.color(accent))
                        .padding(.horizontal, FCSpacingToken.s4.rawValue)
                        .padding(.vertical, 2)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.color(accent).opacity(0.14))
                        )
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .help(title)
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
