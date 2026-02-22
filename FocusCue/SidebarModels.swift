//
//  SidebarModels.swift
//  FocusCue
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct FocusCueDocumentV3: Codable, Equatable {
    static let currentSchemaVersion = 3

    var schemaVersion: Int
    var workspace: ScriptWorkspace

    init(workspace: ScriptWorkspace, schemaVersion: Int = FocusCueDocumentV3.currentSchemaVersion) {
        self.schemaVersion = schemaVersion
        self.workspace = workspace
    }
}

enum PageModule: String, Codable, CaseIterable {
    case liveTranscripts
    case archive
}

struct ScriptWorkspace: Codable, Equatable {
    var livePages: [ScriptPage]
    var archivePages: [ScriptPage]
    var selectedPageID: UUID?
    var nextPageCounter: Int

    static func makeDefault() -> ScriptWorkspace {
        let firstPage = ScriptPage(
            id: UUID(),
            title: "Page 1",
            text: "",
            isCustomTitle: false
        )
        return ScriptWorkspace(
            livePages: [firstPage],
            archivePages: [],
            selectedPageID: firstPage.id,
            nextPageCounter: 2
        )
    }
}

struct ScriptPage: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var text: String
    var isCustomTitle: Bool
}

enum SidebarSectionKind: Equatable {
    case liveTranscripts
    case archive
}

struct SidebarPageRowModel: Identifiable, Equatable {
    var id: UUID
    var module: PageModule
    var localIndex: Int
    var displayTitle: String
    var baseTitle: String
    var preview: String
    var isRead: Bool
    var isSelected: Bool
    var needsSave: Bool
    var saveFailed: Bool
}

struct SidebarSectionModel: Identifiable, Equatable {
    var kind: SidebarSectionKind
    var title: String
    var subtitle: String
    var pages: [SidebarPageRowModel]

    var id: String {
        switch kind {
        case .liveTranscripts:
            return "live-transcripts"
        case .archive:
            return "archive"
        }
    }

    var module: PageModule {
        switch kind {
        case .liveTranscripts:
            return .liveTranscripts
        case .archive:
            return .archive
        }
    }
}

enum SidebarDragItemKind: String, Codable {
    case page
}

struct SidebarDragPayload: Codable, Equatable, Transferable {
    var kind: SidebarDragItemKind
    var id: UUID
    var sourceModule: PageModule

    static func page(_ id: UUID, sourceModule: PageModule) -> SidebarDragPayload {
        SidebarDragPayload(kind: .page, id: id, sourceModule: sourceModule)
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .focusCueSidebarPayload)
    }
}

extension UTType {
    static let focusCueSidebarPayload = UTType(exportedAs: "com.saransh1337.focuscue.sidebar-payload")
}
