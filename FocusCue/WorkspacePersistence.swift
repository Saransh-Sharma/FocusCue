//
//  WorkspacePersistence.swift
//  FocusCue
//

import Foundation

final class WorkspacePersistence {
    static let autosaveKey = "focuscue.workspace.v3"

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var pendingSave: DispatchWorkItem?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        self.decoder = JSONDecoder()
    }

    deinit {
        pendingSave?.cancel()
    }

    func restoreWorkspace() -> ScriptWorkspace? {
        guard let data = defaults.data(forKey: Self.autosaveKey) else {
            return nil
        }

        do {
            let document = try decoder.decode(FocusCueDocumentV3.self, from: data)
            guard document.schemaVersion == FocusCueDocumentV3.currentSchemaVersion else {
                return nil
            }
            return document.workspace
        } catch {
            return nil
        }
    }

    func scheduleSave(workspace: ScriptWorkspace, delay: TimeInterval = 0.35) {
        pendingSave?.cancel()
        let snapshot = workspace

        let item = DispatchWorkItem { [weak self] in
            self?.saveImmediately(workspace: snapshot)
        }
        pendingSave = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func saveImmediately(workspace: ScriptWorkspace) {
        do {
            let payload = FocusCueDocumentV3(workspace: workspace)
            let data = try encoder.encode(payload)
            defaults.set(data, forKey: Self.autosaveKey)
        } catch {
            // Persistence should never interrupt the editing flow.
        }
    }
}
