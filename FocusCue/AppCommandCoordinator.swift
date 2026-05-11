//
//  AppCommandCoordinator.swift
//  FocusCue
//

import Foundation

@MainActor
@Observable
final class AppCommandCoordinator {
    static let shared = AppCommandCoordinator()

    enum Command: Equatable {
        case openSettings
    }

    private(set) var pendingCommands: [Command] = []
    private(set) var enqueueCount: Int = 0

    func enqueueOpenSettings() {
        pendingCommands.append(.openSettings)
        enqueueCount &+= 1
    }

    func drainCommands() -> [Command] {
        let drained = pendingCommands
        pendingCommands.removeAll()
        return drained
    }
}
