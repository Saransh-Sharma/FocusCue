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
    var compact: Bool = false

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
                        .lineLimit(1)
                    if !compact {
                        Text(subtitle)
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.bodyM)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .layoutPriority(1)
                Spacer()
            }
        }
    }
}

struct FCPageRail: View {
    let livePages: [SidebarPageRowModel]
    let archivePages: [SidebarPageRowModel]
    let canDeletePages: Bool
    let selectedModule: PageModule?
    let onSelectPage: (UUID) -> Void
    let onRenamePage: (UUID, String) -> Void
    let onSavePage: (UUID) -> Void
    let onDeletePage: (UUID) -> Void
    let onAddLivePage: () -> Void
    let onReorderPage: (UUID, PageModule, Int) -> Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editingPageID: UUID?
    @State private var draftTitle = ""

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let railActionDockHeight: CGFloat = 82

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

                ZStack(alignment: .bottom) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                            moduleSection(
                                title: "Live Transcripts",
                                subtitle: "Plays in sequence on Start",
                                module: .liveTranscripts,
                                pages: livePages
                            )

                            moduleSection(
                                title: "Archive",
                                subtitle: "Stored only • not in sequence",
                                module: .archive,
                                pages: archivePages
                            )
                        }
                        .padding(.bottom, railActionDockHeight + FCSpacingToken.s8.rawValue)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    railActionDock(height: railActionDockHeight)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .contextMenu {
            Button("Add Page", action: onAddLivePage)
        }
    }

    @ViewBuilder
    private func moduleSection(
        title: String,
        subtitle: String,
        module: PageModule,
        pages: [SidebarPageRowModel]
    ) -> some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let isSelectedModule = selectedModule == module

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

    private func pageList(pages: [SidebarPageRowModel], module: PageModule) -> some View {
        VStack(spacing: FCSpacingToken.s8.rawValue) {
            if pages.isEmpty {
                FCPageAppendDropZone(
                    message: module == .liveTranscripts
                        ? "No live transcript pages yet"
                        : "Archived pages will appear here",
                    onDropPayload: { payload in
                        guard payload.kind == .page, payload.sourceModule == module else { return false }
                        return onReorderPage(payload.id, module, 0)
                    },
                    minHeight: 40
                )
            } else {
                ForEach(Array(pages.enumerated()), id: \.element.id) { pageIndex, page in
                    FCSidebarPageRow(
                        row: page,
                        canDelete: canDeletePages,
                        isEditing: editingPageID == page.id,
                        draftTitle: $draftTitle,
                        onSelect: { onSelectPage(page.id) },
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
                        onDropPayload: { payload, edge in
                            guard payload.kind == .page, payload.sourceModule == module else { return false }
                            let targetIndex = edge == .before ? pageIndex : (pageIndex + 1)
                            return onReorderPage(payload.id, module, targetIndex)
                        }
                    )
                }

                FCPageAppendDropZone(
                    message: "Drop page to move to end",
                    onDropPayload: { payload in
                        guard payload.kind == .page, payload.sourceModule == module else { return false }
                        return onReorderPage(payload.id, module, pages.count)
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func railActionDock(height: CGFloat) -> some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    theme.color(.surfaceGlass).opacity(0),
                    theme.color(.surfaceGlass).opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 14)
            .allowsHitTesting(false)

            railActionButton(
                title: "Add Page",
                icon: "plus.circle.fill",
                tint: .accentPrimary,
                action: onAddLivePage
            )
            .padding(.horizontal, FCSpacingToken.s4.rawValue)
            .padding(.top, FCSpacingToken.s4.rawValue)
            .padding(.bottom, FCSpacingToken.s4.rawValue)
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .fill(theme.color(.surfaceGlassStrong).opacity(0.84))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                    .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
            )
        }
        .padding(.horizontal, FCSpacingToken.s8.rawValue)
        .padding(.bottom, FCSpacingToken.s4.rawValue)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .bottom)
    }

    @ViewBuilder
    private func railActionButton(title: String, icon: String, tint: FCColorToken, action: @escaping () -> Void) -> some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        Button(action: action) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(title)
                        .fcTypography(.label)
                }
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text("Add")
                        .fcTypography(.label)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, FCSpacingToken.s12.rawValue)
            .padding(.vertical, FCSpacingToken.s8.rawValue)
            .foregroundStyle(theme.color(tint))
            .background(
                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                    .fill(theme.color(tint).opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}

private enum FCPageDropEdge {
    case before
    case after
}

private struct FCPageAppendDropZone: View {
    let message: String?
    let onDropPayload: (SidebarDragPayload) -> Bool
    var minHeight: CGFloat = 18

    @State private var isTargeted = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        VStack(spacing: FCSpacingToken.s4.rawValue) {
            RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                .fill(theme.color(.accentInfo).opacity(isTargeted ? 0.18 : 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                        .stroke(
                            isTargeted ? theme.color(.borderFocus) : theme.color(.borderSubtle).opacity(0.3),
                            lineWidth: isTargeted ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
                        )
                )
                .frame(minHeight: minHeight)

            if let message {
                Text(message)
                    .foregroundStyle(theme.color(.textTertiary))
                    .fcTypography(.caption)
            }
        }
        .dropDestination(for: SidebarDragPayload.self) { payloads, _ in
            guard let payload = payloads.first else { return false }
            return onDropPayload(payload)
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }
}

private struct FCSidebarPageRow: View {
    let row: SidebarPageRowModel
    let canDelete: Bool
    let isEditing: Bool
    @Binding var draftTitle: String
    let onSelect: () -> Void
    let onBeginRename: () -> Void
    let onCommitRename: () -> Void
    let onCancelRename: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void
    let onDropPayload: ((SidebarDragPayload, FCPageDropEdge) -> Bool)?

    @State private var isHovered = false
    @State private var rowHeight: CGFloat = 0
    @State private var isDropTargeted = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let background = row.isSelected
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
                            .foregroundStyle(row.isSelected ? theme.color(.textPrimary) : theme.color(.textSecondary))
                            .lineLimit(1)
                            .fcTypography(.label)
                            .onTapGesture(count: 2, perform: onBeginRename)

                        if row.needsSave || row.saveFailed {
                            Circle()
                                .fill(theme.color(.stateWarning))
                                .frame(width: 6, height: 6)
                        }
                    }
                }

                Spacer(minLength: 0)
                if (row.needsSave || row.saveFailed) && !isEditing && (isHovered || row.isSelected) {
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
                    row.isSelected ? theme.color(.borderFocus) : .clear,
                    lineWidth: row.isSelected ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous))
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { rowHeight = proxy.size.height }
                    .onChange(of: proxy.size.height) { _, newValue in
                        rowHeight = newValue
                    }
            }
        )
        .overlay(alignment: .top) {
            if isDropTargeted {
                Capsule(style: .continuous)
                    .fill(theme.color(.borderFocus))
                    .frame(height: 2)
                    .padding(.horizontal, 4)
            }
        }
        .onTapGesture {
            if !isEditing {
                onSelect()
            }
        }
        .onHover { hovering in
            withAnimation(theme.animation(.fast)) {
                isHovered = hovering
            }
        }
        .draggable(SidebarDragPayload.page(row.id, sourceModule: row.module))
        .dropDestination(for: SidebarDragPayload.self) { payloads, location in
            guard let onDropPayload, let payload = payloads.first else { return false }
            let midpoint = max(rowHeight, 1) / 2
            let edge: FCPageDropEdge = location.y <= midpoint ? .before : .after
            return onDropPayload(payload, edge)
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .contextMenu {
            if row.needsSave || row.saveFailed {
                Button("Save", action: onSave)
            }
            Button("Rename", action: onBeginRename)
            if canDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Page", systemImage: "trash")
                }
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
    let isEnabled: Bool

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
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .onHover { hovering in
            withAnimation(theme.animation(.fast)) {
                isHovered = hovering
            }
        }
    }
}

struct FCPlaybackHeroPanel: View {
    let isRunning: Bool
    let startAvailabilityReason: FocusCueService.StartAvailabilityReason
    let selectedPageTitle: String?
    let selectedPageModule: PageModule?
    let livePlayablePageCount: Int
    let remainingPlayableCountFromSelection: Int?
    let modeLabel: String
    let modeDescription: String
    let onStart: () -> Void
    let onStop: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    private var helperText: String {
        if isRunning {
            return "Live sequence is running. Stop playback to return to editing."
        }
        switch startAvailabilityReason {
        case .ready:
            return "Starts from the selected live page and continues through remaining non-empty live transcript pages."
        case .noSelection:
            return "Select a page in Live Transcripts to enable Start."
        case .selectedPageInArchive:
            return "Archive pages do not play. Move this page to Live Transcripts to start."
        case .selectedLivePageEmpty:
            return "Add script text to this live transcript page to enable Start."
        case .noNonEmptyLivePages:
            return "Add script to a live transcript page to start a sequence."
        }
    }

    private var canStart: Bool {
        !isRunning && startAvailabilityReason == .ready
    }

    private var primaryLabel: String {
        isRunning ? "Stop" : "Start Live Sequence"
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let accent = isRunning ? theme.color(.stateError) : theme.color(.accentPrimary)

        FCGlassPanel(emphasized: true) {
            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                    Text("Start Live Sequence")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.heading)
                    Text("Only pages in Live Transcripts play in order when Start is pressed.")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.caption)
                }

                Button {
                    if isRunning {
                        onStop()
                    } else {
                        onStart()
                    }
                } label: {
                    HStack(spacing: FCSpacingToken.s8.rawValue) {
                        Image(systemName: isRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text(primaryLabel)
                            .fcTypography(.label)
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, FCSpacingToken.s12.rawValue)
                    .frame(minHeight: 46)
                    .background(
                        RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accent.opacity(isHovered ? 0.95 : 0.85),
                                        isRunning ? theme.color(.stateError) : theme.color(.accentInfo)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: FCStrokeToken.thin.rawValue)
                    )
                    .shadow(color: accent.opacity(FCEffectToken.shadowFloat.opacity), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(!(isRunning || canStart))
                .opacity((isRunning || canStart) ? 1 : 0.45)
                .scaleEffect(isHovered ? 1.01 : 1)
                .animation(theme.animation(.fast), value: isHovered)
                .onHover { isHovered = $0 }

                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Image(systemName: isRunning ? "dot.radiowaves.left.and.right" : "info.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isRunning ? theme.color(.stateSuccess) : theme.color(.textTertiary))
                    Text(helperText)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.caption)
                }

                VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                    metadataRow(
                        label: "Selected",
                        value: selectedPageTitle ?? "None"
                    )
                    metadataRow(
                        label: "Module",
                        value: {
                            switch selectedPageModule {
                            case .liveTranscripts?: return "Live Transcripts"
                            case .archive?: return "Archive"
                            case nil: return "None"
                            }
                        }()
                    )
                    metadataRow(
                        label: "Playable Live Pages",
                        value: "\(livePlayablePageCount)"
                    )
                    if let remainingPlayableCountFromSelection {
                        metadataRow(
                            label: "Remaining in Sequence",
                            value: "\(remainingPlayableCountFromSelection)"
                        )
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
    }

    @ViewBuilder
    private func metadataRow(label: String, value: String) -> some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        HStack(spacing: FCSpacingToken.s8.rawValue) {
            Text(label)
                .foregroundStyle(theme.color(.textTertiary))
                .fcTypography(.caption)
            Spacer()
            Text(value)
                .foregroundStyle(theme.color(.textSecondary))
                .lineLimit(1)
                .fcTypography(.caption)
        }
    }
}

struct FCCommandCenter: View {
    let fileName: String?
    let hasUnsavedChanges: Bool
    let hasDirtyPages: Bool
    let modeLabel: String
    let modeDescription: String
    let onOpenDocument: (() -> Void)?
    let onSaveAllDirtyPages: () -> Void
    let onDraft: () -> Void
    let onAddPage: () -> Void
    let onSettings: () -> Void
    let onOpenOnboarding: () -> Void
    let showOnboardingPrompt: Bool

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

                VStack(spacing: FCSpacingToken.s8.rawValue) {
                    if let onOpenDocument {
                        FCQuickActionButton(
                            title: "Open Script File",
                            subtitle: fileName ?? "Open a .focuscue file or import notes",
                            icon: "folder",
                            accent: .accentInfo,
                            action: onOpenDocument,
                            isEnabled: true
                        )
                    }
                    FCQuickActionButton(
                        title: "Save All Changes",
                        subtitle: "Persist pending edits to draft files",
                        icon: "square.and.arrow.down.on.square",
                        accent: .accentInfo,
                        action: onSaveAllDirtyPages,
                        isEnabled: hasDirtyPages
                    )
                    FCQuickActionButton(
                        title: "Draft Script",
                        subtitle: "Record and refine with AI",
                        icon: "mic.badge.plus",
                        accent: .accentCTA,
                        action: onDraft,
                        isEnabled: true
                    )
                    FCQuickActionButton(
                        title: "New Live Transcript Page",
                        subtitle: "Add a page to the playable live sequence",
                        icon: "plus.square.on.square",
                        accent: .accentPrimary,
                        action: onAddPage,
                        isEnabled: true
                    )
                    FCQuickActionButton(
                        title: "Open Settings",
                        subtitle: "Tune guidance and teleprompter",
                        icon: "slider.horizontal.3",
                        accent: .accentInfo,
                        action: onSettings,
                        isEnabled: true
                    )
                }

                VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                    HStack(spacing: FCSpacingToken.s8.rawValue) {
                        Circle()
                            .fill(hasUnsavedChanges ? theme.color(.stateWarning) : theme.color(.stateSuccess))
                            .frame(width: 7, height: 7)
                        Text(fileName ?? "Untitled Script")
                            .foregroundStyle(theme.color(.textSecondary))
                            .lineLimit(1)
                            .fcTypography(.caption)
                        Spacer()
                    }
                    Text(modeLabel)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.caption)
                    Text(modeDescription)
                        .foregroundStyle(theme.color(.textTertiary))
                        .fcTypography(.caption)
                }

                if showOnboardingPrompt {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
