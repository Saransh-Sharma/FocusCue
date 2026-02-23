//
//  SettingsView.swift
//  FocusCue
//
//  Created by Fatih Kadir Akın on 8.02.2026.
//

import SwiftUI
import AppKit
import Speech
import Combine
import CoreImage.CIFilterBuiltins

// MARK: - Preview Panel Controller

class NotchPreviewController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<NotchPreviewContent>?
    private var originalFrame: NSRect?
    private var cursorTimer: AnyCancellable?
    private var trackingSettings: NotchSettings?

    func show(settings: NotchSettings) {
        // If panel already exists, just re-show it
        if let panel {
            panel.orderFront(nil)
            return
        }

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let menuBarHeight = screenFrame.maxY - visibleFrame.maxY

        let maxWidth = NotchSettings.maxWidth
        let maxHeight = menuBarHeight + NotchSettings.maxHeight + 40

        let xPosition = screenFrame.midX - maxWidth / 2
        let yPosition = screenFrame.maxY - maxHeight

        let content = NotchPreviewContent(settings: settings, menuBarHeight: menuBarHeight)
        let hostingView = NSHostingView(rootView: content)
        self.hostingView = hostingView

        let panel = NSPanel(
            contentRect: NSRect(x: xPosition, y: yPosition, width: maxWidth, height: maxHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.contentView = hostingView
        panel.orderFront(nil)
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func dismiss() {
        stopCursorTracking()
        panel?.orderOut(nil)
        panel = nil
        hostingView = nil
        originalFrame = nil
    }

    var isAtCursor: Bool { originalFrame != nil }

    func animateToCursor(settings: NotchSettings) {
        guard let panel else { return }
        if originalFrame == nil {
            originalFrame = panel.frame
        }
        trackingSettings = settings

        // Animate to cursor, then start continuous tracking
        let target = cursorFrame(for: panel, settings: settings)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(target, display: true)
        }, completionHandler: { [weak self] in
            self?.startCursorTracking()
        })
    }

    func animateFromCursor() {
        stopCursorTracking()
        guard let panel, let originalFrame else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(originalFrame, display: true)
        }
        self.originalFrame = nil
        self.trackingSettings = nil
    }

    private func cursorFrame(for panel: NSPanel, settings: NotchSettings) -> NSRect {
        let mouse = NSEvent.mouseLocation
        let cursorOffset: CGFloat = 8
        let maxWidth = panel.frame.width
        let notchWidth = settings.notchWidth
        let panelHeight = panel.frame.height

        let panelX = mouse.x + cursorOffset - (maxWidth - notchWidth) / 2
        let panelY = mouse.y + 60 - panelHeight
        return NSRect(x: panelX, y: panelY, width: maxWidth, height: panelHeight)
    }

    private func startCursorTracking() {
        cursorTimer?.cancel()
        cursorTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePreviewPosition()
            }
    }

    private func stopCursorTracking() {
        cursorTimer?.cancel()
        cursorTimer = nil
    }

    private func updatePreviewPosition() {
        guard let panel, let settings = trackingSettings else { return }
        let target = cursorFrame(for: panel, settings: settings)
        panel.setFrame(target, display: false)
    }
}

struct NotchPreviewContent: View {
    @Bindable var settings: NotchSettings
    let menuBarHeight: CGFloat

    private static let loremWords = "Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua Ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur Excepteur sint occaecat cupidatat non proident sunt in culpa qui officia deserunt mollit anim id est laborum Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium totam rem aperiam eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt".split(separator: " ").map(String.init)

    private let highlightedCount = 42
    @State private var previewWordProgress: Double = 0
    private let scrollTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    // Phase 1: corners flatten (0=concave, 1=squared)
    @State private var cornerPhase: CGFloat = 0
    // Phase 2: detach from top (0=stuck to top, 1=moved down + rounded)
    @State private var offsetPhase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let topPadding = menuBarHeight * (1 - offsetPhase) + 14 * offsetPhase
            let contentHeight = topPadding + settings.textAreaHeight
            let currentWidth = settings.notchWidth
            let yOffset = 60 * offsetPhase

            ZStack(alignment: .top) {
                // Shape: concave corners flatten via cornerPhase, then cross-fade to rounded via offsetPhase
                DynamicIslandShape(
                    topInset: 16 * (1 - cornerPhase),
                    bottomRadius: 18
                )
                .fill(.black)
                .opacity(Double(1 - offsetPhase))
                .frame(width: currentWidth, height: contentHeight)

                Group {
                    if settings.floatingGlassEffect {
                        ZStack {
                            GlassEffectView()
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.black.opacity(settings.glassOpacity))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.black)
                    }
                }
                .opacity(Double(offsetPhase))
                .frame(width: currentWidth, height: contentHeight)

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        if settings.showElapsedTime {
                            ElapsedTimeView(fontSize: 11)
                                .padding(.trailing, 12)
                        }
                    }
                    .frame(height: topPadding)

                    SpeechScrollView(
                        words: Self.loremWords,
                        highlightedCharCount: settings.listeningMode == .wordTracking ? highlightedCount : Self.loremWords.count * 5,
                        font: settings.font,
                        highlightColor: settings.fontColorPreset.color,
                        smoothScroll: settings.listeningMode != .wordTracking,
                        smoothWordProgress: previewWordProgress,
                        isListening: settings.listeningMode != .wordTracking
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .frame(width: currentWidth, height: contentHeight)
            }
            .frame(width: currentWidth, height: contentHeight, alignment: .top)
            .offset(y: yOffset)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .animation(.easeInOut(duration: 0.15), value: settings.notchWidth)
            .animation(.easeInOut(duration: 0.15), value: settings.textAreaHeight)
        }
        .onChange(of: settings.overlayMode) { _, mode in
            if mode == .floating {
                // Phase 1: flatten corners while at top
                withAnimation(.easeInOut(duration: 0.25)) {
                    cornerPhase = 1
                }
                // Phase 2: move down + round corners
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        offsetPhase = 1
                    }
                }
            } else {
                // Reverse Phase 1: move back up to top
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    offsetPhase = 0
                }
                // Reverse Phase 2: restore concave corners
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        cornerPhase = 0
                    }
                }
            }
        }
        .onAppear {
            let isFloating = settings.overlayMode == .floating
            cornerPhase = isFloating ? 1 : 0
            offsetPhase = isFloating ? 1 : 0
        }
        .onReceive(scrollTimer) { _ in
            guard settings.listeningMode != .wordTracking else { return }
            let wordCount = Double(Self.loremWords.count)
            previewWordProgress += settings.scrollSpeed * 0.05
            if previewWordProgress >= wordCount {
                previewWordProgress = 0
            }
        }
        .onChange(of: settings.listeningMode) { _, mode in
            if mode != .wordTracking {
                previewWordProgress = 0
            }
        }
    }
}

// MARK: - Settings Tabs

enum SettingsTab: String, CaseIterable, Identifiable {
    case appearance, guidance, teleprompter, external, browser

    var id: String { rawValue }

    var label: String {
        switch self {
        case .appearance: return "Appearance"
        case .guidance: return "Guidance"
        case .teleprompter: return "Teleprompter"
        case .external: return "External"
        case .browser: return "Remote"
        }
    }

    var icon: String {
        switch self {
        case .appearance: return "paintpalette"
        case .guidance: return "waveform"
        case .teleprompter: return "macwindow"
        case .external: return "rectangle.on.rectangle"
        case .browser: return "antenna.radiowaves.left.and.right"
        }
    }

    var accent: FCColorToken {
        switch self {
        case .appearance: return .accentPrimary
        case .guidance: return .accentInfo
        case .teleprompter: return .accentCTA
        case .external: return .stateSuccess
        case .browser: return .accentInfo
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    private enum Layout {
        static let dialogWidth: CGFloat = 640
        static let dialogHeight: CGFloat = 620
    }

    @Bindable var settings: NotchSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var previewController = NotchPreviewController()
    @State private var selectedTab: SettingsTab = .appearance
    @State private var showResetConfirmation = false

    @State private var availableMics: [AudioInputDevice] = []
    @State private var overlayScreens: [NSScreen] = []
    @State private var availableScreens: [NSScreen] = []

    @State private var localIP: String = BrowserServer.localIPAddress() ?? "localhost"
    @State private var showAdvanced: Bool = false
    @State private var browserPortInput: String = ""
    @State private var browserPortValidation: String?

    private var theme: FCTheme {
        FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
    }

    private var browserURL: String {
        "http://\(localIP):\(settings.browserServerPort)"
    }

    var body: some View {
        FCSettingsShell(sidebarWidth: 155) {
            sidebar
        } content: {
            tabContent
        } footer: {
            footer
        }
        .frame(width: Layout.dialogWidth, height: Layout.dialogHeight)
        .alert("Reset All Settings?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                withAnimation(theme.animation(.base)) {
                    resetAllSettings()
                }
            }
        } message: {
            Text("This will restore all settings to their defaults.")
        }
        .onAppear {
            syncDerivedState()
            if settings.overlayMode != .fullscreen {
                previewController.show(settings: settings)
                if settings.followCursorWhenUndocked && settings.overlayMode == .floating {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        previewController.animateToCursor(settings: settings)
                    }
                }
            }
        }
        .onDisappear {
            previewController.dismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            previewController.hide()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            if settings.overlayMode != .fullscreen {
                previewController.show(settings: settings)
                if settings.followCursorWhenUndocked && settings.overlayMode == .floating {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        previewController.animateToCursor(settings: settings)
                    }
                }
            }
        }
        .onChange(of: settings.followCursorWhenUndocked) { _, follow in
            if follow && settings.overlayMode == .floating {
                previewController.animateToCursor(settings: settings)
            } else {
                previewController.animateFromCursor()
            }
        }
        .onChange(of: settings.overlayMode) { _, mode in
            if mode == .fullscreen {
                previewController.hide()
            } else {
                previewController.show(settings: settings)
                if mode == .floating && settings.followCursorWhenUndocked {
                    previewController.animateToCursor(settings: settings)
                } else if previewController.isAtCursor {
                    previewController.animateFromCursor()
                }
            }
        }
        .onChange(of: settings.browserServerPort) { _, newPort in
            let value = String(newPort)
            if browserPortInput != value {
                browserPortInput = value
            }
            validateBrowserPortInput(browserPortInput)
        }
        .onChange(of: selectedTab) { _, tab in
            if tab == .guidance {
                availableMics = AudioInputDevice.allInputDevices()
            }
            if tab == .teleprompter {
                refreshOverlayScreens()
            }
            if tab == .external {
                refreshScreens()
            }
            if tab == .browser {
                localIP = BrowserServer.localIPAddress() ?? "localhost"
            }
        }
    }

    private var sidebar: some View {
        FCSettingsTabRail(title: "Settings", tabs: SettingsTab.allCases, selectedTab: $selectedTab) { tab, isSelected in
            HStack(spacing: FCSpacingToken.s8.rawValue) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 16)
                Text(tab.label)
                    .fcTypography(.bodyM)
            }
            .foregroundStyle(isSelected ? theme.color(tab.accent) : theme.color(.textSecondary))
        }
    }

    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .appearance:
                appearanceTab
            case .guidance:
                guidanceTab
            case .teleprompter:
                teleprompterTab
            case .external:
                externalTab
            case .browser:
                browserTab
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Reset All") {
                showResetConfirmation = true
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.color(.textSecondary))
            .fcTypography(.label)
            .padding(.horizontal, FCSpacingToken.s12.rawValue)
            .padding(.vertical, FCSpacingToken.s8.rawValue)
            .background(
                Capsule(style: .continuous)
                    .fill(theme.color(.surfaceOverlay).opacity(0.85))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
            )

            Spacer()

            Button("Done") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .fcTypography(.label)
            .padding(.horizontal, FCSpacingToken.s20.rawValue)
            .padding(.vertical, FCSpacingToken.s8.rawValue)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.color(.accentInfo), theme.color(.accentPrimary)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
    }

    // MARK: - Appearance Tab

    private var appearanceTab: some View {
        settingsScroll {
            FCSettingsSectionCard(title: "Font", subtitle: "Choose the teleprompter type style.") {
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    ForEach(FontFamilyPreset.allCases) { preset in
                        Button {
                            withAnimation(theme.animation(.base)) {
                                settings.fontFamilyPreset = preset
                            }
                        } label: {
                            FCSettingsOptionCard(isSelected: settings.fontFamilyPreset == preset, accent: .accentInfo) {
                                VStack(spacing: FCSpacingToken.s4.rawValue) {
                                    Text(preset.sampleText)
                                        .font(Font(preset.font(size: 18)))
                                        .foregroundStyle(settings.fontFamilyPreset == preset ? theme.color(.accentInfo) : theme.color(.textPrimary))
                                    Text(preset.label)
                                        .foregroundStyle(settings.fontFamilyPreset == preset ? theme.color(.accentInfo) : theme.color(.textSecondary))
                                        .fcTypography(.caption)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            FCSettingsSectionCard(title: "Size", subtitle: "Set default text size in the overlay.") {
                HStack(spacing: FCSpacingToken.s8.rawValue) {
                    ForEach(FontSizePreset.allCases) { preset in
                        Button {
                            withAnimation(theme.animation(.base)) {
                                settings.fontSizePreset = preset
                            }
                        } label: {
                            FCSettingsOptionCard(isSelected: settings.fontSizePreset == preset, accent: .accentPrimary) {
                                VStack(spacing: FCSpacingToken.s4.rawValue) {
                                    Text("Ag")
                                        .font(Font(settings.fontFamilyPreset.font(size: preset.pointSize * 0.7)))
                                        .foregroundStyle(settings.fontSizePreset == preset ? theme.color(.accentPrimary) : theme.color(.textPrimary))
                                    Text(preset.label)
                                        .foregroundStyle(settings.fontSizePreset == preset ? theme.color(.accentPrimary) : theme.color(.textSecondary))
                                        .fcTypography(.caption)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            FCSettingsSectionCard(title: "Highlight Color", subtitle: "Color used for focused words while reading.") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: FCSpacingToken.s8.rawValue)], spacing: FCSpacingToken.s8.rawValue) {
                    ForEach(FontColorPreset.allCases) { preset in
                        Button {
                            withAnimation(theme.animation(.base)) {
                                settings.fontColorPreset = preset
                            }
                        } label: {
                            FCSettingsOptionCard(isSelected: settings.fontColorPreset == preset, accent: .accentCTA) {
                                VStack(spacing: FCSpacingToken.s4.rawValue) {
                                    Circle()
                                        .fill(preset.color)
                                        .frame(width: 22, height: 22)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
                                        )
                                        .overlay(
                                            Group {
                                                if settings.fontColorPreset == preset {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundStyle(preset == .white ? .black : .white)
                                                }
                                            }
                                        )
                                    Text(preset.label)
                                        .foregroundStyle(settings.fontColorPreset == preset ? theme.color(.textPrimary) : theme.color(.textSecondary))
                                        .fcTypography(.caption)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            FCSettingsSectionCard(title: "Dimensions", subtitle: "Tune notch panel size.") {
                VStack(spacing: FCSpacingToken.s12.rawValue) {
                    sliderControl(
                        title: "Width",
                        valueLabel: "\(Int(settings.notchWidth))px"
                    ) {
                        Slider(
                            value: $settings.notchWidth,
                            in: NotchSettings.minWidth...NotchSettings.maxWidth,
                            step: 10
                        )
                    }

                    sliderControl(
                        title: "Height",
                        valueLabel: "\(Int(settings.textAreaHeight))px"
                    ) {
                        Slider(
                            value: $settings.textAreaHeight,
                            in: NotchSettings.minHeight...NotchSettings.maxHeight,
                            step: 10
                        )
                    }
                }
            }
        }
    }

    // MARK: - Guidance Tab

    private var guidanceTab: some View {
        settingsScroll {
            FCSettingsSectionCard(title: "Speech Backend") {
                VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                    Picker("", selection: $settings.speechBackend) {
                        ForEach(SpeechBackend.allCases) { backend in
                            Text(backend.label).tag(backend)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    Text(settings.speechBackend.description)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.caption)
                }
            }

            FCSettingsSectionCard(title: "Provider Keys", subtitle: "Stored securely in Keychain.") {
                VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                    if settings.speechBackend == .deepgram {
                        providerKeyField(
                            title: "Deepgram API Key",
                            placeholder: "Paste your Deepgram API key",
                            text: Binding(
                                get: { settings.deepgramAPIKey },
                                set: { settings.deepgramAPIKey = $0 }
                            ),
                            helpText: "Get a free API key",
                            helpURL: URL(string: "https://console.deepgram.com")!
                        )
                    }

                    providerKeyField(
                        title: "OpenAI API Key",
                        placeholder: "Paste your OpenAI API key",
                        text: Binding(
                            get: { settings.openaiAPIKey },
                            set: { settings.openaiAPIKey = $0 }
                        ),
                        description: "Used for Smart Resync and script refinement.",
                        helpText: "Get an API key",
                        helpURL: URL(string: "https://platform.openai.com/api-keys")!
                    )
                }
            }

            FCSettingsSectionCard(title: "Smart Resync") {
                VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                    Toggle(isOn: $settings.llmResyncEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Smart Resync")
                                .foregroundStyle(theme.color(.textPrimary))
                                .fcTypography(.label)
                            Text("Uses AI to re-sync the teleprompter when you paraphrase or go off-script.")
                                .foregroundStyle(theme.color(.textSecondary))
                                .fcTypography(.caption)
                        }
                    }
                    .toggleStyle(.switch)

                    VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                        Text("Refinement Model")
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.caption)
                        Picker("", selection: $settings.refinementModel) {
                            Text("GPT-4o").tag("gpt-4o")
                            Text("GPT-4o Mini").tag("gpt-4o-mini")
                            Text("GPT-5.2").tag("gpt-5.2")
                        }
                        .labelsHidden()
                        .frame(width: 200)
                    }
                }
            }

            FCSettingsSectionCard(title: "Listening Mode") {
                VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                    Picker("", selection: $settings.listeningMode) {
                        ForEach(ListeningMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    Text(settings.listeningMode.description)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.caption)

                    if settings.listeningMode == .wordTracking {
                        VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                            Text("Speech Language")
                                .foregroundStyle(theme.color(.textSecondary))
                                .fcTypography(.caption)
                            Picker("", selection: $settings.speechLocale) {
                                ForEach(SFSpeechRecognizer.supportedLocales().sorted(by: { $0.identifier < $1.identifier }), id: \.identifier) { locale in
                                    Text(Locale.current.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                                        .tag(locale.identifier)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                }
            }

            if settings.listeningMode != .classic {
                FCSettingsSectionCard(title: "Input Device") {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                        Text("Microphone")
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.caption)
                        Picker("", selection: $settings.selectedMicUID) {
                            Text("System Default").tag("")
                            ForEach(availableMics) { mic in
                                Text(mic.name).tag(mic.uid)
                            }
                        }
                        .labelsHidden()
                    }
                }
            }

            if settings.listeningMode != .wordTracking {
                FCSettingsSectionCard(title: "Scroll") {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                        sliderControl(
                            title: "Scroll Speed",
                            valueLabel: String(format: "%.1f words/s", settings.scrollSpeed)
                        ) {
                            Slider(
                                value: $settings.scrollSpeed,
                                in: 0.5...8,
                                step: 0.5
                            )
                        }

                        HStack {
                            Text("Slower")
                                .foregroundStyle(theme.color(.textTertiary))
                                .fcTypography(.caption)
                            Spacer()
                            Text("Faster")
                                .foregroundStyle(theme.color(.textTertiary))
                                .fcTypography(.caption)
                        }
                    }
                }
            }
        }
        .onAppear {
            availableMics = AudioInputDevice.allInputDevices()
        }
    }

    // MARK: - Teleprompter Tab

    private var teleprompterTab: some View {
        settingsScroll {
            FCSettingsSectionCard(title: "Overlay Mode") {
                VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                    Picker("", selection: $settings.overlayMode) {
                        ForEach(OverlayMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    Text(settings.overlayMode.description)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.caption)
                }
            }

            if settings.overlayMode == .pinned {
                FCSettingsSectionCard(title: "Pinned Display") {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                        Picker("", selection: $settings.notchDisplayMode) {
                            ForEach(NotchDisplayMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Text(settings.notchDisplayMode.description)
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.caption)

                        if settings.notchDisplayMode == .fixedDisplay {
                            displayPicker(
                                screens: overlayScreens,
                                selectedID: $settings.pinnedScreenID,
                                onRefresh: { refreshOverlayScreens() }
                            )
                        }
                    }
                }
            }

            if settings.overlayMode == .floating {
                FCSettingsSectionCard(title: "Floating Window") {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                        Toggle(isOn: $settings.followCursorWhenUndocked) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Follow Cursor")
                                    .foregroundStyle(theme.color(.textPrimary))
                                    .fcTypography(.label)
                                Text("The window follows your cursor and sticks to its bottom-right.")
                                    .foregroundStyle(theme.color(.textSecondary))
                                    .fcTypography(.caption)
                            }
                        }
                        .toggleStyle(.switch)

                        Toggle(isOn: $settings.floatingGlassEffect) {
                            Text("Glass Effect")
                                .foregroundStyle(theme.color(.textPrimary))
                                .fcTypography(.label)
                        }
                        .toggleStyle(.switch)

                        if settings.floatingGlassEffect {
                            sliderControl(
                                title: "Opacity",
                                valueLabel: "\(Int(settings.glassOpacity * 100))%"
                            ) {
                                Slider(
                                    value: $settings.glassOpacity,
                                    in: 0.0...0.6,
                                    step: 0.05
                                )
                            }
                        }
                    }
                }
            }

            if settings.overlayMode == .fullscreen {
                FCSettingsSectionCard(title: "Fullscreen Display") {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                        displayPicker(
                            screens: overlayScreens,
                            selectedID: $settings.fullscreenScreenID,
                            onRefresh: { refreshOverlayScreens() }
                        )

                        FCSettingsInlineNotice(kind: .info, text: "Press Esc to stop the teleprompter.")
                    }
                }
            }

            FCSettingsSectionCard(title: "Visibility") {
                VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                    Toggle(isOn: $settings.showElapsedTime) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Elapsed Time")
                                .foregroundStyle(theme.color(.textPrimary))
                                .fcTypography(.label)
                            Text("Display a running timer while the teleprompter is active.")
                                .foregroundStyle(theme.color(.textSecondary))
                                .fcTypography(.caption)
                        }
                    }
                    .toggleStyle(.checkbox)

                    Toggle(isOn: $settings.hideFromScreenShare) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hide from Screen Sharing")
                                .foregroundStyle(theme.color(.textPrimary))
                                .fcTypography(.label)
                            Text("Hide the overlay from screen recordings and video calls.")
                                .foregroundStyle(theme.color(.textSecondary))
                                .fcTypography(.caption)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
            }

            FCSettingsSectionCard(title: "Pagination") {
                VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                    Toggle(isOn: $settings.autoNextPage) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto Next Page")
                                .foregroundStyle(theme.color(.textPrimary))
                                .fcTypography(.label)
                            Text("Automatically advance to the next page after a countdown.")
                                .foregroundStyle(theme.color(.textSecondary))
                                .fcTypography(.caption)
                        }
                    }
                    .toggleStyle(.checkbox)

                    if settings.autoNextPage {
                        HStack(spacing: FCSpacingToken.s8.rawValue) {
                            Text("Countdown")
                                .foregroundStyle(theme.color(.textSecondary))
                                .fcTypography(.caption)
                            Spacer()
                            Picker("", selection: $settings.autoNextPageDelay) {
                                Text("3 seconds").tag(3)
                                Text("5 seconds").tag(5)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }
                    }
                }
            }
        }
        .onAppear {
            refreshOverlayScreens()
        }
    }

    // MARK: - External Tab

    private var externalTab: some View {
        settingsScroll {
            FCSettingsSectionCard(title: "External Output", subtitle: "Show the teleprompter on an external display or Sidecar iPad.") {
                VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                    Picker("", selection: $settings.externalDisplayMode) {
                        ForEach(ExternalDisplayMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    Text(settings.externalDisplayMode.description)
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.caption)
                }
            }

            if settings.externalDisplayMode == .mirror {
                FCSettingsSectionCard(title: "Mirror Axis") {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                        Picker("", selection: $settings.mirrorAxis) {
                            ForEach(MirrorAxis.allCases) { axis in
                                Text(axis.label).tag(axis)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Text(settings.mirrorAxis.description)
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.caption)
                    }
                }
            }

            if settings.externalDisplayMode != .off {
                FCSettingsSectionCard(title: "Target Display") {
                    displayPicker(
                        screens: availableScreens,
                        selectedID: $settings.externalScreenID,
                        onRefresh: { refreshScreens() },
                        emptyMessage: "No external displays detected. Connect a display or enable Sidecar."
                    )
                }
            }
        }
        .onAppear {
            refreshScreens()
        }
    }

    // MARK: - Remote Tab

    private var browserTab: some View {
        settingsScroll {
            FCSettingsSectionCard(title: "Connection", subtitle: "Use your phone or TV browser on the same Wi-Fi network.") {
                Toggle(isOn: $settings.browserServerEnabled) {
                    Text("Enable Remote Connection")
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.label)
                }
                .toggleStyle(.switch)
            }

            if settings.browserServerEnabled {
                FCSettingsSectionCard(title: "Remote URL") {
                    VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                        if let qrImage = generateQRCode(from: browserURL) {
                            HStack {
                                Spacer()
                                Image(nsImage: qrImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 124, height: 124)
                                    .clipShape(RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                                            .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
                                    )
                                Spacer()
                            }
                        }

                        HStack(spacing: FCSpacingToken.s8.rawValue) {
                            Text(browserURL)
                                .foregroundStyle(theme.color(.accentInfo))
                                .fcTypography(.mono)
                                .textSelection(.enabled)
                                .lineLimit(1)

                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(browserURL, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(theme.color(.textSecondary))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Copy remote URL")
                            .help("Copy URL")
                        }
                        .padding(FCSpacingToken.s12.rawValue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                                .fill(theme.color(.accentInfo).opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                                .stroke(theme.color(.accentInfo).opacity(0.28), lineWidth: FCStrokeToken.thin.rawValue)
                        )
                    }
                }

                FCSettingsSectionCard(title: "Advanced") {
                    DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
                        VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                            HStack(alignment: .top, spacing: FCSpacingToken.s8.rawValue) {
                                VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                                    Text("Port")
                                        .foregroundStyle(theme.color(.textSecondary))
                                        .fcTypography(.caption)

                                    TextField("Port", text: $browserPortInput)
                                        .textFieldStyle(.plain)
                                        .padding(.horizontal, FCSpacingToken.s8.rawValue)
                                        .padding(.vertical, FCSpacingToken.s8.rawValue)
                                        .frame(width: 96)
                                        .background(
                                            RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                                                .fill(theme.color(.surfaceOverlay).opacity(0.82))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                                                .stroke(
                                                    browserPortValidation == nil ? theme.color(.borderSubtle) : theme.color(.stateWarning),
                                                    lineWidth: FCStrokeToken.thin.rawValue
                                                )
                                        )
                                        .onChange(of: browserPortInput) { _, newValue in
                                            validateBrowserPortInput(newValue)
                                            guard browserPortValidation == nil, let val = UInt16(newValue), val >= 1024 else { return }
                                            settings.browserServerPort = val
                                        }
                                }

                                VStack(alignment: .leading, spacing: FCSpacingToken.s4.rawValue) {
                                    Text("Restart required after change")
                                        .foregroundStyle(theme.color(.textTertiary))
                                        .fcTypography(.caption)

                                    Button("Restart") {
                                        FocusCueService.shared.browserServer.stop()
                                        FocusCueService.shared.browserServer.start()
                                        localIP = BrowserServer.localIPAddress() ?? "localhost"
                                    }
                                    .buttonStyle(.bordered)
                                }

                                Spacer(minLength: 0)
                            }

                            if let browserPortValidation {
                                FCSettingsInlineNotice(kind: .warning, text: browserPortValidation)
                            }

                            FCSettingsInlineNotice(
                                kind: .info,
                                text: "Uses ports \(settings.browserServerPort) (HTTP) and \(settings.browserServerPort + 1) (WebSocket)."
                            )
                        }
                        .padding(.top, FCSpacingToken.s8.rawValue)
                    }
                    .tint(theme.color(.textSecondary))
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.label)
                }
            }
        }
        .onAppear {
            localIP = BrowserServer.localIPAddress() ?? "localhost"
        }
    }

    // MARK: - Shared Components

    private func settingsScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                content()
            }
            .padding(.bottom, FCSpacingToken.s8.rawValue)
        }
    }

    private func sliderControl<Control: View>(
        title: String,
        valueLabel: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
            HStack {
                Text(title)
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.caption)
                Spacer()
                Text(valueLabel)
                    .foregroundStyle(theme.color(.textTertiary))
                    .fcTypography(.mono)
            }
            control()
        }
    }

    private func providerKeyField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        description: String? = nil,
        helpText: String,
        helpURL: URL
    ) -> some View {
        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
            HStack {
                Text(title)
                    .foregroundStyle(theme.color(.textSecondary))
                    .fcTypography(.caption)
                Spacer()
                FCSettingsStatusBadge(
                    label: text.wrappedValue.isEmpty ? "Missing" : "Configured",
                    kind: text.wrappedValue.isEmpty ? .warning : .success
                )
            }

            SecureField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding(.horizontal, FCSpacingToken.s8.rawValue)
                .padding(.vertical, FCSpacingToken.s8.rawValue)
                .background(
                    RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                        .fill(theme.color(.surfaceOverlay).opacity(0.82))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                        .stroke(theme.color(.borderSubtle), lineWidth: FCStrokeToken.thin.rawValue)
                )

            if let description {
                Text(description)
                    .foregroundStyle(theme.color(.textTertiary))
                    .fcTypography(.caption)
            }

            Link(helpText, destination: helpURL)
                .foregroundStyle(theme.color(.accentInfo))
                .fcTypography(.caption)
        }
    }

    private func displayPicker(
        screens: [NSScreen],
        selectedID: Binding<UInt32>,
        onRefresh: @escaping () -> Void,
        emptyMessage: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
            if screens.isEmpty, let emptyMessage {
                FCSettingsInlineNotice(kind: .warning, text: emptyMessage)
            } else {
                ForEach(screens, id: \.displayID) { screen in
                    Button {
                        withAnimation(theme.animation(.fast)) {
                            selectedID.wrappedValue = screen.displayID
                        }
                    } label: {
                        FCSettingsOptionCard(isSelected: selectedID.wrappedValue == screen.displayID, accent: .accentInfo) {
                            HStack(spacing: FCSpacingToken.s8.rawValue) {
                                Image(systemName: "display")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(selectedID.wrappedValue == screen.displayID ? theme.color(.accentInfo) : theme.color(.textSecondary))
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(screen.displayName)
                                        .foregroundStyle(selectedID.wrappedValue == screen.displayID ? theme.color(.accentInfo) : theme.color(.textPrimary))
                                        .fcTypography(.label)
                                    Text("\(Int(screen.frame.width))×\(Int(screen.frame.height))")
                                        .foregroundStyle(theme.color(.textTertiary))
                                        .fcTypography(.caption)
                                }

                                Spacer()

                                if selectedID.wrappedValue == screen.displayID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(theme.color(.accentInfo))
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: onRefresh) {
                HStack(spacing: FCSpacingToken.s4.rawValue) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Refresh")
                        .fcTypography(.caption)
                }
                .foregroundStyle(theme.color(.textSecondary))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - QR Code

    private func generateQRCode(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return nil }
        let scale = 10.0
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: scaled.extent.width, height: scaled.extent.height))
    }

    // MARK: - Helpers

    private func syncDerivedState() {
        availableMics = AudioInputDevice.allInputDevices()
        refreshScreens()
        refreshOverlayScreens()
        localIP = BrowserServer.localIPAddress() ?? "localhost"
        browserPortInput = String(settings.browserServerPort)
        validateBrowserPortInput(browserPortInput)
    }

    private func validateBrowserPortInput(_ value: String) {
        if value.isEmpty {
            browserPortValidation = "Port is required and must be 1024 or higher."
            return
        }

        guard let parsed = UInt16(value) else {
            browserPortValidation = "Port must be a number between 1024 and 65535."
            return
        }

        guard parsed >= 1024 else {
            browserPortValidation = "Ports below 1024 are reserved by the system."
            return
        }

        browserPortValidation = nil
    }

    private func resetAllSettings() {
        settings.speechBackend = .apple
        settings.notchWidth = NotchSettings.defaultWidth
        settings.textAreaHeight = NotchSettings.defaultHeight
        settings.fontSizePreset = .lg
        settings.fontFamilyPreset = .sans
        settings.fontColorPreset = .white
        settings.overlayMode = .pinned
        settings.notchDisplayMode = .followMouse
        settings.pinnedScreenID = 0
        settings.floatingGlassEffect = false
        settings.glassOpacity = 0.15
        settings.followCursorWhenUndocked = false
        settings.fullscreenScreenID = 0
        settings.externalDisplayMode = .off
        settings.externalScreenID = 0
        settings.mirrorAxis = .horizontal
        settings.listeningMode = .wordTracking
        settings.scrollSpeed = 3
        settings.showElapsedTime = true
        settings.selectedMicUID = ""
        settings.autoNextPage = false
        settings.autoNextPageDelay = 3
        settings.browserServerEnabled = false
        settings.browserServerPort = 7373
        settings.llmResyncEnabled = false
        settings.refinementModel = "gpt-4o"

        browserPortInput = String(settings.browserServerPort)
        validateBrowserPortInput(browserPortInput)
    }

    private func refreshScreens() {
        availableScreens = NSScreen.screens.filter { $0 != NSScreen.main }
        if settings.externalScreenID == 0, let first = availableScreens.first {
            settings.externalScreenID = first.displayID
        }
    }

    private func refreshOverlayScreens() {
        overlayScreens = NSScreen.screens
        if settings.pinnedScreenID == 0, let main = NSScreen.main {
            settings.pinnedScreenID = main.displayID
        }
        if settings.fullscreenScreenID == 0, let main = NSScreen.main {
            settings.fullscreenScreenID = main.displayID
        }
    }
}
