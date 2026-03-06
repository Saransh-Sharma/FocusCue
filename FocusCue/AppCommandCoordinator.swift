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
        case presentPaywall(FeatureGate)
        case restorePurchases
    }

    private(set) var pendingCommands: [Command] = []
    private(set) var enqueueCount: Int = 0

    func enqueuePresentPaywall(feature: FeatureGate) {
        pendingCommands.append(.presentPaywall(feature))
        enqueueCount &+= 1
    }

    func enqueueRestorePurchases() {
        pendingCommands.append(.restorePurchases)
        enqueueCount &+= 1
    }

    func drainCommands() -> [Command] {
        let drained = pendingCommands
        pendingCommands.removeAll()
        return drained
    }
}
