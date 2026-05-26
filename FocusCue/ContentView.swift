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
    @State private var entitlements = EntitlementService.shared
    @State private var isRunning = false
    @State private var isDroppingPresentation = false
    @State private var dropError: String?
    @State private var dropAlertTitle = "Import Error"
    @State private var settingsGuidedTemplateDraft: OnboardingDraft?
    @State private var showOnboarding = false
    @State private var onboardingInitialStep: OnboardingStep = .welcome
    @State private var onboardingEntryContext: OnboardingEntryContext = .firstRun
    @State private var revealMainWindow = false
    @State private var showDeletePageConfirmation = false
    @State private var pendingDeletePageID: UUID?
    @State private var modalCoordinator = AppModalCoordinator()
    @State private var commandCoordinator = AppCommandCoordinator.shared

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

    private var selectedSidebarRow: SidebarPageRowModel? {
        guard let selectedPageID = service.selectedPageID,
              let selectedModule = service.selectedPageModule else {
            return nil
        }
        return sidebarRows(for: selectedModule).first { $0.id == selectedPageID }
    }

    private var selectedPageSaveFailed: Bool {
        selectedSidebarRow?.saveFailed ?? false
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

    private var currentTheme: FCTheme {
        FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
    }

    var body: some View {
        let theme = currentTheme
        lifecycleSubscriptions(
            modalAndDialogs(
                mainLayout(theme: theme),
                theme: theme
            )
        )
    }

    private func mainLayout(theme: FCTheme) -> some View {
        GeometryReader { proxy in
            mainLayout(theme: theme, isCompactLayout: proxy.size.width < 920)
        }
    }

    @ViewBuilder
    private func mainLayout(theme: FCTheme, isCompactLayout: Bool) -> some View {
        let contentPadding = FCSpacingToken.s16.rawValue
        let mainStackSpacing = FCSpacingToken.s12.rawValue
        let columnSpacing = FCSpacingToken.s12.rawValue
        let sidebarWidth: CGFloat = 220
        let editorMinHeight: CGFloat = 220

        ZStack {
            FCWindowBackdrop()

            VStack(alignment: .leading, spacing: mainStackSpacing) {
                FCWindowHeader(
                    subtitle: "Stay on script. Stay on camera. Stay natural.",
                    entitlements: entitlements,
                    compact: isCompactLayout
                )

                if isCompactLayout {
                    VStack(alignment: .leading, spacing: mainStackSpacing) {
                        pageRailView(theme: theme, width: sidebarWidth)
                        editorPanel(theme: theme, minHeight: editorMinHeight)
                        actionBarView(theme: theme)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    HStack(alignment: .top, spacing: columnSpacing) {
                        pageRailView(theme: theme, width: sidebarWidth)

                        VStack(spacing: mainStackSpacing) {
                            editorPanel(theme: theme, minHeight: editorMinHeight)
                            actionBarView(theme: theme)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .padding(contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .opacity(revealMainWindow ? 1 : 0)
            .offset(y: revealMainWindow ? 0 : (reduceMotion ? 0 : 12))
            .animation(theme.animation(.emphasized, curve: .enter), value: revealMainWindow)

            dropZoneOverlay()
        }
    }

    @ViewBuilder
    private func dropZoneOverlay() -> some View {
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

    private func modalAndDialogs<Content: View>(_ content: Content, theme: FCTheme) -> some View {
        content
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
                    guard entitlements.canPerform(.delete, on: pageID, in: service.workspace) else {
                        pendingDeletePageID = nil
                        return
                    }
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
            .frame(minWidth: 720, minHeight: 540)
            .sheet(
                isPresented: Binding(
                    get: { modalCoordinator.activeRoute != nil },
                    set: { isPresented in
                        if !isPresented {
                            modalCoordinator.clear()
                        }
                    }
                )
            ) {
                modalSheetContent
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
    }

    private func lifecycleSubscriptions<Content: View>(_ content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
                presentSettings()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openAbout)) { _ in
                modalCoordinator.present(.about)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openOnboarding)) { _ in
                settingsGuidedTemplateDraft = nil
                onboardingInitialStep = .welcome
                onboardingEntryContext = .manual
                showOnboarding = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                isRunning = service.overlayController.isShowing
                entitlements.refreshPresentationState()
                entitlements.enforceAllowedSettings()
            }
            .onAppear {
                entitlements.handleAppLaunch()
                processPendingCommands()
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
            .onChange(of: service.selectedPageID) { _, _ in
                entitlements.syncLiteUnlockedPage(with: service.workspace)
            }
            .onChange(of: commandCoordinator.enqueueCount) { _, _ in
                processPendingCommands()
            }
    }

    // MARK: - Main Window Subviews

    @ViewBuilder
    private func pageRailView(theme: FCTheme, width: CGFloat) -> some View {
        FCPageRail(
            livePages: liveSidebarRows,
            archivePages: archiveSidebarRows,
            canAddPages: entitlements.has(.multiPageEditing),
            canDeletePages: service.canDeletePages,
            onSelectPage: { pageID in
                withAnimation(theme.spring(.snappy)) {
                    service.selectPage(pageID)
                }
            },
            onSelectLockedPage: { pageID in
                service.selectPage(pageID)
            },
            onRenamePage: { pageID, title in
                service.renamePage(pageID, to: title)
            },
            onSavePage: { pageID in
                _ = service.savePageDraft(pageID)
            },
            onDeletePage: { pageID in
                guard entitlements.canPerform(.delete, on: pageID, in: service.workspace) else {
                    return
                }
                pendingDeletePageID = pageID
                showDeletePageConfirmation = true
            },
            onAddLivePage: { addPage() },
            onAddLocked: {
                addPage()
            },
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
        let canEditSelectedPage = entitlements.canPerform(.editText, on: service.selectedPageID, in: service.workspace)
        let hasSaveFailure = selectedPageSaveFailed

        FCGlassPanel {
            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    Text("Script Editor")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.titleSm)
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
                            .fill(theme.color(.surfaceInset))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                            .stroke(
                                hasSaveFailure
                                    ? theme.color(.resyncVioletText)
                                    : (isTextFocused ? theme.color(.cueMint) : theme.color(.controlBorder)),
                                lineWidth: (hasSaveFailure || isTextFocused) ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
                            )
                    )
                    .focused($isTextFocused)
                    .disabled(!canEditSelectedPage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                if hasSaveFailure {
                    HStack(spacing: FCSpacingToken.s6.rawValue) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text("SAVE FAILED. CHECK FILE ACCESS AND TRY AGAIN.")
                            .fcTypography(.labelCaps)
                    }
                    .foregroundStyle(theme.color(.resyncVioletText))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: .infinity)
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
            .foregroundStyle(theme.color(.cueMint))
        }
    }

    @ViewBuilder
    private func editorMovePageButton(theme: FCTheme) -> some View {
        if let selectedPageID = service.selectedPageID,
           let selectedModule = service.selectedPageModule {
            let canMoveSelectedPage = entitlements.canPerform(.moveBetweenSections, on: selectedPageID, in: service.workspace)
            if selectedModule == .liveTranscripts {
                Button {
                    guard canMoveSelectedPage else {
                        return
                    }
                    withAnimation(theme.spring(.snappy)) {
                        service.movePageToArchive(selectedPageID)
                    }
                } label: {
                    Label("Move to Archive", systemImage: "archivebox")
                        .fcTypography(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.color(canMoveSelectedPage ? .teleprompterOrange : .textDisabled))
                .disabled(!canMoveSelectedPage)
            } else {
                Button {
                    guard canMoveSelectedPage else {
                        return
                    }
                    withAnimation(theme.spring(.snappy)) {
                        service.movePageToLiveTranscripts(selectedPageID)
                    }
                } label: {
                    Label("Move to Live Transcripts", systemImage: "tray.and.arrow.up")
                        .fcTypography(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.color(canMoveSelectedPage ? .cueMint : .textDisabled))
                .disabled(!canMoveSelectedPage)
            }
        }
    }

    @ViewBuilder
    private func editorDeletePageButton(theme: FCTheme) -> some View {
        if let selectedPageID = service.selectedPageID {
            let canDeleteSelectedPage = entitlements.canPerform(.delete, on: selectedPageID, in: service.workspace)
            Button {
                guard canDeleteSelectedPage else {
                    return
                }
                pendingDeletePageID = selectedPageID
                showDeletePageConfirmation = true
            } label: {
                Label("Delete Page", systemImage: "trash")
                    .fcTypography(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.color((service.canDeletePages && canDeleteSelectedPage) ? .dangerText : .textDisabled))
            .disabled(!service.canDeletePages || !canDeleteSelectedPage)
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
                let canMoveBetweenSections = entitlements.canPerform(.moveBetweenSections, on: selectedPageID, in: service.workspace)

                if selectedModule == .liveTranscripts {
                    Button {
                        withAnimation(theme.spring(.snappy)) {
                            service.movePageToArchive(selectedPageID)
                        }
                    } label: {
                        Label("Move to Archive", systemImage: "archivebox")
                    }
                    .disabled(!canMoveBetweenSections)
                } else {
                    Button {
                        withAnimation(theme.spring(.snappy)) {
                            service.movePageToLiveTranscripts(selectedPageID)
                        }
                    } label: {
                        Label("Move to Live Transcripts", systemImage: "tray.and.arrow.up")
                    }
                    .disabled(!canMoveBetweenSections)
                }

                Button {
                    movePageUp(selectedPageID, module: selectedModule, theme: theme)
                } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }
                .disabled((selectedIndex ?? 0) <= 0 || !entitlements.canPerform(.reorder, on: selectedPageID, in: service.workspace))

                Button {
                    movePageDown(selectedPageID, module: selectedModule, theme: theme)
                } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }
                .disabled({
                    guard let selectedIndex else { return true }
                    return selectedIndex >= (rows.count - 1) || !entitlements.canPerform(.reorder, on: selectedPageID, in: service.workspace)
                }())

                Button(role: .destructive) {
                    guard entitlements.canPerform(.delete, on: selectedPageID, in: service.workspace) else {
                        return
                    }
                    pendingDeletePageID = selectedPageID
                    showDeletePageConfirmation = true
                } label: {
                    Label("Delete Page", systemImage: "trash")
                }
                .disabled(!service.canDeletePages || !entitlements.canPerform(.delete, on: selectedPageID, in: service.workspace))
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
            accessTier: entitlements.tier,
            settings: NotchSettings.shared,
            hasDirtyPages: service.hasDirtyDraftPages,
            showOnboardingPrompt: shouldPresentOnboardingOnLaunch,
            onStart: { run() },
            onStop: { stop() },
            onOpenDocument: { service.openFile() },
            onSaveAllDirtyPages: { saveSelectedOrAllDirtyPages() },
            onDraft: { openDraft() },
            onAddPage: { addPage() },
            onSettings: { presentSettings() },
            onOpenOnboarding: {
                settingsGuidedTemplateDraft = nil
                onboardingInitialStep = .welcome
                onboardingEntryContext = .manual
                showOnboarding = true
            },
            onBlockedFeature: { feature in
                let _ = feature
            }
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var modalSheetContent: some View {
        if let rootRoute = modalCoordinator.stack.first {
            ZStack(alignment: .top) {
                modalBaseContent(for: rootRoute)

                if modalCoordinator.stack.count > 1,
                   let overlayRoute = modalCoordinator.activeRoute {
                    currentTheme.color(.absoluteBlack).opacity(0.56)
                        .ignoresSafeArea()

                    modalOverlayContent(for: overlayRoute)
                }
            }
        } else {
            Color.clear
                .frame(width: 1, height: 1)
        }
    }

    @ViewBuilder
    private func modalBaseContent(for route: AppModalCoordinator.Route) -> some View {
        switch route {
        case .draft:
            DraftSessionView(
                onAccept: { script in
                    let trimmed = script.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    service.replaceWorkspaceWithSinglePage(text: trimmed, markAsSaved: true)
                },
                onClose: {
                    modalCoordinator.pop()
                },
                onBlockedFeature: { feature in
                    let _ = feature
                }
            )
        case .settings(let initialTab, let launchedFromOnboarding):
            SettingsView(
                settings: NotchSettings.shared,
                initialTab: initialTab,
                launchedFromOnboarding: launchedFromOnboarding,
                onReturnToGuidedTemplate: settingsGuidedTemplateDraft != nil ? {
                    returnToGuidedTemplateFromSettings()
                } : nil,
                onBlockedFeature: { feature in
                    let _ = feature
                }
            )
        case .about:
            AboutView()
        }
    }

    @ViewBuilder
    private func modalOverlayContent(for route: AppModalCoordinator.Route) -> some View {
        modalBaseContent(for: route)
    }

    // MARK: - Actions

    private func addPage() {
        withAnimation(currentTheme.spring(.snappy)) {
            _ = service.createPageInSelectedSection()
        }
    }

    private func saveSelectedOrAllDirtyPages() {
        if let selectedPageID = service.selectedPageID,
           service.pageNeedsSave(selectedPageID),
           entitlements.canPerform(.save, on: selectedPageID, in: service.workspace) {
            _ = service.savePageDraft(selectedPageID)
        } else {
            let result = service.saveAllDirtyPagesRespectingAccess()
            if !result.skippedLockedPageIDs.isEmpty {
                dropAlertTitle = "Save Incomplete"
                dropError = "Some pages could not be saved."
            }
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
        guard ensureEntitlementsResolvedForSensitiveAction() else { return }
        entitlements.refreshPresentationState()
        entitlements.enforceAllowedSettings()

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
            entitlements.refreshPresentationState()
            entitlements.enforceAllowedSettings()
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
        entitlements.enforceAllowedSettings()
        settingsGuidedTemplateDraft = guidedTemplateDraft
        modalCoordinator.present(.settings(initialTab: initialTab, launchedFromOnboarding: launchedFromOnboarding))
    }

    private func applyOnboardingDraft(_ draft: OnboardingDraft) {
        NotchSettings.shared.listeningMode = draft.listeningMode
        NotchSettings.shared.overlayMode = draft.overlayMode
        entitlements.enforceAllowedSettings()
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
            let shouldApplyDraftBeforeStart = !completion.applyDraft
            startGuidedTemplate(from: completion.draft, applyDraftBeforeStart: shouldApplyDraftBeforeStart)
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

    private func startGuidedTemplate(from draft: OnboardingDraft, applyDraftBeforeStart: Bool = true) {
        if applyDraftBeforeStart {
            applyOnboardingDraft(draft)
        }
        applyGuidedTemplate()
        run()
    }

    private func returnToGuidedTemplateFromSettings() {
        guard let draft = settingsGuidedTemplateDraft else { return }
        settingsGuidedTemplateDraft = nil
        startGuidedTemplate(from: draft)
    }

    private func openDraft() {
        guard ensureEntitlementsResolvedForSensitiveAction() else { return }
        entitlements.refreshPresentationState()
        entitlements.enforceAllowedSettings()

        modalCoordinator.present(.draft)
    }

    private func processPendingCommands() {
        let commands = commandCoordinator.drainCommands()
        for command in commands {
            switch command {
            case .openSettings:
                presentSettings()
            }
        }
    }

    private func ensureEntitlementsResolvedForSensitiveAction() -> Bool {
        guard entitlements.hasResolvedPurchaseState else {
            entitlements.handleAppLaunch()
            dropAlertTitle = "Checking Access"
            dropError = "Please wait a moment while FocusCue prepares access."
            return false
        }
        return true
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var theme: FCTheme {
        FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
    }

    var body: some View {
        VStack(spacing: 16) {
            FCBrandIconView(size: 80, cornerRadius: 18)

            VStack(spacing: 4) {
                Text("FocusCue")
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.titleMd)
                Text("Version \(appVersion)")
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.monoTimestamp)
            }

            Text("A camera-first macOS teleprompter that keeps your script close, calm, and ready to deliver.")
                .foregroundStyle(theme.color(.textSecondary))
                .fcTypography(.bodyCompact)
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
                    .foregroundStyle(theme.color(.cueMint))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(theme.color(.canvasBlack))
                    .overlay(Capsule(style: .continuous).stroke(theme.color(.cueMint), lineWidth: FCStrokeToken.thin.rawValue))
                    .clipShape(Capsule())
                }

                Link(destination: URL(string: "https://donate.stripe.com/aFa8wO4NF2S96jDfn4dMI09")!) {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(theme.color(.dangerText))
                        Text("Donate")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(theme.color(.dangerText))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(theme.color(.canvasBlack))
                    .overlay(Capsule(style: .continuous).stroke(theme.color(.dangerText), lineWidth: FCStrokeToken.thin.rawValue))
                    .clipShape(Capsule())
                }
            }

            Rectangle()
                .fill(theme.color(.controlBorder))
                .frame(height: 1)
                .padding(.horizontal, 20)

            VStack(spacing: 4) {
                Text("Made by Fatih Kadir Akin")
                    .fcTypography(.caption)
                    .foregroundStyle(theme.color(.textSecondary))
                Text("Original idea by Semih Kışlar")
                    .fcTypography(.caption)
                    .foregroundStyle(theme.color(.textTertiary))
            }

            Button("OK") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.onAccentForeground(for: .cueMint))
            .fcTypography(.monoButton)
            .padding(.horizontal, FCSpacingToken.s20.rawValue)
            .padding(.vertical, FCSpacingToken.s8.rawValue)
            .background(Capsule(style: .continuous).fill(theme.color(.cueMint)))
            .controlSize(.small)
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 320)
        .background(theme.color(.surfaceSlate))
        .overlay(
            RoundedRectangle(cornerRadius: FCShapeToken.radius20.rawValue, style: .continuous)
                .stroke(theme.color(.controlBorder), lineWidth: FCStrokeToken.thin.rawValue)
        )
    }
}

#Preview {
    ContentView()
}
