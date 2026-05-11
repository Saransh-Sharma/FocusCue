//
//  AppModalCoordinator.swift
//  FocusCue
//

import Foundation

@MainActor
@Observable
final class AppModalCoordinator {
    enum Route: Equatable, Identifiable {
        case draft
        case settings(initialTab: SettingsTab, launchedFromOnboarding: Bool)
        case about

        var id: String {
            switch self {
            case .draft:
                return "draft"
            case .settings(let initialTab, let launchedFromOnboarding):
                return "settings-\(initialTab.rawValue)-\(launchedFromOnboarding)"
            case .about:
                return "about"
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
