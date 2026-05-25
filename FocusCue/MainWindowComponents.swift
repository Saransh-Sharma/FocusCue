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

        theme.color(.canvasBlack)
            .ignoresSafeArea()
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
        let corner = emphasized ? FCShapeToken.radius24.rawValue : FCShapeToken.radius20.rawValue
        let fillToken: FCColorToken = emphasized ? .surfaceRaised : .surfaceSlate
        let panelShape = RoundedRectangle(cornerRadius: corner, style: .continuous)

        Group {
            if includePadding {
                content
                    .padding(FCSpacingToken.s16.rawValue)
            } else {
                content
            }
        }
        .background(theme.color(fillToken), in: panelShape)
        .clipShape(panelShape)
        .overlay(
            panelShape
                .stroke(theme.color(emphasized ? .hazardWhite : .controlBorder), lineWidth: FCStrokeToken.thin.rawValue)
        )
    }
}

struct FCWindowHeader: View {
    let subtitle: String
    @Bindable var entitlements: EntitlementService
    var compact: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                FCBrandIconView(
                    size: 42,
                    cornerRadius: FCShapeToken.radius14.rawValue
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("FocusCue")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.titleMd)
                        .lineLimit(1)
                    if !compact {
                        Text(subtitle)
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.bodyCompact)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }
                .layoutPriority(1)
                Spacer()
                FCInlineEntitlementWidget(
                    entitlements: entitlements
                )
            }
        }
    }
}

struct FCPageRail: View {
    let livePages: [SidebarPageRowModel]
    let archivePages: [SidebarPageRowModel]
    let canAddPages: Bool
    let canDeletePages: Bool
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
                    Text("TIMELINE")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.labelCaps)
                    Spacer()
                    Text("\(livePages.count + archivePages.count)")
                        .foregroundStyle(theme.color(.textTertiary))
                        .fcTypography(.counter)
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
                Text("ADD PAGE")
                    .fcTypography(.monoButton)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, FCSpacingToken.s12.rawValue)
            .padding(.vertical, FCSpacingToken.s8.rawValue)
            .foregroundStyle(theme.color(canAddPages ? .cueMint : .textDisabled))
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius24.rawValue, style: .continuous)
                    .fill(theme.color(.canvasBlack))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius24.rawValue, style: .continuous)
                    .stroke(
                        theme.color(canAddPages ? .cueMint : .controlBorder),
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

        if pages.isEmpty {
            VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                HStack(alignment: .firstTextBaseline, spacing: FCSpacingToken.s8.rawValue) {
                    Text(title.uppercased())
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.labelCaps)
                    Spacer()
                    Text("0")
                        .foregroundStyle(theme.color(.textTertiary))
                        .fcTypography(.counter)
                }

                Text(emptyMessage)
                    .foregroundStyle(theme.color(.textTertiary))
                    .fcTypography(.caption)
            }
            .padding(.leading, FCSpacingToken.s12.rawValue)
            .padding(.trailing, FCSpacingToken.s8.rawValue)
            .padding(.vertical, FCSpacingToken.s8.rawValue)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(theme.color(module == .liveTranscripts ? .violetRule : .frameGray))
                    .frame(width: 1)
            }
        } else {
            VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                HStack(alignment: .firstTextBaseline, spacing: FCSpacingToken.s8.rawValue) {
                    Text(title.uppercased())
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.labelCaps)
                    Spacer()
                    Text("\(pages.count)")
                        .foregroundStyle(theme.color(.textTertiary))
                        .fcTypography(.counter)
                }

                Text(subtitle)
                    .foregroundStyle(theme.color(.textTertiary))
                    .fcTypography(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)

                pageList(pages: pages, module: module)
            }
            .padding(.leading, FCSpacingToken.s12.rawValue)
            .padding(.trailing, FCSpacingToken.s8.rawValue)
            .padding(.vertical, FCSpacingToken.s12.rawValue)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(theme.color(module == .liveTranscripts ? .violetRule : .frameGray))
                    .frame(width: 1)
            }
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
        let shouldFrame = row.isSelected || row.saveFailed || row.isLocked || isHovered
        let background = shouldFrame ? theme.color(row.isLocked ? .surfaceSlate : .canvasBlack) : Color.clear

        VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
            HStack(spacing: FCSpacingToken.s8.rawValue) {
                if isEditing {
                    Text("\(row.localIndex).")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.labelCaps)
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
                                ? theme.color(.textDisabled)
                                : (isHovered ? theme.color(.hoverBlue) : (row.isSelected ? theme.color(.textPrimary) : theme.color(.textSecondary)))
                            )
                            .lineLimit(1)
                            .fcTypography(.label)
                            .onTapGesture(count: 2) {
                                guard row.canRename else { return }
                                onBeginRename()
                            }

                        if row.isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(theme.color(.textDisabled))
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
                        .foregroundStyle(theme.color(.cueMint))
                        .fcTypography(.caption)
                        .padding(.horizontal, FCSpacingToken.s8.rawValue)
                        .padding(.vertical, FCSpacingToken.s4.rawValue)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.color(.canvasBlack))
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
                    .foregroundStyle(row.isLocked ? theme.color(.textDisabled) : theme.color(.textTertiary))
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
                    row.saveFailed
                        ? theme.color(.resyncVioletText)
                        : (row.isSelected ? theme.color(.cueMint) : (shouldFrame ? theme.color(.controlBorder) : .clear)),
                    lineWidth: row.isSelected || row.saveFailed ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
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
                Button("Select Page", action: onSelectLocked)
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
        let accentToken: FCColorToken = isRunning ? .recordingPink : .cueMint
        let accent = theme.color(accentToken)
        let isStartEnabled = isRunning || canStart

        FCGlassPanel {
            VStack(spacing: FCSpacingToken.s16.rawValue) {
                Button {
                    if isRunning { onStop() } else { onStart() }
                } label: {
                    HStack(spacing: FCSpacingToken.s8.rawValue) {
                        Image(systemName: isRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text(isRunning ? "STOP SEQUENCE" : "START LIVE SEQUENCE")
                            .fcTypography(.monoButton)
                    }
                    .foregroundStyle(isStartEnabled ? theme.onAccentForeground(for: accentToken) : theme.color(.textDisabled))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isStartEnabled ? accent.opacity(isStartHovered ? 0.92 : 1.0) : theme.color(.surfaceInset))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                isStartEnabled ? theme.color(isRunning ? .recordingPink : .cueMintBorder) : theme.color(.controlBorder),
                                lineWidth: FCStrokeToken.thin.rawValue
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isStartEnabled)
                .animation(theme.animation(.fast), value: isStartHovered)
                .onHover { isStartHovered = $0 }
                .help(helperText)

                VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                    Text("Listening Mode")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.labelCaps)

                    listeningModePicker(theme: theme)

                    Text(settings.listeningMode.description)
                        .foregroundStyle(theme.color(.textTertiary))
                        .fcTypography(.caption)
                }

                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    FCActionTile(title: "Open", icon: "folder", accent: .hoverBlue, action: onOpenDocument)
                    FCActionTile(title: "Save", icon: "square.and.arrow.down", accent: .cueMint, enabled: hasDirtyPages, action: onSaveAllDirtyPages)
                    FCActionTile(title: "Draft", icon: "mic.badge.plus", accent: .resyncViolet, action: onDraft)
                    FCActionTile(
                        title: "Add Page",
                        icon: "plus.square.on.square",
                        accent: .cueMint,
                        action: onAddPage
                    )
                    FCActionTile(title: "Settings", icon: "slider.horizontal.3", accent: .hoverBlue, action: onSettings)
                    if showOnboardingPrompt {
                        FCActionTile(title: "Setup", icon: "checklist", accent: .teleprompterOrange, action: onOpenOnboarding)
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
                    HStack(spacing: FCSpacingToken.s4.rawValue) {
                        Text(mode.label)
                            .lineLimit(1)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(FCTypographyToken.caption.font)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FCSpacingToken.s8.rawValue)
                    .foregroundStyle(
                        isSelected
                        ? theme.onAccentForeground(for: isLocked ? .controlBorder : .cueMint)
                        : theme.color(isLocked ? .textDisabled : .textSecondary)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                            .fill(
                                isSelected
                                ? theme.color(isLocked ? .controlBorder : .cueMint)
                                : .clear
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FCSpacingToken.s4.rawValue)
        .background(
            RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                .fill(theme.color(.canvasBlack))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                .stroke(theme.color(.controlBorder), lineWidth: FCStrokeToken.thin.rawValue)
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
        let accentToken = enabled ? (accent == .resyncViolet ? FCColorToken.resyncVioletText : accent) : .textDisabled

        Button(action: action) {
            VStack(spacing: FCSpacingToken.s4.rawValue) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color(accentToken))
                Text(title)
                    .fcTypography(.monoButton)
                    .textCase(.uppercase)
                    .foregroundStyle(theme.color(accentToken))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                    .fill(theme.color(.canvasBlack))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                    .stroke(
                        enabled ? theme.color(accentToken).opacity(isHovered ? 1 : 0.72) : theme.color(.controlBorder),
                        lineWidth: FCStrokeToken.thin.rawValue
                    )
            )
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .fcTypography(.caption)
                        .foregroundStyle(theme.color(accentToken))
                        .padding(.horizontal, FCSpacingToken.s4.rawValue)
                        .padding(.vertical, 2)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.color(accentToken).opacity(0.14))
                        )
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .onHover { hovering in
            withAnimation(theme.animation(.fast)) {
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
        let tint = isRunning ? theme.color(.recordingPink) : theme.color(.cueMint)
        let accentToken: FCColorToken = isRunning ? .recordingPink : .cueMint

        Button(action: action) {
            HStack(spacing: FCSpacingToken.s8.rawValue) {
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                Text(isRunning ? "Stop" : "Start")
                    .fcTypography(.label)
            }
            .foregroundStyle(isEnabled ? theme.onAccentForeground(for: accentToken) : theme.color(.textDisabled))
            .padding(.horizontal, FCSpacingToken.s20.rawValue)
            .padding(.vertical, FCSpacingToken.s12.rawValue)
            .background(
                Capsule(style: .continuous)
                    .fill(isEnabled ? tint : theme.color(.surfaceInset))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isEnabled ? theme.color(isRunning ? .recordingPink : .cueMintBorder) : theme.color(.controlBorder), lineWidth: FCStrokeToken.thin.rawValue)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
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
                    .fill(theme.color(.teleprompterOrange).opacity(0.16))
                    .frame(width: 68, height: 68)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(theme.color(.teleprompterOrange))
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
        .background(theme.color(.surfaceInset), in: RoundedRectangle(cornerRadius: FCShapeToken.radius24.rawValue, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FCShapeToken.radius24.rawValue, style: .continuous)
                .stroke(theme.color(.teleprompterOrange).opacity(pulse ? 1.0 : 0.66), style: StrokeStyle(lineWidth: 2, dash: [9, 7]))
        )
        .padding(FCSpacingToken.s16.rawValue)
        .onAppear {
            withAnimation(theme.animation(.slow, curve: .standard).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
