//
//  ContentView.swift
//  FocusCue
//
//  Created by Fatih Kadir Akın on 8.02.2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var service = FocusCueService.shared
    @State private var isRunning = false
    @State private var isDroppingPresentation = false
    @State private var dropError: String?
    @State private var dropAlertTitle = "Import Error"
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showDraft = false
    @State private var showOnboarding = false
    @State private var revealMainWindow = false

    @AppStorage("focuscue.onboarding.completed") private var onboardingCompleted = false

    @FocusState private var isTextFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let defaultText = """
Welcome to FocusCue! This is your personal teleprompter that sits right below your MacBook's notch. [smile]

As you read aloud, the text will highlight in real-time, following your voice. The speech recognition matches your words and keeps track of your progress. [pause]

You can pause at any time, go back and re-read sections, and the highlighting will follow along. When you finish reading all the text, the overlay will automatically close with a smooth animation. [nod]

Try reading this passage out loud to see how the highlighting works. The waveform at the bottom shows your voice activity, and you'll see the last few words you spoke displayed next to it.

Happy presenting! [wave]
"""

    private var languageLabel: String {
        let locale = NotchSettings.shared.speechLocale
        return Locale.current.localizedString(forIdentifier: locale) ?? locale
    }

    private var modeLabel: String {
        if NotchSettings.shared.listeningMode == .wordTracking {
            return "Word Tracking (\(languageLabel))"
        }
        return NotchSettings.shared.listeningMode.label
    }

    private var modeDescription: String {
        NotchSettings.shared.listeningMode.description
    }

    private var currentText: Binding<String> {
        Binding(
            get: {
                guard service.currentPageIndex < service.pages.count else { return "" }
                return service.pages[service.currentPageIndex]
            },
            set: { newValue in
                guard service.currentPageIndex < service.pages.count else { return }
                service.pages[service.currentPageIndex] = newValue
            }
        )
    }

    private var hasAnyContent: Bool {
        service.pages.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var currentFileName: String? {
        service.currentFileURL?.deletingPathExtension().lastPathComponent
    }

    private var pageItems: [FCPageRailItemModel] {
        service.pages.enumerated().map { index, text in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let preview = trimmed.isEmpty ? "" : String(trimmed.prefix(30))
            return FCPageRailItemModel(
                index: index,
                isRead: service.readPages.contains(index),
                isCurrent: service.currentPageIndex == index,
                preview: preview
            )
        }
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        ZStack {
            FCWindowBackdrop()

            VStack(alignment: .leading, spacing: FCSpacingToken.s20.rawValue) {
                FCWindowHeader(subtitle: "Premium Teleprompter Control Center")

                HStack(alignment: .top, spacing: FCSpacingToken.s16.rawValue) {
                    FCPageRail(
                        items: pageItems,
                        canDelete: service.pages.count > 1,
                        onSelect: { index in
                            withAnimation(theme.spring(.snappy)) {
                                service.currentPageIndex = index
                            }
                        },
                        onDelete: { index in
                            removePage(at: index)
                        },
                        onAdd: {
                            addPage()
                        }
                    )

                    FCGlassPanel {
                        VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
                            HStack {
                                Text("Script Editor")
                                    .foregroundStyle(theme.color(.textPrimary))
                                    .fcTypography(.heading)
                                Spacer()
                                if service.hasUnsavedChanges {
                                    Label("Unsaved", systemImage: "circle.fill")
                                        .foregroundStyle(theme.color(.stateWarning))
                                        .fcTypography(.caption)
                                }
                            }

                            TextEditor(text: currentText)
                                .foregroundStyle(theme.color(.textPrimary))
                                .fcTypography(.bodyL)
                                .scrollContentBackground(.hidden)
                                .padding(FCSpacingToken.s12.rawValue)
                                .background(
                                    RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                                        .fill(theme.color(.surfaceGlassStrong).opacity(0.84))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)
                                        .stroke(
                                            isTextFocused ? theme.color(.borderFocus) : theme.color(.borderSubtle),
                                            lineWidth: isTextFocused ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
                                        )
                                )
                                .focused($isTextFocused)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 460)

                    FCCommandCenter(
                        fileName: currentFileName,
                        hasUnsavedChanges: service.hasUnsavedChanges,
                        modeLabel: modeLabel,
                        modeDescription: modeDescription,
                        onOpenDocument: { service.openFile() },
                        onDraft: { showDraft = true },
                        onAddPage: { addPage() },
                        onSettings: { showSettings = true },
                        onOpenOnboarding: { showOnboarding = true }
                    )
                }
            }
            .padding(FCSpacingToken.s24.rawValue)
            .opacity(revealMainWindow ? 1 : 0)
            .offset(y: revealMainWindow ? 0 : (reduceMotion ? 0 : 12))
            .animation(theme.animation(.emphasized, curve: .enter), value: revealMainWindow)

            if isDroppingPresentation {
                FCDropZoneOverlay()
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97)))
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FCRunDock(
                        isRunning: isRunning,
                        isEnabled: isRunning || hasAnyContent,
                        action: {
                            if isRunning {
                                stop()
                            } else {
                                run()
                            }
                        }
                    )
                }
                .padding(.trailing, FCSpacingToken.s24.rawValue)
                .padding(.bottom, FCSpacingToken.s20.rawValue)
            }

            // Invisible drop target covering the whole window.
            Color.clear
                .contentShape(Rectangle())
                .onDrop(of: [.fileURL], isTargeted: $isDroppingPresentation) { providers in
                    guard let provider = providers.first else { return false }
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        guard let url else { return }
                        let ext = url.pathExtension.lowercased()
                        if ext == "key" {
                            DispatchQueue.main.async {
                                dropAlertTitle = "Conversion Required"
                                dropError = "Keynote files can't be imported directly. Please export your Keynote presentation as PowerPoint (.pptx) first, then drop the exported file here."
                            }
                            return
                        }
                        guard ext == "pptx" else {
                            DispatchQueue.main.async {
                                dropAlertTitle = "Import Error"
                                dropError = "Unsupported file. Drop a PowerPoint (.pptx) file."
                            }
                            return
                        }
                        DispatchQueue.main.async {
                            handlePresentationDrop(url: url)
                        }
                    }
                    return true
                }
                .allowsHitTesting(isDroppingPresentation)
        }
        .alert(dropAlertTitle, isPresented: Binding(get: { dropError != nil }, set: { if !$0 { dropError = nil } })) {
            Button("OK") { dropError = nil }
        } message: {
            Text(dropError ?? "")
        }
        .frame(minWidth: 1100, minHeight: 660)
        .sheet(isPresented: $showDraft) {
            DraftSessionView { script in
                let trimmed = script.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                service.pages = [trimmed]
                service.currentPageIndex = 0
                service.savedPages = service.pages
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: NotchSettings.shared)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingWizardView(
                onStartTemplate: {
                    applyGuidedTemplate()
                },
                onOpenSettings: {
                    showSettings = true
                },
                onFinish: {
                    onboardingCompleted = true
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            showSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAbout)) { _ in
            showAbout = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openOnboarding)) { _ in
            showOnboarding = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            isRunning = service.overlayController.isShowing
        }
        .onAppear {
            if service.pages.count == 1 && service.pages[0].isEmpty {
                service.pages[0] = defaultText
            }

            if service.overlayController.isShowing {
                isRunning = true
            }

            if FocusCueService.shared.launchedExternally {
                DispatchQueue.main.async {
                    for window in NSApp.windows where !(window is NSPanel) {
                        window.orderOut(nil)
                    }
                }
            } else {
                isTextFocused = true
                if !onboardingCompleted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showOnboarding = true
                    }
                }
            }

            revealMainWindow = true
        }
    }

    // MARK: - Actions

    private func addPage() {
        withAnimation(.spring(response: FCMotionToken.Spring.snappy.response, dampingFraction: FCMotionToken.Spring.snappy.dampingFraction)) {
            service.pages.append("")
            service.currentPageIndex = service.pages.count - 1
        }
    }

    private func removePage(at index: Int) {
        guard service.pages.count > 1 else { return }
        withAnimation(.spring(response: FCMotionToken.Spring.snappy.response, dampingFraction: FCMotionToken.Spring.snappy.dampingFraction)) {
            service.pages.remove(at: index)
            if service.currentPageIndex >= service.pages.count {
                service.currentPageIndex = service.pages.count - 1
            } else if service.currentPageIndex > index {
                service.currentPageIndex -= 1
            }
        }
    }

    private func run() {
        guard hasAnyContent else { return }
        isTextFocused = false
        service.onOverlayDismissed = { [self] in
            isRunning = false
            service.readPages.removeAll()
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        service.readPages.removeAll()
        service.currentPageIndex = 0
        service.readCurrentPage()
        isRunning = true
    }

    @State private var isImporting = false

    private func handlePresentationDrop(url: URL) {
        guard service.confirmDiscardIfNeeded() else { return }
        isImporting = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let notes = try PresentationNotesExtractor.extractNotes(from: url)
                DispatchQueue.main.async {
                    service.pages = notes
                    service.savedPages = notes
                    service.currentPageIndex = 0
                    service.readPages.removeAll()
                    service.currentFileURL = nil
                    isImporting = false
                }
            } catch {
                DispatchQueue.main.async {
                    dropError = error.localizedDescription
                    isImporting = false
                }
            }
        }
    }

    private func stop() {
        service.overlayController.dismiss()
        service.readPages.removeAll()
        isRunning = false
    }

    private func applyGuidedTemplate() {
        service.pages = [defaultText]
        service.currentPageIndex = 0
        service.readPages.removeAll()
        service.currentFileURL = nil
        isTextFocused = true
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 16) {
            if let icon = NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            VStack(spacing: 4) {
                Text("FocusCue")
                    .font(.system(size: 20, weight: .bold))
                Text("Version \(appVersion)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Text("A free, open-source teleprompter that highlights your script in real-time as you speak.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/saransh1337/FocusCue")!) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                        Text("GitHub")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Capsule())
                }

                Link(destination: URL(string: "https://donate.stripe.com/aFa8wO4NF2S96jDfn4dMI09")!) {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.pink)
                        Text("Donate")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            Divider().padding(.horizontal, 20)

            VStack(spacing: 4) {
                Text("Made by Fatih Kadir Akin")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Original idea by Semih Kışlar")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Button("OK") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ContentView()
}
