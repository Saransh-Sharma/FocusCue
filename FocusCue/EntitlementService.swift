//
//  EntitlementService.swift
//  FocusCue
//

import Foundation

enum AccessTier: String, Codable {
    case lite
    case trial
    case pro
}

enum FeatureGate: String, CaseIterable, Identifiable {
    case generalAccess
    case multiPageEditing
    case multiPagePlayback
    case autoNextPage
    case wordTracking
    case deepgramBackend
    case smartResync
    case aiRefinement
    case pptxImport
    case fullscreenOverlay
    case externalDisplay
    case browserRemote

    var id: String { rawValue }
}

enum BrandState: Equatable {
    case checking
    case lite
    case proTrial(daysRemaining: Int)
    case pro

    var label: String {
        switch self {
        case .checking:
            return "Checking Access"
        case .lite, .proTrial, .pro:
            return "FocusCue Pro"
        }
    }
}

enum PurchaseAuthorityState: Equatable {
    case loading
    case notPurchased
    case purchased(verifiedAt: Date)
}

enum ProtectedSessionKind: Hashable {
    case playback
}

enum AccessDecision: Equatable {
    case allowed
    case blocked(FeatureGate)
}

enum PageOperation: Equatable {
    case view
    case activateInLite
    case editText
    case rename
    case save
    case delete
    case reorder
    case moveBetweenSections
}

struct EntitlementSnapshot {
    var tier: AccessTier
    var hasLifetimePurchase: Bool
    var trialStartedAt: Date?
    var trialEndsAt: Date?
    var isTrialActive: Bool
    var daysRemaining: Int
    var liteUnlockedPageID: UUID?
    var lastVerifiedPurchaseAt: Date?
}

@MainActor
@Observable
final class EntitlementService {
    static let shared = EntitlementService()

    private(set) var purchaseAuthorityState: PurchaseAuthorityState = .purchased(verifiedAt: Date())

    var liteUnlockedPageID: UUID?
    var shouldPresentDowngradeNotice = false
    var isPurchasing = false
    var isRestoring = false
    var storeErrorMessage: String?

    var hasResolvedPurchaseState: Bool { true }
    var isCheckingAccess: Bool { false }
    var hasLifetimePurchase: Bool { true }
    var hasStartedTrial: Bool { false }
    var isEligibleForTrial: Bool { false }
    var hasExpiredPriorTrial: Bool { false }
    var isTrialActive: Bool { false }
    var hasProAccess: Bool { true }
    var tier: AccessTier { .pro }
    var daysRemaining: Int { 0 }
    var daysUsed: Int { 0 }
    var brandState: BrandState { .pro }
    var brandLabel: String { brandState.label }
    var statusHeadline: String { "FocusCue Pro is enabled" }
    var statusDetail: String { "All teleprompter workflows are included." }
    var statusFootnote: String { "Every FocusCue Pro feature is available by default." }

    var snapshot: EntitlementSnapshot {
        EntitlementSnapshot(
            tier: tier,
            hasLifetimePurchase: hasLifetimePurchase,
            trialStartedAt: nil,
            trialEndsAt: nil,
            isTrialActive: false,
            daysRemaining: 0,
            liteUnlockedPageID: nil,
            lastVerifiedPurchaseAt: nil
        )
    }

    func handleAppLaunch() {
        refreshPresentationState()
    }

    func bootstrapStoreState() async {
        refreshPresentationState()
    }

    func has(_ feature: FeatureGate) -> Bool {
        decision(for: feature) == .allowed
    }

    func decision(for feature: FeatureGate) -> AccessDecision {
        let _ = feature
        return .allowed
    }

    func canEnable(_ feature: FeatureGate) -> Bool {
        has(feature)
    }

    func availableListeningModes(current: ListeningMode) -> [ListeningMode] {
        let _ = current
        return ListeningMode.allCases
    }

    func availableSpeechBackends(current: SpeechBackend) -> [SpeechBackend] {
        let _ = current
        return SpeechBackend.allCases
    }

    func refreshPresentationState() {
        shouldPresentDowngradeNotice = false
    }

    @discardableResult
    func startTrialIfNeeded() -> Bool {
        false
    }

    func dismissDowngradeNotice() {
        shouldPresentDowngradeNotice = false
    }

    func beginProtectedSession(_ kind: ProtectedSessionKind) {
        let _ = kind
    }

    func endProtectedSession(_ kind: ProtectedSessionKind) {
        let _ = kind
    }

    func syncLiteUnlockedPage(with workspace: ScriptWorkspace) {
        let _ = workspace
        liteUnlockedPageID = nil
    }

    func makeLitePageActive(_ pageID: UUID, in workspace: ScriptWorkspace) {
        let _ = pageID
        let _ = workspace
    }

    func canPerform(_ operation: PageOperation, on pageID: UUID?, in workspace: ScriptWorkspace) -> Bool {
        let _ = operation
        guard let pageID else { return false }
        return (workspace.livePages + workspace.archivePages).contains { $0.id == pageID }
    }

    func canEditPage(_ pageID: UUID?, in workspace: ScriptWorkspace) -> Bool {
        canPerform(.editText, on: pageID, in: workspace)
    }

    func canPlayMultiplePages(in workspace: ScriptWorkspace) -> Bool {
        let _ = workspace
        return true
    }

func enforceAllowedSettings() {}
}
