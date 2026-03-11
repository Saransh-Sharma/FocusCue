//
//  EntitlementService.swift
//  FocusCue
//

import Foundation
import StoreKit

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
            return "Checking Pro Access"
        case .lite:
            return "FocusCue Lite"
        case .proTrial:
            return "FocusCue Pro Trial"
        case .pro:
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

struct VerifiedPurchaseRecord: Equatable {
    var productID: String
    var revocationDate: Date?
}

protocol PurchaseEntitlementProviding {
    nonisolated func currentEntitlements() async -> [VerifiedPurchaseRecord]
    nonisolated func sync() async throws
}

protocol DateProviding {
    nonisolated var now: Date { get }
}

struct SystemDateProvider: DateProviding {
    nonisolated var now: Date { Date() }
}

struct StoreKitPurchaseEntitlementProvider: PurchaseEntitlementProviding {
    nonisolated func currentEntitlements() async -> [VerifiedPurchaseRecord] {
        var records: [VerifiedPurchaseRecord] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            records.append(
                VerifiedPurchaseRecord(
                    productID: transaction.productID,
                    revocationDate: transaction.revocationDate
                )
            )
        }
        return records
    }

    nonisolated func sync() async throws {
        try await AppStore.sync()
    }
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

enum StoreProductIDs {
    // Must match App Store Connect and FocusCue/StoreKit/FocusCue.storekit.
    static let lifetimeProUnlock = "com.saransh1337.focuscue.pro.lifetime.teleprompter"
}

@MainActor
@Observable
final class EntitlementService {
    static let shared = EntitlementService(
        purchaseProvider: StoreKitPurchaseEntitlementProvider(),
        dateProvider: SystemDateProvider()
    )

    let lifetimeProductID = StoreProductIDs.lifetimeProUnlock

    private let trialStartedAtKey = "focuscue.entitlement.trialStartedAt"
    private let trialEndsAtKey = "focuscue.entitlement.trialEndsAt"
    private let obsoleteHasLifetimePurchaseKey = "focuscue.entitlement.hasLifetimePurchase"
    private let liteUnlockedPageIDKey = "focuscue.entitlement.liteUnlockedPageID"
    private let lastVerifiedPurchaseAtKey = "focuscue.entitlement.lastVerifiedPurchaseAt"
    private let downgradeNoticeDismissedKey = "focuscue.entitlement.downgradeNoticeDismissed"
    private let trialDuration: TimeInterval = 14 * 24 * 60 * 60

    private let purchaseProvider: PurchaseEntitlementProviding
    private let dateProvider: DateProviding

    private(set) var purchaseAuthorityState: PurchaseAuthorityState

    var trialStartedAt: Date? {
        didSet {
            UserDefaults.standard.set(trialStartedAt, forKey: trialStartedAtKey)
        }
    }

    var trialEndsAt: Date? {
        didSet {
            UserDefaults.standard.set(trialEndsAt, forKey: trialEndsAtKey)
        }
    }

    var liteUnlockedPageID: UUID? {
        didSet {
            UserDefaults.standard.set(liteUnlockedPageID?.uuidString, forKey: liteUnlockedPageIDKey)
        }
    }

    var lastVerifiedPurchaseAt: Date? {
        didSet {
            UserDefaults.standard.set(lastVerifiedPurchaseAt, forKey: lastVerifiedPurchaseAtKey)
        }
    }

    var shouldPresentDowngradeNotice = false
    var isPurchasing = false
    var isRestoring = false
    var storeErrorMessage: String?
    private(set) var proProduct: Product?

    private var transactionUpdatesTask: Task<Void, Never>?
    private var protectedSessions: Set<ProtectedSessionKind> = []
    private var hasDeferredPostSessionRefresh = false
    private var hasStartedBootstrap = false

    init(
        purchaseProvider: PurchaseEntitlementProviding,
        dateProvider: DateProviding,
        startObservingTransactions: Bool = true
    ) {
        self.purchaseProvider = purchaseProvider
        self.dateProvider = dateProvider
        self.purchaseAuthorityState = .loading
        self.trialStartedAt = UserDefaults.standard.object(forKey: trialStartedAtKey) as? Date
        self.trialEndsAt = UserDefaults.standard.object(forKey: trialEndsAtKey) as? Date
        if let rawPageID = UserDefaults.standard.string(forKey: liteUnlockedPageIDKey) {
            self.liteUnlockedPageID = UUID(uuidString: rawPageID)
        } else {
            self.liteUnlockedPageID = nil
        }
        self.lastVerifiedPurchaseAt = UserDefaults.standard.object(forKey: lastVerifiedPurchaseAtKey) as? Date

        UserDefaults.standard.removeObject(forKey: obsoleteHasLifetimePurchaseKey)

        if startObservingTransactions {
            transactionUpdatesTask = Task { [weak self] in
                await self?.observeTransactionUpdates()
            }
        }
    }

    @MainActor
    deinit {
        transactionUpdatesTask?.cancel()
    }

    var hasResolvedPurchaseState: Bool {
        if case .loading = purchaseAuthorityState {
            return false
        }
        return true
    }

    var isCheckingAccess: Bool {
        !hasResolvedPurchaseState
    }

    var hasLifetimePurchase: Bool {
        if case .purchased = purchaseAuthorityState {
            return true
        }
        return false
    }

    var hasStartedTrial: Bool {
        trialStartedAt != nil
    }

    var isEligibleForTrial: Bool {
        !hasLifetimePurchase && !hasStartedTrial
    }

    var hasExpiredPriorTrial: Bool {
        hasStartedTrial && !isTrialActive && !hasLifetimePurchase
    }

    var isTrialActive: Bool {
        guard !hasLifetimePurchase, let trialEndsAt else { return false }
        return dateProvider.now < trialEndsAt
    }

    var hasProAccess: Bool {
        hasLifetimePurchase || isTrialActive
    }

    var tier: AccessTier {
        if hasLifetimePurchase {
            return .pro
        }
        if isTrialActive {
            return .trial
        }
        return .lite
    }

    var daysRemaining: Int {
        guard isTrialActive, let trialEndsAt else { return 0 }
        let secondsRemaining = max(0, trialEndsAt.timeIntervalSince(dateProvider.now))
        return min(14, max(1, Int(ceil(secondsRemaining / 86_400))))
    }

    var daysUsed: Int {
        guard hasStartedTrial else { return 0 }
        return min(14, max(0, 14 - daysRemaining))
    }

    var brandState: BrandState {
        guard hasResolvedPurchaseState else { return .checking }
        switch tier {
        case .lite:
            return .lite
        case .trial:
            return .proTrial(daysRemaining: daysRemaining)
        case .pro:
            return .pro
        }
    }

    var brandLabel: String {
        brandState.label
    }

    var statusHeadline: String {
        guard hasResolvedPurchaseState else { return "Checking Pro access…" }
        switch tier {
        case .lite:
            return "You’re in FocusCue Lite"
        case .trial:
            return "Your full Pro trial is active"
        case .pro:
            return "FocusCue Pro is unlocked"
        }
    }

    var statusDetail: String {
        guard hasResolvedPurchaseState else { return "Verifying purchases on this Apple ID." }
        switch tier {
        case .lite:
            return "Single-page prompting is available. Upgrade for unlimited scripts, remote output, and Pro guidance."
        case .trial:
            return "\(daysUsed) of 14 days used"
        case .pro:
            if let proProduct {
                return "Lifetime unlock active (\(proProduct.displayPrice))"
            }
            return "Lifetime unlock active"
        }
    }

    var statusFootnote: String {
        guard hasResolvedPurchaseState else { return "Core editing stays available while FocusCue verifies your receipt." }
        switch tier {
        case .lite:
            return "Lite keeps one page editable and playable while the rest of your script stays visible."
        case .trial:
            return daysRemaining == 1 ? "1 day remaining." : "\(daysRemaining) days remaining."
        case .pro:
            return "All Pro features are available on this Apple ID."
        }
    }

    var snapshot: EntitlementSnapshot {
        EntitlementSnapshot(
            tier: tier,
            hasLifetimePurchase: hasLifetimePurchase,
            trialStartedAt: trialStartedAt,
            trialEndsAt: trialEndsAt,
            isTrialActive: isTrialActive,
            daysRemaining: daysRemaining,
            liteUnlockedPageID: liteUnlockedPageID,
            lastVerifiedPurchaseAt: lastVerifiedPurchaseAt
        )
    }

    func handleAppLaunch() {
        guard !hasStartedBootstrap else {
            refreshPresentationState()
            return
        }
        hasStartedBootstrap = true
        Task { [weak self] in
            await self?.bootstrapStoreState()
        }
    }

    func bootstrapStoreState() async {
        do {
            let products = try await Product.products(for: [lifetimeProductID])
            proProduct = products.first
        } catch {
            storeErrorMessage = error.localizedDescription
        }

        await refreshPurchasedState()
        enforceAllowedSettings()
        refreshPresentationState()
    }

    func has(_ feature: FeatureGate) -> Bool {
        decision(for: feature) == .allowed
    }

    func decision(for feature: FeatureGate) -> AccessDecision {
        guard DistributionFeatures.allows(feature) else { return .blocked(feature) }
        guard hasResolvedPurchaseState else { return .blocked(feature) }
        if hasProAccess {
            return .allowed
        }

        switch feature {
        case .generalAccess:
            return .allowed
        case .multiPageEditing, .multiPagePlayback, .autoNextPage, .wordTracking,
             .deepgramBackend, .smartResync, .aiRefinement, .pptxImport,
             .fullscreenOverlay, .externalDisplay, .browserRemote:
            return .blocked(feature)
        }
    }

    func canEnable(_ feature: FeatureGate) -> Bool {
        has(feature)
    }

    func availableListeningModes(current: ListeningMode) -> [ListeningMode] {
        guard hasResolvedPurchaseState else {
            return ListeningMode.allCases
        }
        if has(.wordTracking) || current == .wordTracking {
            return ListeningMode.allCases
        }
        return ListeningMode.allCases.filter { $0 != .wordTracking }
    }

    func availableSpeechBackends(current: SpeechBackend) -> [SpeechBackend] {
        guard DistributionFeatures.cloudSpeechEnabled else {
            let _ = current
            return [.apple]
        }
        guard hasResolvedPurchaseState else {
            return SpeechBackend.allCases
        }
        if has(.deepgramBackend) || current == .deepgram {
            return SpeechBackend.allCases
        }
        return SpeechBackend.allCases.filter { $0 != .deepgram }
    }

    func refreshPresentationState() {
        guard hasResolvedPurchaseState else {
            shouldPresentDowngradeNotice = false
            return
        }

        let shouldShowExpiredTrialNotice = !hasLifetimePurchase && hasStartedTrial && !isTrialActive
        if shouldShowExpiredTrialNotice && !protectedSessions.isEmpty {
            hasDeferredPostSessionRefresh = true
            shouldPresentDowngradeNotice = false
            return
        }

        let hasDismissedNotice = UserDefaults.standard.bool(forKey: downgradeNoticeDismissedKey)
        shouldPresentDowngradeNotice = shouldShowExpiredTrialNotice && !hasDismissedNotice
    }

    @discardableResult
    func startTrialIfNeeded() -> Bool {
        guard hasResolvedPurchaseState else { return false }
        guard !hasLifetimePurchase, trialStartedAt == nil else { return false }
        let now = dateProvider.now
        trialStartedAt = now
        trialEndsAt = now.addingTimeInterval(trialDuration)
        UserDefaults.standard.set(false, forKey: downgradeNoticeDismissedKey)
        shouldPresentDowngradeNotice = false
        return true
    }

    func dismissDowngradeNotice() {
        shouldPresentDowngradeNotice = false
        UserDefaults.standard.set(true, forKey: downgradeNoticeDismissedKey)
        if protectedSessions.isEmpty {
            enforceAllowedSettings()
        } else {
            hasDeferredPostSessionRefresh = true
        }
    }

    func beginProtectedSession(_ kind: ProtectedSessionKind) {
        protectedSessions.insert(kind)
    }

    func endProtectedSession(_ kind: ProtectedSessionKind) {
        protectedSessions.remove(kind)
        guard protectedSessions.isEmpty else { return }

        if hasDeferredPostSessionRefresh {
            hasDeferredPostSessionRefresh = false
            refreshPresentationState()
            enforceAllowedSettings()
        }
    }

    func syncLiteUnlockedPage(with workspace: ScriptWorkspace) {
        guard hasResolvedPurchaseState else { return }

        let validPageIDs = Set((workspace.livePages + workspace.archivePages).map(\.id))
        if validPageIDs.isEmpty {
            liteUnlockedPageID = nil
            return
        }

        if tier != .lite {
            if let liteUnlockedPageID, !validPageIDs.contains(liteUnlockedPageID) {
                self.liteUnlockedPageID = nil
            }
            return
        }

        if let liteUnlockedPageID, validPageIDs.contains(liteUnlockedPageID) {
            return
        }

        self.liteUnlockedPageID = workspace.selectedPageID ?? workspace.livePages.first?.id ?? workspace.archivePages.first?.id
    }

    func makeLitePageActive(_ pageID: UUID, in workspace: ScriptWorkspace) {
        let validPageIDs = Set((workspace.livePages + workspace.archivePages).map(\.id))
        guard validPageIDs.contains(pageID) else { return }
        guard canPerform(.activateInLite, on: pageID, in: workspace) else { return }
        liteUnlockedPageID = pageID
    }

    func canPerform(_ operation: PageOperation, on pageID: UUID?, in workspace: ScriptWorkspace) -> Bool {
        guard hasResolvedPurchaseState else { return false }
        guard let pageID else { return false }

        let validPageIDs = Set((workspace.livePages + workspace.archivePages).map(\.id))
        guard validPageIDs.contains(pageID) else { return false }

        if hasProAccess {
            return true
        }

        syncLiteUnlockedPage(with: workspace)
        let isSinglePageWorkspace = validPageIDs.count <= 1

        if isSinglePageWorkspace {
            switch operation {
            case .view, .activateInLite, .editText, .rename, .save:
                return true
            case .delete:
                return true
            case .reorder, .moveBetweenSections:
                return false
            }
        }

        switch operation {
        case .view, .activateInLite:
            return true
        case .editText, .rename, .save:
            return liteUnlockedPageID == pageID
        case .delete, .reorder, .moveBetweenSections:
            return false
        }
    }

    func canEditPage(_ pageID: UUID?, in workspace: ScriptWorkspace) -> Bool {
        canPerform(.editText, on: pageID, in: workspace)
    }

    func canPlayMultiplePages(in workspace: ScriptWorkspace) -> Bool {
        let _ = workspace
        return has(.multiPagePlayback)
    }

    func enforceAllowedSettings() {
        let settings = NotchSettings.shared

        if !DistributionFeatures.cloudSpeechEnabled, settings.speechBackend != .apple {
            settings.speechBackend = .apple
        }
        if !DistributionFeatures.openAIFeaturesEnabled, settings.llmResyncEnabled {
            settings.llmResyncEnabled = false
        }
        if !DistributionFeatures.browserRemoteEnabled, settings.browserServerEnabled {
            settings.browserServerEnabled = false
        }

        guard hasResolvedPurchaseState else { return }
        guard !hasProAccess else { return }

        if settings.listeningMode == .wordTracking {
            settings.listeningMode = .silencePaused
        }
        if settings.speechBackend == .deepgram {
            settings.speechBackend = .apple
        }
        if settings.llmResyncEnabled {
            settings.llmResyncEnabled = false
        }
        if settings.overlayMode == .fullscreen {
            settings.overlayMode = .floating
        }
        if settings.externalDisplayMode != .off {
            settings.externalDisplayMode = .off
        }
        if settings.browserServerEnabled {
            settings.browserServerEnabled = false
        }
        if settings.autoNextPage {
            settings.autoNextPage = false
        }
    }

    @discardableResult
    func purchaseLifetimeUnlock() async -> Bool {
        storeErrorMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }

        if proProduct == nil {
            do {
                let products = try await Product.products(for: [lifetimeProductID])
                proProduct = products.first
            } catch {
                storeErrorMessage = error.localizedDescription
            }
        }

        guard let proProduct else {
            storeErrorMessage = "The Pro unlock is currently unavailable. Please try again in a few minutes."
            return false
        }

        do {
            let result = try await proProduct.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await handleVerifiedTransaction(transaction, finishTransaction: true)
                    return hasLifetimePurchase
                case .unverified(_, let error):
                    storeErrorMessage = error.localizedDescription
                }
            case .userCancelled:
                return false
            case .pending:
                storeErrorMessage = "Purchase is pending approval."
            @unknown default:
                storeErrorMessage = "Purchase could not be completed."
            }
        } catch {
            storeErrorMessage = error.localizedDescription
        }

        return false
    }

    func restorePurchases() async {
        storeErrorMessage = nil
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await purchaseProvider.sync()
            await refreshPurchasedState()
        } catch {
            storeErrorMessage = error.localizedDescription
        }
    }

    private func refreshPurchasedState() async {
        let now = dateProvider.now
        let records = await purchaseProvider.currentEntitlements()
        let purchased = records.contains { $0.productID == lifetimeProductID && $0.revocationDate == nil }

        if purchased {
            lastVerifiedPurchaseAt = now
            purchaseAuthorityState = .purchased(verifiedAt: now)
            UserDefaults.standard.set(true, forKey: downgradeNoticeDismissedKey)
            shouldPresentDowngradeNotice = false
        } else {
            purchaseAuthorityState = .notPurchased
            applyPostPurchaseStateChange()
        }
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await handleVerifiedTransaction(transaction, finishTransaction: true)
        }
    }

    private func handleVerifiedTransaction(_ transaction: Transaction, finishTransaction: Bool) async {
        guard transaction.productID == lifetimeProductID else {
            if finishTransaction {
                await transaction.finish()
            }
            return
        }

        let now = dateProvider.now
        if transaction.revocationDate == nil {
            purchaseAuthorityState = .purchased(verifiedAt: now)
            lastVerifiedPurchaseAt = now
            UserDefaults.standard.set(true, forKey: downgradeNoticeDismissedKey)
            shouldPresentDowngradeNotice = false
        } else {
            purchaseAuthorityState = .notPurchased
            applyPostPurchaseStateChange()
        }

        storeErrorMessage = nil
        if protectedSessions.isEmpty {
            enforceAllowedSettings()
        } else {
            hasDeferredPostSessionRefresh = true
        }

        if finishTransaction {
            await transaction.finish()
        }
    }

    private func applyPostPurchaseStateChange() {
        if protectedSessions.isEmpty {
            refreshPresentationState()
            enforceAllowedSettings()
        } else {
            hasDeferredPostSessionRefresh = true
            shouldPresentDowngradeNotice = false
        }
    }
}
