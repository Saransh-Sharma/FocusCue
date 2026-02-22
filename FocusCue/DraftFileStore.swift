//
//  DraftFileStore.swift
//  FocusCue
//

import Foundation

struct DraftPageReference: Codable, Equatable {
    var relativePath: String
    var savedDigest: String
}

struct DraftWorkspaceIndex: Codable, Equatable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int
    var workspace: ScriptWorkspace
    var pageReferences: [UUID: DraftPageReference]
    var updatedAt: Date

    init(
        workspace: ScriptWorkspace,
        pageReferences: [UUID: DraftPageReference],
        updatedAt: Date = Date(),
        schemaVersion: Int = DraftWorkspaceIndex.currentSchemaVersion
    ) {
        self.workspace = workspace
        self.pageReferences = pageReferences
        self.updatedAt = updatedAt
        self.schemaVersion = schemaVersion
    }
}

struct DraftPageDocument: Codable, Equatable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int
    var pageID: UUID
    var module: PageModule
    var page: ScriptPage
    var updatedAt: Date

    init(
        page: ScriptPage,
        module: PageModule,
        updatedAt: Date = Date(),
        schemaVersion: Int = DraftPageDocument.currentSchemaVersion
    ) {
        self.pageID = page.id
        self.module = module
        self.page = page
        self.updatedAt = updatedAt
        self.schemaVersion = schemaVersion
    }
}

final class DraftFileStore {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private let baseURL: URL
    private let livePagesURL: URL
    private let archivePagesURL: URL
    private let indexURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ??
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents", isDirectory: true)
        self.baseURL = documentsURL.appendingPathComponent("FocusCue", isDirectory: true)
        self.livePagesURL = baseURL.appendingPathComponent("LiveTranscripts", isDirectory: true)
        self.archivePagesURL = baseURL.appendingPathComponent("Archive", isDirectory: true)
        self.indexURL = baseURL.appendingPathComponent("workspace.index.json", isDirectory: false)
    }

    func restoreIndex() -> DraftWorkspaceIndex? {
        guard let data = try? Data(contentsOf: indexURL) else { return nil }
        guard let decoded = try? decoder.decode(DraftWorkspaceIndex.self, from: data) else { return nil }
        guard decoded.schemaVersion == DraftWorkspaceIndex.currentSchemaVersion else { return nil }
        return decoded
    }

    func saveIndex(workspace: ScriptWorkspace, pageReferences: [UUID: DraftPageReference]) throws {
        try ensureBaseDirectories()
        let payload = DraftWorkspaceIndex(workspace: workspace, pageReferences: pageReferences)
        let data = try encoder.encode(payload)
        try data.write(to: indexURL, options: .atomic)
    }

    func savePage(
        _ page: ScriptPage,
        module: PageModule,
        digest: String,
        existingReference: DraftPageReference?
    ) throws -> DraftPageReference {
        try ensureBaseDirectories()
        let destinationURL = pageFileURL(pageID: page.id, module: module)
        try ensureDirectory(destinationURL.deletingLastPathComponent())

        if let existingReference {
            let existingURL = absoluteURL(forRelativePath: existingReference.relativePath)
            if existingURL.standardizedFileURL != destinationURL.standardizedFileURL,
               fileManager.fileExists(atPath: existingURL.path) {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: existingURL, to: destinationURL)
            }
        }

        let payload = DraftPageDocument(page: page, module: module)
        let data = try encoder.encode(payload)
        try data.write(to: destinationURL, options: .atomic)

        return DraftPageReference(
            relativePath: relativePath(forAbsoluteURL: destinationURL),
            savedDigest: digest
        )
    }

    func relocatePageFileIfNeeded(
        pageID: UUID,
        module: PageModule,
        reference: DraftPageReference
    ) throws -> DraftPageReference {
        try ensureBaseDirectories()
        let sourceURL = absoluteURL(forRelativePath: reference.relativePath)
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            return reference
        }

        let destinationURL = pageFileURL(pageID: pageID, module: module)
        guard sourceURL.standardizedFileURL != destinationURL.standardizedFileURL else {
            return reference
        }

        try ensureDirectory(destinationURL.deletingLastPathComponent())
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: sourceURL, to: destinationURL)

        return DraftPageReference(
            relativePath: relativePath(forAbsoluteURL: destinationURL),
            savedDigest: reference.savedDigest
        )
    }

    func trashPageFile(reference: DraftPageReference) throws {
        let fileURL = absoluteURL(forRelativePath: reference.relativePath)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        _ = try fileManager.trashItem(at: fileURL, resultingItemURL: nil)
    }

    // MARK: - Paths

    private func ensureBaseDirectories() throws {
        try ensureDirectory(baseURL)
        try ensureDirectory(livePagesURL)
        try ensureDirectory(archivePagesURL)
    }

    private func ensureDirectory(_ url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func pageFileURL(pageID: UUID, module: PageModule) -> URL {
        let fileName = "\(pageID.uuidString).focuscuepage.json"
        switch module {
        case .liveTranscripts:
            return livePagesURL.appendingPathComponent(fileName, isDirectory: false)
        case .archive:
            return archivePagesURL.appendingPathComponent(fileName, isDirectory: false)
        }
    }

    private func relativePath(forAbsoluteURL url: URL) -> String {
        let basePath = baseURL.standardizedFileURL.path
        let fullPath = url.standardizedFileURL.path
        guard fullPath.hasPrefix(basePath) else {
            return url.lastPathComponent
        }
        var relative = String(fullPath.dropFirst(basePath.count))
        if relative.hasPrefix("/") {
            relative.removeFirst()
        }
        return relative
    }

    private func absoluteURL(forRelativePath path: String) -> URL {
        baseURL.appendingPathComponent(path, isDirectory: false)
    }
}
