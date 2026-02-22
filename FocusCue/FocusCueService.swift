//
//  FocusCueService.swift
//  FocusCue
//
//  Created by Fatih Kadir Akın on 8.02.2026.
//

import AppKit
import Combine
import CryptoKit
import SwiftUI
import UniformTypeIdentifiers

@Observable
class FocusCueService: NSObject {
    static let shared = FocusCueService()

    let overlayController = NotchOverlayController()
    let externalDisplayController = ExternalDisplayController()
    let browserServer = BrowserServer()

    var onOverlayDismissed: (() -> Void)?
    var launchedExternally = false
    private(set) var restoredWorkspaceFromAutosave = false

    private(set) var workspace: ScriptWorkspace
    private(set) var readPageIDs: Set<UUID> = []
    private(set) var draftPageReferences: [UUID: DraftPageReference] = [:]
    private(set) var dirtyPageIDs: Set<UUID> = []
    private(set) var saveFailedPageIDs: Set<UUID> = []

    var currentFileURL: URL?
    private(set) var savedWorkspace: ScriptWorkspace

    private let workspacePersistence: WorkspacePersistence
    private let draftFileStore: DraftFileStore
    private var pendingDraftIndexSave: DispatchWorkItem?

    override init() {
        let persistence = WorkspacePersistence()
        let draftFileStore = DraftFileStore()
        self.workspacePersistence = persistence
        self.draftFileStore = draftFileStore

        let restoredDraftIndex = draftFileStore.restoreIndex()
        let restoredWorkspace = restoredDraftIndex?.workspace
        self.draftPageReferences = restoredDraftIndex?.pageReferences ?? [:]

        self.restoredWorkspaceFromAutosave = restoredWorkspace != nil
        let restored = restoredWorkspace ?? ScriptWorkspace.makeDefault()
        self.workspace = restored
        self.savedWorkspace = restored

        super.init()

        normalizeWorkspace()
        reconcileDraftReferences()
        refreshDirtyPageState()
        flushDraftIndexSave()
        updatePageInfo()
    }

    // MARK: - Flat compatibility shims

    var pages: [String] {
        get { flattenedPages().map(\.text) }
        set {
            loadTexts(newValue, markAsSaved: false, currentFileURL: currentFileURL)
        }
    }

    var currentPageIndex: Int {
        get { flattenedIndex(for: workspace.selectedPageID) ?? 0 }
        set { selectFlattenedPage(at: newValue) }
    }

    var readPages: Set<Int> {
        get {
            Set(readPageIDs.compactMap { flattenedIndex(for: $0) })
        }
        set {
            readPageIDs = Set(newValue.compactMap { flattenedPageID(at: $0) })
            commitWorkspaceChange()
        }
    }

    var savedPages: [String] {
        get { flattenedPages(in: savedWorkspace).map(\.text) }
        set {
            savedWorkspace = workspaceFromTexts(newValue)
        }
    }

    // MARK: - Derived state

    enum StartAvailabilityReason: Equatable {
        case ready
        case noSelection
        case selectedPageInArchive
        case selectedLivePageEmpty
        case noNonEmptyLivePages
    }

    var hasNextPage: Bool {
        guard selectedPageModule == .liveTranscripts else { return false }
        let pages = liveSequencePages()
        guard let selectedPageID,
              let start = liveSequencePageIDs.firstIndex(of: selectedPageID) else { return false }
        return start + 1 < pages.count
    }

    var currentPageText: String {
        guard let page = page(for: workspace.selectedPageID) else { return "" }
        return page.text
    }

    var selectedPageID: UUID? {
        workspace.selectedPageID
    }

    var selectedPageModule: PageModule? {
        module(containing: workspace.selectedPageID)
    }

    var hasUnsavedChanges: Bool {
        hasDirtyDraftPages || workspaceForDirtyCheck(workspace) != workspaceForDirtyCheck(savedWorkspace)
    }

    var hasDirtyDraftPages: Bool {
        !dirtyPageIDs.isEmpty || !saveFailedPageIDs.isEmpty
    }

    var sidebarSections: [SidebarSectionModel] {
        [
            SidebarSectionModel(
                kind: .liveTranscripts,
                title: "Live Transcripts",
                subtitle: "Plays in sequence on Start",
                pages: makeSidebarRows(from: workspace.livePages, module: .liveTranscripts)
            ),
            SidebarSectionModel(
                kind: .archive,
                title: "Archive",
                subtitle: "Stored only • not in sequence",
                pages: makeSidebarRows(from: workspace.archivePages, module: .archive)
            ),
        ]
    }

    var totalPageCount: Int {
        allPages().count
    }

    var canDeletePages: Bool {
        totalPageCount > 1
    }

    // MARK: - Sidebar display helpers

    func flattenedPages() -> [ScriptPage] {
        allPages()
    }

    func allPages() -> [ScriptPage] {
        workspace.livePages + workspace.archivePages
    }

    func liveSequencePages() -> [ScriptPage] {
        workspace.livePages.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var liveSequencePageIDs: [UUID] {
        liveSequencePages().map(\.id)
    }

    var hasAnyLiveTranscriptContent: Bool {
        workspace.livePages.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var canStartSelectedLiveTranscriptPage: Bool {
        startAvailabilityReason == .ready
    }

    var startAvailabilityReason: StartAvailabilityReason {
        guard let selectedPageID else { return .noSelection }
        guard hasAnyLiveTranscriptContent else { return .noNonEmptyLivePages }
        guard let module = module(containing: selectedPageID) else { return .noSelection }
        guard module == .liveTranscripts else { return .selectedPageInArchive }
        let trimmed = currentPageText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? .selectedLivePageEmpty : .ready
    }

    func flattenedPageIDs() -> [UUID] {
        allPages().map(\.id)
    }

    func flattenedIndex(for pageID: UUID?) -> Int? {
        guard let pageID else { return nil }
        return flattenedPageIDs().firstIndex(of: pageID)
    }

    func pageTitle(for pageID: UUID) -> String {
        page(for: pageID)?.title ?? ""
    }

    func pageNeedsSave(_ pageID: UUID) -> Bool {
        dirtyPageIDs.contains(pageID) || saveFailedPageIDs.contains(pageID)
    }

    func textBindingForSelectedPage() -> Binding<String> {
        Binding(
            get: { [weak self] in
                self?.currentPageText ?? ""
            },
            set: { [weak self] value in
                self?.setTextForSelectedPage(value)
            }
        )
    }

    func sectionPageCount(module: PageModule) -> Int {
        switch module {
        case .liveTranscripts:
            return workspace.livePages.count
        case .archive:
            return workspace.archivePages.count
        }
    }

    // MARK: - Playback / Overlay

    func readText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        launchedExternally = true
        hideMainWindow()

        overlayController.show(text: trimmed, hasNextPage: hasNextPage) { [weak self] in
            self?.externalDisplayController.dismiss()
            self?.browserServer.hideContent()
            self?.onOverlayDismissed?()
        }
        updatePageInfo()

        let words = splitTextIntoWords(trimmed)
        let totalCharCount = words.joined(separator: " ").count
        externalDisplayController.show(
            speechRecognizer: overlayController.speechRecognizer,
            words: words,
            totalCharCount: totalCharCount,
            hasNextPage: hasNextPage
        )

        if browserServer.isRunning {
            browserServer.showContent(
                speechRecognizer: overlayController.speechRecognizer,
                words: words,
                totalCharCount: totalCharCount,
                hasNextPage: hasNextPage
            )
        }
    }

    func readCurrentPage() {
        guard selectedPageModule == .liveTranscripts else { return }
        let trimmed = currentPageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let selectedPageID {
            readPageIDs.insert(selectedPageID)
        }
        readText(trimmed)
    }

    func clearReadState() {
        readPageIDs.removeAll()
        updatePageInfo()
    }

    func startAllPages() {
        readPageIDs.removeAll()
        if let firstID = liveSequencePageIDs.first {
            workspace.selectedPageID = firstID
            commitWorkspaceChange()
            readCurrentPage()
        }
    }

    func advanceToNextPage() {
        guard selectedPageModule == .liveTranscripts else { return }
        let ids = liveSequencePageIDs
        guard let selectedPageID, let current = ids.firstIndex(of: selectedPageID) else { return }
        let next = current + 1
        guard next < ids.count else { return }
        jumpToLiveSequencePage(index: next)
    }

    func jumpToPage(index: Int) {
        guard let targetID = flattenedPageID(at: index) else { return }
        jumpToPage(pageID: targetID)
    }

    func jumpToLiveSequencePage(index: Int) {
        let ids = liveSequencePageIDs
        guard index >= 0 && index < ids.count else { return }
        jumpToPage(pageID: ids[index])
    }

    func jumpToPage(pageID: UUID) {
        guard let page = page(for: pageID) else { return }
        let trimmed = page.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let wasListening = overlayController.speechRecognizer.isListening
        if wasListening {
            overlayController.speechRecognizer.stop()
        }

        workspace.selectedPageID = pageID
        readPageIDs.insert(pageID)

        overlayController.updateContent(text: trimmed, hasNextPage: hasNextPage)
        updatePageInfo()

        let words = splitTextIntoWords(trimmed)
        externalDisplayController.overlayContent.words = words
        externalDisplayController.overlayContent.totalCharCount = words.joined(separator: " ").count
        externalDisplayController.overlayContent.hasNextPage = hasNextPage

        if browserServer.isRunning {
            browserServer.updateContent(
                words: words,
                totalCharCount: words.joined(separator: " ").count,
                hasNextPage: hasNextPage
            )
        }

        if wasListening {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.overlayController.speechRecognizer.resume()
            }
        }

        commitWorkspaceChange()
    }

    func selectPage(_ pageID: UUID) {
        guard page(for: pageID) != nil else { return }
        workspace.selectedPageID = pageID
        commitWorkspaceChange()
    }

    func selectFlattenedPage(at index: Int) {
        guard let pageID = flattenedPageID(at: index) else { return }
        selectPage(pageID)
    }

    // MARK: - Sidebar mutations

    @discardableResult
    func createPage(in module: PageModule = .liveTranscripts) -> UUID {
        let page = makePage(text: "")
        insertPage(page, into: module, at: pageCount(in: module))

        workspace.selectedPageID = page.id
        commitWorkspaceChange()
        return page.id
    }

    @discardableResult
    func createLivePage() -> UUID {
        createPage(in: .liveTranscripts)
    }

    @discardableResult
    func createPageInSelectedSection() -> UUID {
        // Product rule: new pages are created in Live Transcripts.
        createLivePage()
    }

    @discardableResult
    func savePageDraft(_ pageID: UUID) -> Bool {
        guard let page = page(for: pageID) else { return false }
        guard let module = module(containing: pageID) else { return false }
        let digest = pageDigest(for: page)

        do {
            let existing = draftPageReferences[pageID]
            let reference = try draftFileStore.savePage(
                page,
                module: module,
                digest: digest,
                existingReference: existing
            )
            draftPageReferences[pageID] = reference
            saveFailedPageIDs.remove(pageID)
            refreshDirtyPageState()
            flushDraftIndexSave()
            return true
        } catch {
            saveFailedPageIDs.insert(pageID)
            refreshDirtyPageState()
            return false
        }
    }

    func saveAllDirtyPages() {
        let orderedPageIDs = flattenedPageIDs()
        let pending = orderedPageIDs.filter { pageNeedsSave($0) }
        guard !pending.isEmpty else {
            flushDraftIndexSave()
            return
        }

        for pageID in pending {
            _ = savePageDraft(pageID)
        }
        flushDraftIndexSave()
    }

    func renamePage(_ pageID: UUID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard updatePage(pageID: pageID, mutation: { page in
            page.title = trimmed
            page.isCustomTitle = true
        }) else {
            return
        }
        commitWorkspaceChange()
    }

    func deletePage(_ pageID: UUID) {
        guard canDeletePages else { return }
        guard removePage(pageID) != nil else { return }

        if let reference = draftPageReferences.removeValue(forKey: pageID) {
            do {
                try draftFileStore.trashPageFile(reference: reference)
            } catch {
                // Ignore trash failures for deleted pages.
            }
        }

        readPageIDs.remove(pageID)
        dirtyPageIDs.remove(pageID)
        saveFailedPageIDs.remove(pageID)
        if workspace.selectedPageID == pageID {
            workspace.selectedPageID = nil
        }

        commitWorkspaceChange()
    }

    func deleteSelectedPage() {
        guard let selectedPageID else { return }
        deletePage(selectedPageID)
    }

    @discardableResult
    func movePageWithinModule(_ pageID: UUID, module: PageModule, toIndex: Int) -> Bool {
        guard let source = pageLocation(for: pageID) else { return false }
        guard source.module == module else { return false }
        let destinationCapacity = pageCount(in: module)

        var targetIndex = max(0, min(toIndex, destinationCapacity))
        if source.index < targetIndex {
            targetIndex -= 1
        }

        if source.index == targetIndex {
            return false
        }

        guard let removed = removePage(pageID) else { return false }
        insertPage(removed.page, into: module, at: targetIndex)

        workspace.selectedPageID = pageID
        commitWorkspaceChange()
        return true
    }

    func movePageToArchive(_ pageID: UUID) {
        guard let source = pageLocation(for: pageID), source.module == .liveTranscripts else { return }
        guard let removed = removePage(pageID) else { return }
        insertPage(removed.page, into: .archive, at: workspace.archivePages.count)
        workspace.selectedPageID = pageID
        commitWorkspaceChange()
    }

    func movePageToLiveTranscripts(_ pageID: UUID, toIndex: Int? = nil) {
        guard let source = pageLocation(for: pageID), source.module == .archive else { return }
        guard let removed = removePage(pageID) else { return }
        insertPage(removed.page, into: .liveTranscripts, at: toIndex ?? workspace.livePages.count)
        workspace.selectedPageID = pageID
        commitWorkspaceChange()
    }

    func setTextForSelectedPage(_ text: String) {
        guard let selectedPageID else { return }
        setText(text, forPageID: selectedPageID)
    }

    func setText(_ text: String, forPageID pageID: UUID) {
        guard updatePage(pageID: pageID, mutation: { page in
            page.text = text
            if !page.isCustomTitle {
                page.title = autoTitle(for: page, text: text)
            }
        }) else {
            return
        }
        commitWorkspaceChange()
    }

    func replaceWorkspaceWithSinglePage(text: String, markAsSaved: Bool) {
        loadTexts([text], markAsSaved: markAsSaved, currentFileURL: nil)
    }

    func startSelectedLivePage() {
        guard startAvailabilityReason == .ready else { return }
        clearReadState()
        readCurrentPage()
    }

    // MARK: - Overlay metadata

    func updatePageInfo() {
        let pages = liveSequencePages()
        let content = overlayController.overlayContent

        content.pageCount = pages.count
        if let selectedPageID,
           let liveIndex = liveSequencePageIDs.firstIndex(of: selectedPageID) {
            content.currentPageIndex = liveIndex
        } else {
            content.currentPageIndex = 0
        }
        content.pagePreviews = pages.map { pagePreview(for: $0.text) }
        content.pageTitles = pages.map(\.title)
    }

    // MARK: - Window

    func hideMainWindow() {
        DispatchQueue.main.async {
            for window in NSApp.windows where !(window is NSPanel) {
                window.makeFirstResponder(nil)
                window.orderOut(nil)
            }
        }
    }

    // MARK: - File operations

    func saveFile() {
        if let url = currentFileURL {
            saveToURL(url)
        } else {
            saveFileAs()
        }
    }

    func saveFileAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "focuscue")!]
        panel.nameFieldStringValue = "Untitled.focuscue"
        panel.canCreateDirectories = true

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.saveToURL(url)
        }
    }

    private func saveToURL(_ url: URL) {
        do {
            let payload = FocusCueDocumentV3(workspace: workspace)
            let data = try JSONEncoder().encode(payload)
            try data.write(to: url, options: .atomic)
            currentFileURL = url
            savedWorkspace = workspace
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to save file"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    func openFile() {
        guard confirmDiscardIfNeeded() else { return }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "focuscue")!,
            .init(filenameExtension: "key")!,
            .init(filenameExtension: "pptx")!,
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            let ext = url.pathExtension.lowercased()
            if ext == "key" {
                let alert = NSAlert()
                alert.messageText = "Keynote files can't be imported directly"
                alert.informativeText = "Please export your Keynote presentation as PowerPoint (.pptx) first:\n\nIn Keynote: File → Export To → PowerPoint"
                alert.alertStyle = .informational
                alert.runModal()
            } else if ext == "pptx" {
                self?.importPresentation(from: url)
            } else {
                self?.openFileAtURL(url)
            }
        }
    }

    func openFileAtURL(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)

            if let document = try? JSONDecoder().decode(FocusCueDocumentV3.self, from: data) {
                guard document.schemaVersion == FocusCueDocumentV3.currentSchemaVersion else {
                    showUnsupportedSchemaAlert()
                    return
                }
                loadWorkspace(document.workspace, markAsSaved: true, currentFileURL: url)
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
                return
            }

            if (try? JSONDecoder().decode([String].self, from: data)) != nil {
                showUnsupportedLegacyAlert()
                return
            }

            throw NSError(domain: "FocusCue", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "The file is not a valid FocusCue document.",
            ])
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed to open file"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    func importPresentation(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let notes = try PresentationNotesExtractor.extractNotes(from: url)
                DispatchQueue.main.async {
                    self?.loadTexts(notes, markAsSaved: true, currentFileURL: nil)
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Import Error"
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }

    /// Returns true if it's safe to proceed (saved, discarded, or no changes).
    /// Returns false if the user cancelled.
    func confirmDiscardIfNeeded() -> Bool {
        let dirtyPageIDs = flattenedPages().map(\.id).filter { pageNeedsSave($0) }
        guard !dirtyPageIDs.isEmpty else { return true }

        let dirtyTitles = dirtyPageIDs.compactMap { pageTitle(for: $0) }
        let previewList = dirtyTitles.prefix(3).joined(separator: ", ")
        let extraCount = max(0, dirtyTitles.count - 3)

        let alert = NSAlert()
        alert.messageText = "You have unsaved page changes"
        if extraCount > 0 {
            alert.informativeText = "\(dirtyTitles.count) pages need saving (\(previewList), and \(extraCount) more)."
        } else {
            alert.informativeText = "\(dirtyTitles.count) pages need saving (\(previewList))."
        }
        alert.addButton(withTitle: "Save All")
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            saveAllDirtyPages()
            return !hasDirtyDraftPages
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    // MARK: - Browser server

    func updateBrowserServer() {
        if NotchSettings.shared.browserServerEnabled {
            if !browserServer.isRunning {
                browserServer.start()
            }
        } else {
            browserServer.stop()
        }
    }

    func flushPendingPersistence() {
        pendingDraftIndexSave?.cancel()
        flushDraftIndexSave()
        workspacePersistence.saveImmediately(workspace: workspace)
    }

    // macOS Services handler
    @objc func readInFocusCue(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let text = pboard.string(forType: .string) else {
            error.pointee = "No text found on pasteboard" as NSString
            return
        }
        readText(text)
    }

    // URL scheme handler: focuscue://read?text=Hello%20World
    func handleURL(_ url: URL) {
        guard url.scheme == "focuscue" else { return }

        if url.host == "read" || url.path == "/read" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let textParam = components.queryItems?.first(where: { $0.name == "text" })?.value {
                readText(textParam)
            }
        }
    }

    // MARK: - Workspace internals

    private func commitWorkspaceChange() {
        normalizeWorkspace()
        reconcileDraftReferences()
        syncSavedPageFilesToCurrentLocations()
        refreshDirtyPageState()
        scheduleDraftIndexSave()
        workspacePersistence.scheduleSave(workspace: workspace)
        updatePageInfo()
    }

    private func loadTexts(_ texts: [String], markAsSaved: Bool, currentFileURL: URL?) {
        let nextWorkspace = workspaceFromTexts(texts)
        loadWorkspace(nextWorkspace, markAsSaved: markAsSaved, currentFileURL: currentFileURL)
    }

    private func loadWorkspace(_ workspace: ScriptWorkspace, markAsSaved: Bool, currentFileURL: URL?) {
        self.workspace = workspace
        self.currentFileURL = currentFileURL
        readPageIDs.removeAll()
        normalizeWorkspace()
        reconcileDraftReferences()
        syncSavedPageFilesToCurrentLocations()
        refreshDirtyPageState()
        flushDraftIndexSave()
        workspacePersistence.saveImmediately(workspace: self.workspace)
        updatePageInfo()

        if markAsSaved {
            savedWorkspace = self.workspace
        }
    }

    private func workspaceFromTexts(_ texts: [String]) -> ScriptWorkspace {
        var counter = 1
        var pages: [ScriptPage] = []

        for text in texts {
            let fallback = "Page \(counter)"
            counter += 1
            let title = firstMeaningfulLine(in: text) ?? fallback
            pages.append(
                ScriptPage(
                    id: UUID(),
                    title: title,
                    text: text,
                    isCustomTitle: false
                )
            )
        }

        if pages.isEmpty {
            pages = [
                ScriptPage(
                    id: UUID(),
                    title: "Page \(counter)",
                    text: "",
                    isCustomTitle: false
                ),
            ]
            counter += 1
        }

        return ScriptWorkspace(
            livePages: pages,
            archivePages: [],
            selectedPageID: pages.first?.id,
            nextPageCounter: counter
        )
    }

    private func normalizeWorkspace() {
        if workspace.nextPageCounter < 1 {
            workspace.nextPageCounter = 1
        }

        for index in workspace.livePages.indices {
            if !workspace.livePages[index].isCustomTitle {
                workspace.livePages[index].title = autoTitle(for: workspace.livePages[index], text: workspace.livePages[index].text)
            }
        }

        for pageIndex in workspace.archivePages.indices {
            if !workspace.archivePages[pageIndex].isCustomTitle {
                let page = workspace.archivePages[pageIndex]
                workspace.archivePages[pageIndex].title = autoTitle(for: page, text: page.text)
            }
        }

        if allPages().isEmpty {
            workspace.livePages = [makePage(text: "")]
        }

        let validPageIDs = Set(flattenedPageIDs())
        readPageIDs = readPageIDs.intersection(validPageIDs)

        if let selected = workspace.selectedPageID,
           flattenedPageIDs().contains(selected) {
            return
        }

        workspace.selectedPageID = flattenedPageIDs().first
    }

    private func workspaceForDirtyCheck(_ workspace: ScriptWorkspace) -> ScriptWorkspace {
        var copy = workspace
        copy.selectedPageID = nil
        return copy
    }

    private func makeSidebarRows(from pages: [ScriptPage], module: PageModule) -> [SidebarPageRowModel] {
        pages.enumerated().map { (offset, page) in
            SidebarPageRowModel(
                id: page.id,
                module: module,
                localIndex: offset + 1,
                displayTitle: "\(offset + 1). \(page.title)",
                baseTitle: page.title,
                preview: pagePreview(for: page.text),
                isRead: readPageIDs.contains(page.id),
                isSelected: workspace.selectedPageID == page.id,
                needsSave: dirtyPageIDs.contains(page.id),
                saveFailed: saveFailedPageIDs.contains(page.id)
            )
        }
    }

    private func pagePreview(for text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let preview = String(trimmed.prefix(40))
        return preview + (trimmed.count > 40 ? "…" : "")
    }

    private func firstMeaningfulLine(in text: String) -> String? {
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            return String(line.prefix(80))
        }
        return nil
    }

    private func nextFallbackTitle() -> String {
        let counter = max(1, workspace.nextPageCounter)
        workspace.nextPageCounter = counter + 1
        return "Page \(counter)"
    }

    private func makePage(text: String) -> ScriptPage {
        let fallback = nextFallbackTitle()
        let title = firstMeaningfulLine(in: text) ?? fallback
        return ScriptPage(id: UUID(), title: title, text: text, isCustomTitle: false)
    }

    private func autoTitle(for page: ScriptPage, text: String) -> String {
        if let line = firstMeaningfulLine(in: text) {
            return line
        }
        if isFallbackTitle(page.title) {
            return page.title
        }
        return nextFallbackTitle()
    }

    private func isFallbackTitle(_ value: String) -> Bool {
        value.range(of: "^Page [0-9]+$", options: .regularExpression) != nil
    }

    private func flattenedPages(in workspace: ScriptWorkspace) -> [ScriptPage] {
        workspace.livePages + workspace.archivePages
    }

    private func flattenedPageID(at index: Int) -> UUID? {
        let ids = flattenedPageIDs()
        guard index >= 0 && index < ids.count else { return nil }
        return ids[index]
    }

    private func page(for pageID: UUID?) -> ScriptPage? {
        guard let pageID else { return nil }
        if let livePage = workspace.livePages.first(where: { $0.id == pageID }) {
            return livePage
        }
        return workspace.archivePages.first(where: { $0.id == pageID })
    }

    private func module(containing pageID: UUID?) -> PageModule? {
        guard let pageID else { return nil }
        if workspace.livePages.contains(where: { $0.id == pageID }) {
            return .liveTranscripts
        }
        if workspace.archivePages.contains(where: { $0.id == pageID }) {
            return .archive
        }
        return nil
    }

    private func pageLocation(for pageID: UUID) -> (module: PageModule, index: Int)? {
        if let index = workspace.livePages.firstIndex(where: { $0.id == pageID }) {
            return (.liveTranscripts, index)
        }
        if let index = workspace.archivePages.firstIndex(where: { $0.id == pageID }) {
            return (.archive, index)
        }
        return nil
    }

    private func pageCount(in module: PageModule) -> Int {
        switch module {
        case .liveTranscripts:
            return workspace.livePages.count
        case .archive:
            return workspace.archivePages.count
        }
    }

    private func updatePage(pageID: UUID, mutation: (inout ScriptPage) -> Void) -> Bool {
        if let liveIndex = workspace.livePages.firstIndex(where: { $0.id == pageID }) {
            mutation(&workspace.livePages[liveIndex])
            return true
        }
        if let archiveIndex = workspace.archivePages.firstIndex(where: { $0.id == pageID }) {
            mutation(&workspace.archivePages[archiveIndex])
            return true
        }
        return false
    }

    private func removePage(_ pageID: UUID) -> (page: ScriptPage, sourceModule: PageModule, sourceIndex: Int)? {
        if let liveIndex = workspace.livePages.firstIndex(where: { $0.id == pageID }) {
            let removed = workspace.livePages.remove(at: liveIndex)
            return (removed, .liveTranscripts, liveIndex)
        }
        if let archiveIndex = workspace.archivePages.firstIndex(where: { $0.id == pageID }) {
            let removed = workspace.archivePages.remove(at: archiveIndex)
            return (removed, .archive, archiveIndex)
        }
        return nil
    }

    private func insertPage(_ page: ScriptPage, into module: PageModule, at index: Int) {
        switch module {
        case .liveTranscripts:
            let clamped = max(0, min(index, workspace.livePages.count))
            workspace.livePages.insert(page, at: clamped)
        case .archive:
            let clamped = max(0, min(index, workspace.archivePages.count))
            workspace.archivePages.insert(page, at: clamped)
        }
    }

    private func scheduleDraftIndexSave(delay: TimeInterval = 0.30) {
        pendingDraftIndexSave?.cancel()

        let workspaceSnapshot = workspace
        let referencesSnapshot = draftPageReferences
        let item = DispatchWorkItem { [draftFileStore] in
            try? draftFileStore.saveIndex(workspace: workspaceSnapshot, pageReferences: referencesSnapshot)
        }
        pendingDraftIndexSave = item
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func flushDraftIndexSave() {
        pendingDraftIndexSave?.cancel()
        pendingDraftIndexSave = nil
        try? draftFileStore.saveIndex(workspace: workspace, pageReferences: draftPageReferences)
    }

    private func reconcileDraftReferences() {
        let validIDs = Set(flattenedPageIDs())
        draftPageReferences = draftPageReferences.filter { validIDs.contains($0.key) }
        dirtyPageIDs = dirtyPageIDs.intersection(validIDs)
        saveFailedPageIDs = saveFailedPageIDs.intersection(validIDs)
    }

    private func refreshDirtyPageState() {
        let pages = flattenedPages()
        let validIDs = Set(pages.map(\.id))
        var dirty: Set<UUID> = []

        for page in pages {
            let digest = pageDigest(for: page)
            if let reference = draftPageReferences[page.id] {
                if reference.savedDigest != digest {
                    dirty.insert(page.id)
                }
            } else if shouldTrackDraftChange(for: page) {
                dirty.insert(page.id)
            }
        }

        dirtyPageIDs = dirty
        saveFailedPageIDs = saveFailedPageIDs.intersection(validIDs)
    }

    private func shouldTrackDraftChange(for page: ScriptPage) -> Bool {
        let hasText = !page.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasText || page.isCustomTitle
    }

    private func pageDigest(for page: ScriptPage) -> String {
        let raw = "\(page.id.uuidString)\n\(page.title)\n\(page.isCustomTitle)\n\(page.text)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func syncSavedPageFilesToCurrentLocations() {
        var nextReferences = draftPageReferences

        for (pageID, reference) in draftPageReferences {
            guard let targetModule = module(containing: pageID) else { continue }
            do {
                let relocated = try draftFileStore.relocatePageFileIfNeeded(
                    pageID: pageID,
                    module: targetModule,
                    reference: reference
                )
                nextReferences[pageID] = relocated
                saveFailedPageIDs.remove(pageID)
            } catch {
                saveFailedPageIDs.insert(pageID)
            }
        }

        draftPageReferences = nextReferences
    }

    private func showUnsupportedLegacyAlert() {
        let alert = NSAlert()
        alert.messageText = "Unsupported FocusCue Format"
        alert.informativeText = "This file uses the legacy array-only .focuscue format, which is no longer supported in this version."
        alert.runModal()
    }

    private func showUnsupportedSchemaAlert() {
        let alert = NSAlert()
        alert.messageText = "Unsupported FocusCue Format"
        alert.informativeText = "This .focuscue document uses an unsupported schema version."
        alert.runModal()
    }
}
