//
//  AppModalCoordinator.swift
//  FocusCue
//

import Foundation

enum ProUnlockSource: Equatable {
    case purchase
    case restore
}

enum TrialEntryAction: Equatable {
    case startSequence
    case openDraft
}

@MainActor
@Observable
final class AppModalCoordinator {
    enum Route: Equatable, Identifiable {
        case draft
        case settings(initialTab: SettingsTab, launchedFromOnboarding: Bool)
        case about
        case paywall(feature: FeatureGate)
        case trialOffer(action: TrialEntryAction)
        case proUnlocked(source: ProUnlockSource)
        case litePageAccess(pageID: UUID)
        case downgrade

        var id: String {
            switch self {
            case .draft:
                return "draft"
            case .settings(let initialTab, let launchedFromOnboarding):
                return "settings-\(initialTab.rawValue)-\(launchedFromOnboarding)"
            case .about:
                return "about"
            case .paywall(let feature):
                return "paywall-\(feature.rawValue)"
            case .trialOffer(let action):
                switch action {
                case .startSequence:
                    return "trial-start-sequence"
                case .openDraft:
                    return "trial-open-draft"
                }
            case .proUnlocked(let source):
                switch source {
                case .purchase:
                    return "pro-unlocked-purchase"
                case .restore:
                    return "pro-unlocked-restore"
                }
            case .litePageAccess(let pageID):
                return "lite-page-\(pageID.uuidString)"
            case .downgrade:
                return "downgrade"
            }
        }
    }

    private(set) var stack: [Route] = []

    var activeRoute: Route? {
        stack.last
    }

    func present(_ route: Route) {
        stack = [route]
    }

    func push(_ route: Route) {
        if stack.isEmpty {
            stack = [route]
        } else {
            stack.append(route)
        }
    }

    func replaceTop(with route: Route) {
        if stack.isEmpty {
            stack = [route]
            return
        }
        stack[stack.count - 1] = route
    }

    func pop() {
        guard !stack.isEmpty else { return }
        stack.removeLast()
    }

    func popToRoot() {
        guard let root = stack.first else { return }
        stack = [root]
    }

    func clear() {
        stack.removeAll()
    }
}
