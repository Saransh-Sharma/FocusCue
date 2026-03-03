//
//  ContentView.swift
//  FocusCue
//
//  Created by Fatih Kadir Akın on 8.02.2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var service = FocusCueService.shared
    @State private var isRunning = false
    @State private var isDroppingPresentation = false
    @State private var dropError: String?
    @State private var dropAlertTitle = "Import Error"
    @State private var showSettings = false
    @State private var settingsInitialTab: SettingsTab = .display
    @State private var settingsLaunchedFromOnboarding = false
    @State private var settingsGuidedTemplateDraft: OnboardingDraft?
    @State private var showAbout = false
    @State private var showDraft = false
    @State private var showOnboarding = false
    @State private var onboardingInitialStep: OnboardingStep = .welcome
    @State private var onboardingEntryContext: OnboardingEntryContext = .firstRun
    @State private var revealMainWindow = false
    @State private var showDeletePageConfirmation = false
    @State private var pendingDeletePageID: UUID?

    @AppStorage(FocusCueOnboardingStorage.completedKey) private var onboardingCompleted = false
    @AppStorage(FocusCueOnboardingStorage.versionKey) private var onboardingVersion = 0
    @AppStorage(FocusCueOnboardingStorage.lastCompletedStepKey) private var onboardingLastCompletedStep = 0

    @FocusState private var isTextFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let defaultText = """
Read this out loud to try FocusCue. [smile]

Welcome to FocusCue — your personal teleprompter that lives just below your MacBook’s notch.

As you speak, your script highlights in real time while FocusCue follows your voice. Speech recognition matches your words and keeps you in sync. [pause]

Need to stop or redo a line? Pause anytime, jump back, and the highlighting will catch up automatically. When you reach the end, the overlay closes smoothly on its own. [nod]

Watch the waveform track your voice, and glance at the last few words you spoke beside it.

Happy presenting! [wave]
"""

    private var currentText: Binding<String> {
        service.textBindingForSelectedPage()
    }

    private var liveSidebarRows: [SidebarPageRowModel] {
        service.sidebarSections.first(where: { $0.kind == .liveTranscripts })?.pages ?? []
    }

    private var archiveSidebarRows: [SidebarPageRowModel] {
        service.sidebarSections.first(where: { $0.kind == .archive })?.pages ?? []
    }

    private var shouldPresentOnboardingOnLaunch: Bool {
        !onboardingCompleted || onboardingVersion < FocusCueOnboardingStorage.currentVersion
    }

    private var resolvedLaunchOnboardingStep: OnboardingStep {
        if !onboardingCompleted,
           let savedStep = OnboardingStep(rawValue: onboardingLastCompletedStep) {
            return savedStep
        }
        return .welcome
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        GeometryReader { proxy in
            let isCompactLayout = proxy.size.width < 960
            let contentPadding = FCSpacingToken.s16.rawValue
            let mainStackSpacing = FCSpacingToken.s12.rawValue
            let columnSpacing = FCSpacingToken.s12.rawValue
            let sidebarWidth: CGFloat = 220
            let editorMinHeight: CGFloat = 380

            ZStack {
                FCWindowBackdrop()

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: mainStackSpacing) {
                        FCWindowHeader(
                            subtitle: "Stay on script. Stay on camera. Stay natural.",
                            compact: isCompactLayout
                        )

                        if isCompactLayout {
                            VStack(alignment: .leading, spacing: mainStackSpacing) {
                                pageRailView(theme: theme, width: sidebarWidth)
                                editorPanel(theme: theme, minHeight: editorMinHeight)
                                actionBarView(theme: theme)
                            }
                        } else {
                            HStack(alignment: .top, spacing: columnSpacing) {
                                pageRailView(theme: theme, width: sidebarWidth)

                                VStack(spacing: mainStackSpacing) {
                                    editorPanel(theme: theme, minHeight: editorMinHeight)
                                    actionBarView(theme: theme)
                                }
                            }
                        }
                    }
                    .padding(contentPadding)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
                .opacity(revealMainWindow ? 1 : 0)
                .offset(y: revealMainWindow ? 0 : (reduceMotion ? 0 : 12))
                .animation(theme.animation(.emphasized, curve: .enter), value: revealMainWindow)

                if isDroppingPresentation {
                    FCDropZoneOverlay()
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97)))
                }

                Color.clear
                    .contentShape(Rectangle())
                    .onDrop(of: [.fileURL], isTargeted: $isDroppingPresentation) { providers in
                    guard let provider = providers.first else { return false }
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        guard let url else { return }
                        let ext = url.pathExtension.lowercased()
                        if ext == "key" {
                            DispatchQueue.main.async {
                                dropAlertTitle = "Conversion Required"
                                dropError = "Keynote files can't be imported directly. Please export your Keynote presentation as PowerPoint (.pptx) first, then drop the exported file here."
                            }
                            return
                        }
                        guard ext == "pptx" else {
                            DispatchQueue.main.async {
                                dropAlertTitle = "Import Error"
                                dropError = "Unsupported file. Drop a PowerPoint (.pptx) file."
                            }
                            return
                        }
                        DispatchQueue.main.async {
                            handlePresentationDrop(url: url)
                        }
                    }
                    return true
                }
                    .allowsHitTesting(isDroppingPresentation)
            }
        }
        .alert(dropAlertTitle, isPresented: Binding(get: { dropError != nil }, set: { if !$0 { dropError = nil } })) {
            Button("OK") { dropError = nil }
        } message: {
            Text(dropError ?? "")
        }
        .confirmationDialog(
            "Delete this page?",
            isPresented: $showDeletePageConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Page", role: .destructive) {
                guard let pageID = pendingDeletePageID else { return }
                withAnimation(theme.spring(.snappy)) {
                    service.deletePage(pageID)
                }
                pendingDeletePageID = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeletePageID = nil
            }
        } message: {
            if let pageID = pendingDeletePageID {
                let title = service.pageTitle(for: pageID)
                Text("Delete \"\(title)\" permanently? This removes the page from FocusCue. If a draft file exists, it will be moved to Trash.")
            }
        }
        .frame(minWidth: 920, minHeight: 540)
        .sheet(isPresented: $showDraft) {
            DraftSessionView { script in
                let trimmed = script.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                service.replaceWorkspaceWithSinglePage(text: trimmed, markAsSaved: true)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                settings: NotchSettings.shared,
                initialTab: settingsInitialTab,
                launchedFromOnboarding: settingsLaunchedFromOnboarding,
                onReturnToGuidedTemplate: settingsGuidedTemplateDraft != nil ? {
                    returnToGuidedTemplateFromSettings()
                } : nil
            )
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingWizardView(
                initialStep: onboardingInitialStep,
                entryContext: onboardingEntryContext
            ) { completion in
                handleOnboardingCompletion(completion)
            }
            .frame(width: 640, height: 540)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            presentSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAbout)) { _ in
            showAbout = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openOnboarding)) { _ in
            settingsGuidedTemplateDraft = nil
            onboardingInitialStep = .welcome
            onboardingEntryContext = .manual
            showOnboarding = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            isRunning = service.overlayController.isShowing
        }
        .onAppear {
            if !service.restoredWorkspaceFromAutosave && service.totalPageCount == 1 && service.currentPageText.isEmpty {
                service.setTextForSelectedPage(defaultText)
            }

            if service.overlayController.isShowing {
                isRunning = true
            }

            if FocusCueService.shared.launchedExternally {
                DispatchQueue.main.async {
                    for window in NSApp.windows where !(window is NSPanel) {
                        window.orderOut(nil)
                    }
                }
            } else {
                isTextFocused = true
                if shouldPresentOnboardingOnLaunch {
                    onboardingInitialStep = resolvedLaunchOnboardingStep
                    onboardingEntryContext = .firstRun
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showOnboarding = true
                    }
                }
            }

            revealMainWindow = true
        }
    }

    // MARK: - Main Window Subviews

    @ViewBuilder
    private func pageRailView(theme: FCTheme, width: CGFloat) -> some View {
        FCPageRail(
            livePages: liveSidebarRows,
            archivePages: archiveSidebarRows,
            canDeletePages: service.canDeletePages,
            selectedModule: service.selectedPageModule,
            onSelectPage: { pageID in
                withAnimation(theme.spring(.snappy)) {
                    service.selectPage(pageID)
                }
            },
            onRenamePage: { pageID, title in
                service.renamePage(pageID, to: title)
            },
            onSavePage: { pageID in
                _ = service.savePageDraft(pageID)
            },
            onDeletePage: { pageID in
                withAnimation(theme.spring(.snappy)) {
                    service.deletePage(pageID)
                }
            },
            onAddLivePage: { addPage() },
            onMovePageUp: { pageID, module in
                movePageUp(pageID, module: module, theme: theme)
            },
            onMovePageDown: { pageID, module in
                movePageDown(pageID, module: module, theme: theme)
            }
        )
        .frame(width: width)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func editorPanel(theme: FCTheme, minHeight: CGFloat) -> some View {
        FCGlassPanel {
            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Text("Script Editor")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.heading)
                        .lineLimit(1)
                        .layoutPriority(1)

                    Spacer(minLength: FCSpacingToken.s8.rawValue)

                    editorToolbarActions(theme: theme)
                }

                TextEditor(text: currentText)
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.bodyL)
                    .scrollContentBackground(.hidden)
                    .padding(FCSpacingToken.s12.rawValue)
                    .background(
                        RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                            .fill(theme.color(.surfaceGlassStrong).opacity(0.84))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                            .stroke(
                                isTextFocused ? theme.color(.borderFocus) : theme.color(.borderSubtle),
                                lineWidth: isTextFocused ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
                            )
                    )
                    .focused($isTextFocused)
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
    }

    @ViewBuilder
    private func editorToolbarActions(theme: FCTheme) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: FCSpacingToken.s12.rawValue) {
                editorSaveButton(theme: theme)
                editorMovePageButton(theme: theme)
                editorDeletePageButton(theme: theme)
            }

            HStack(spacing: FCSpacingToken.s8.rawValue) {
                if service.hasDirtyDraftPages {
                    editorSaveButton(theme: theme)
                }
                if service.selectedPageID != nil {
                    editorPageActionsMenuButton(theme: theme, includeSaveAction: false)
                }
            }

            HStack(spacing: FCSpacingToken.s8.rawValue) {
                if service.selectedPageID != nil {
                    editorPageActionsMenuButton(theme: theme, includeSaveAction: true)
                } else if service.hasDirtyDraftPages {
                    editorSaveButton(theme: theme)
                }
            }
        }
    }

    @ViewBuilder
    private func editorSaveButton(theme: FCTheme) -> some View {
        if service.hasDirtyDraftPages {
            Button {
                saveSelectedOrAllDirtyPages()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
                    .fcTypography(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.color(.accentInfo))
        }
    }

    @ViewBuilder
    private func editorMovePageButton(theme: FCTheme) -> some View {
        if let selectedPageID = service.selectedPageID,
           let selectedModule = service.selectedPageModule {
            if selectedModule == .liveTranscripts {
                Button {
                    withAnimation(theme.spring(.snappy)) {
                        service.movePageToArchive(selectedPageID)
                    }
                } label: {
                    Label("Move to Archive", systemImage: "archivebox")
                        .fcTypography(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.color(.accentInfo))
            } else {
                Button {
                    withAnimation(theme.spring(.snappy)) {
                        service.movePageToLiveTranscripts(selectedPageID)
                    }
                } label: {
                    Label("Move to Live Transcripts", systemImage: "tray.and.arrow.up")
                        .fcTypography(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.color(.accentPrimary))
            }
        }
    }

    @ViewBuilder
    private func editorDeletePageButton(theme: FCTheme) -> some View {
        if let selectedPageID = service.selectedPageID {
            Button {
                pendingDeletePageID = selectedPageID
                showDeletePageConfirmation = true
            } label: {
                Label("Delete Page", systemImage: "trash")
                    .fcTypography(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.color(.stateError))
            .disabled(!service.canDeletePages)
            .opacity(service.canDeletePages ? 1 : 0.4)
        }
    }

    @ViewBuilder
    private func editorPageActionsMenuButton(theme: FCTheme, includeSaveAction: Bool) -> some View {
        Menu {
            if includeSaveAction, service.hasDirtyDraftPages {
                Button("Save", action: saveSelectedOrAllDirtyPages)
            }

            if let selectedPageID = service.selectedPageID,
               let selectedModule = service.selectedPageModule {
                let rows = sidebarRows(for: selectedModule)
                let selectedIndex = rows.firstIndex(where: { $0.id == selectedPageID })

                if selectedModule == .liveTranscripts {
                    Button {
                        withAnimation(theme.spring(.snappy)) {
                            service.movePageToArchive(selectedPageID)
                        }
                    } label: {
                        Label("Move to Archive", systemImage: "archivebox")
                    }
                } else {
                    Button {
                        withAnimation(theme.spring(.snappy)) {
                            service.movePageToLiveTranscripts(selectedPageID)
                        }
                    } label: {
                        Label("Move to Live Transcripts", systemImage: "tray.and.arrow.up")
                    }
                }

                Button {
                    movePageUp(selectedPageID, module: selectedModule, theme: theme)
                } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }
                .disabled((selectedIndex ?? 0) <= 0)

                Button {
                    movePageDown(selectedPageID, module: selectedModule, theme: theme)
                } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }
                .disabled({
                    guard let selectedIndex else { return true }
                    return selectedIndex >= (rows.count - 1)
                }())

                Button(role: .destructive) {
                    pendingDeletePageID = selectedPageID
                    showDeletePageConfirmation = true
                } label: {
                    Label("Delete Page", systemImage: "trash")
                }
                .disabled(!service.canDeletePages)
            }
        } label: {
            Label("Page Actions", systemImage: "ellipsis.circle")
                .fcTypography(.caption)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    @ViewBuilder
    private func actionBarView(theme: FCTheme) -> some View {
        FCActionBar(
            isRunning: isRunning,
            startAvailabilityReason: service.startAvailabilityReason,
            settings: NotchSettings.shared,
            hasDirtyPages: service.hasDirtyDraftPages,
            showOnboardingPrompt: shouldPresentOnboardingOnLaunch,
            onStart: { run() },
            onStop: { stop() },
            onOpenDocument: { service.openFile() },
            onSaveAllDirtyPages: { service.saveAllDirtyPages() },
            onDraft: { showDraft = true },
            onAddPage: { addPage() },
            onSettings: { presentSettings() },
            onOpenOnboarding: {
                settingsGuidedTemplateDraft = nil
                onboardingInitialStep = .welcome
                onboardingEntryContext = .manual
                showOnboarding = true
            }
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Actions

    private func addPage() {
        withAnimation(.spring(response: FCMotionToken.Spring.snappy.response, dampingFraction: FCMotionToken.Spring.snappy.dampingFraction)) {
            _ = service.createPageInSelectedSection()
        }
    }

    private func saveSelectedOrAllDirtyPages() {
        if let selectedPageID = service.selectedPageID,
           service.pageNeedsSave(selectedPageID) {
            _ = service.savePageDraft(selectedPageID)
        } else {
            service.saveAllDirtyPages()
        }
    }

    private func sidebarRows(for module: PageModule) -> [SidebarPageRowModel] {
        switch module {
        case .liveTranscripts:
            return liveSidebarRows
        case .archive:
            return archiveSidebarRows
        }
    }

    private func movePageUp(_ pageID: UUID, module: PageModule, theme: FCTheme) {
        let rows = sidebarRows(for: module)
        guard let pageIndex = rows.firstIndex(where: { $0.id == pageID }), pageIndex > 0 else { return }
        withAnimation(theme.spring(.soft)) {
            _ = service.movePageWithinModule(pageID, module: module, toIndex: pageIndex - 1)
        }
    }

    private func movePageDown(_ pageID: UUID, module: PageModule, theme: FCTheme) {
        let rows = sidebarRows(for: module)
        guard let pageIndex = rows.firstIndex(where: { $0.id == pageID }),
              pageIndex < rows.count - 1 else { return }
        withAnimation(theme.spring(.soft)) {
            _ = service.movePageWithinModule(pageID, module: module, toIndex: pageIndex + 2)
        }
    }

    private func run() {
        switch service.startAvailabilityReason {
        case .ready:
            break
        case .noSelection:
            dropAlertTitle = "Cannot Start"
            dropError = "Select a page in Live Transcripts to enable Start."
            return
        case .selectedPageInArchive:
            dropAlertTitle = "Cannot Start"
            dropError = "Archive pages do not play. Move the selected page to Live Transcripts first."
            return
        case .selectedLivePageEmpty:
            dropAlertTitle = "Cannot Start"
            dropError = "The selected live transcript page is empty. Add script text before starting."
            return
        case .noNonEmptyLivePages:
            dropAlertTitle = "Cannot Start"
            dropError = "Add script to a live transcript page before starting."
            return
        }

        isTextFocused = false
        service.onOverlayDismissed = { [self] in
            isRunning = false
            service.clearReadState()
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        service.startSelectedLivePage()
        isRunning = service.overlayController.isShowing
    }

    private func handlePresentationDrop(url: URL) {
        guard service.confirmDiscardIfNeeded() else { return }
        service.importPresentation(from: url)
    }

    private func stop() {
        service.overlayController.dismiss()
        service.clearReadState()
        isRunning = false
    }

    private func presentSettings(
        initialTab: SettingsTab = .display,
        launchedFromOnboarding: Bool = false,
        guidedTemplateDraft: OnboardingDraft? = nil
    ) {
        settingsInitialTab = initialTab
        settingsLaunchedFromOnboarding = launchedFromOnboarding
        settingsGuidedTemplateDraft = guidedTemplateDraft
        showSettings = true
    }

    private func applyOnboardingDraft(_ draft: OnboardingDraft) {
        NotchSettings.shared.listeningMode = draft.listeningMode
        NotchSettings.shared.overlayMode = draft.overlayMode
    }

    private func handleOnboardingCompletion(_ completion: OnboardingCompletion) {
        if completion.applyDraft {
            applyOnboardingDraft(completion.draft)
        }

        if completion.markOnboardingComplete {
            onboardingCompleted = true
            onboardingVersion = FocusCueOnboardingStorage.currentVersion
            onboardingLastCompletedStep = 0
        } else {
            onboardingCompleted = false
            onboardingLastCompletedStep = completion.draft.lastVisitedStep.rawValue
        }

        if completion.launchGuidedTemplate {
            settingsGuidedTemplateDraft = nil
            startGuidedTemplate(from: completion.draft)
            return
        }

        if let tab = completion.openedSettingsTab {
            presentSettings(
                initialTab: tab,
                launchedFromOnboarding: true,
                guidedTemplateDraft: completion.completionReason == .continueInSettings ? completion.draft : nil
            )
        }
    }

    private func applyGuidedTemplate() {
        service.replaceWorkspaceWithSinglePage(text: defaultText, markAsSaved: true)
        service.clearReadState()
        isTextFocused = true
    }

    private func startGuidedTemplate(from draft: OnboardingDraft) {
        applyOnboardingDraft(draft)
        applyGuidedTemplate()
        run()
    }

    private func returnToGuidedTemplateFromSettings() {
        guard let draft = settingsGuidedTemplateDraft else { return }
        settingsGuidedTemplateDraft = nil
        settingsLaunchedFromOnboarding = false
        startGuidedTemplate(from: draft)
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 16) {
            if let icon = NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            VStack(spacing: 4) {
                Text("FocusCue")
                    .font(.system(size: 20, weight: .bold))
                Text("Version \(appVersion)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Text("A free, open-source teleprompter that highlights your script in real-time as you speak.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/saransh1337/FocusCue")!) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                        Text("GitHub")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Capsule())
                }

                Link(destination: URL(string: "https://donate.stripe.com/aFa8wO4NF2S96jDfn4dMI09")!) {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.pink)
                        Text("Donate")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            Divider().padding(.horizontal, 20)

            VStack(spacing: 4) {
                Text("Made by Fatih Kadir Akin")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Original idea by Semih Kışlar")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Button("OK") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ContentView()
}
