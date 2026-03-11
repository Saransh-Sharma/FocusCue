enum DistributionFeatures {
#if APP_STORE_BUILD
    static let isAppStoreBuild = true
#else
    static let isAppStoreBuild = false
#endif

    static let externalUpdaterEnabled = !isAppStoreBuild
    static let cloudSpeechEnabled = !isAppStoreBuild
    static let openAIFeaturesEnabled = !isAppStoreBuild
    static let browserRemoteEnabled = true

    static var speechBackendSelectionVisible: Bool { cloudSpeechEnabled }
    static var providerKeysVisible: Bool { cloudSpeechEnabled || openAIFeaturesEnabled }
    static var smartResyncVisible: Bool { openAIFeaturesEnabled }
    static var aiDraftRefinementVisible: Bool { openAIFeaturesEnabled }

    static func allows(_ feature: FeatureGate) -> Bool {
        switch feature {
        case .deepgramBackend:
            return cloudSpeechEnabled
        case .smartResync, .aiRefinement:
            return openAIFeaturesEnabled
        case .browserRemote:
            return browserRemoteEnabled
        default:
            return true
        }
    }
}
