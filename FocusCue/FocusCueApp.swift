//
//  FocusCueApp.swift
//  FocusCue
//
//  Created by Fatih Kadir Akın on 8.02.2026.
//

import SwiftUI

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
    static let openAbout = Notification.Name("openAbout")
    static let openOnboarding = Notification.Name("openOnboarding")
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        let launchedByURL: Bool
        if let event = NSAppleEventManager.shared().currentAppleEvent {
            launchedByURL = event.eventClass == kInternetEventClass
        } else {
            launchedByURL = false
        }
        if launchedByURL {
            FocusCueService.shared.launchedExternally = true
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = FocusCueService.shared
        NSUpdateDynamicServices()
        _ = EntitlementService.shared
        EntitlementService.shared.handleAppLaunch()

#if DEBUG
        NSLog(
            "FocusCue distribution features: updater=%@ cloudSpeech=%@ openAI=%@ browserRemote=%@",
            DistributionFeatures.externalUpdaterEnabled.description,
            DistributionFeatures.cloudSpeechEnabled.description,
            DistributionFeatures.openAIFeaturesEnabled.description,
            DistributionFeatures.browserRemoteEnabled.description
        )
#endif

        if FocusCueService.shared.launchedExternally {
            FocusCueService.shared.hideMainWindow()
        }

        if DistributionFeatures.externalUpdaterEnabled {
            UpdateChecker.shared.checkForUpdates(silent: true)
        }

        // Start browser server if enabled
        FocusCueService.shared.updateBrowserServer()
        configureStatusItem()

        // Set window delegate to intercept close, disable tabs and fullscreen
        DispatchQueue.main.async {
            for window in NSApp.windows where !(window is NSPanel) {
                window.delegate = self
                window.tabbingMode = .disallowed
                window.collectionBehavior.remove(.fullScreenPrimary)
                window.collectionBehavior.insert(.fullScreenNone)
            }
            self.removeUnwantedMenus()
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        FocusCueService.shared.confirmDiscardIfNeeded() ? .terminateNow : .terminateCancel
    }

    func applicationWillTerminate(_ notification: Notification) {
        FocusCueService.shared.flushPendingPersistence()
    }

    private func removeUnwantedMenus() {
        guard let mainMenu = NSApp.mainMenu else { return }
        // Keep the Window menu so App Review and users can reopen the hidden main window.
        let menusToRemove = ["View"]
        for title in menusToRemove {
            if let index = mainMenu.items.firstIndex(where: { $0.title == title }) {
                mainMenu.removeItem(at: index)
            }
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide the window instead of closing it
        sender.orderOut(nil)
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if FocusCueService.shared.launchedExternally {
            FocusCueService.shared.launchedExternally = false
            NSApp.setActivationPolicy(.regular)
        }
        if !flag {
            // Show existing window instead of letting SwiftUI create a duplicate
            FocusCueService.shared.showMainWindow()
            return false
        }
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.pathExtension == "focuscue" {
                FocusCueService.shared.openFileAtURL(url)
                // Show the main window for file opens
                FocusCueService.shared.showMainWindow()
            } else {
                let wasExternal = FocusCueService.shared.launchedExternally
                FocusCueService.shared.launchedExternally = true
                if !wasExternal {
                    NSApp.setActivationPolicy(.accessory)
                }
                FocusCueService.shared.hideMainWindow()
                FocusCueService.shared.handleURL(url)
            }
        }
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: "FocusCue")
        item.button?.imagePosition = .imageLeading
        item.button?.toolTip = "FocusCue"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show FocusCue", action: #selector(showFocusCueFromStatusItem), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettingsFromStatusItem), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit FocusCue", action: #selector(quitFromStatusItem), keyEquivalent: "q"))
        for menuItem in menu.items {
            menuItem.target = self
        }
        item.menu = menu
        statusItem = item
    }

    @objc private func showFocusCueFromStatusItem() {
        FocusCueService.shared.showMainWindow()
    }

    @objc private func openSettingsFromStatusItem() {
        FocusCueService.shared.showMainWindow()
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }

    @objc private func quitFromStatusItem() {
        NSApp.terminate(nil)
    }
}

@main
struct FocusCueApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    if url.pathExtension == "focuscue" {
                        FocusCueService.shared.openFileAtURL(url)
                    } else {
                        FocusCueService.shared.handleURL(url)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About FocusCue") {
                    NotificationCenter.default.post(name: .openAbout, object: nil)
                }
                if DistributionFeatures.externalUpdaterEnabled {
                    Divider()
                    Button("Check for Updates…") {
                        UpdateChecker.shared.checkForUpdates()
                    }
                }
            }
            CommandGroup(after: .appSettings) {
                Button("Settings…") {
                    FocusCueService.shared.showMainWindow()
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(replacing: .newItem) {
                Button("Open…") {
                    FocusCueService.shared.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Save") {
                    FocusCueService.shared.saveFile()
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As…") {
                    FocusCueService.shared.saveFileAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .windowArrangement) {
                Button("Show FocusCue Window") {
                    FocusCueService.shared.showMainWindow()
                }
                .keyboardShortcut("0", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .help) {
                Button("Getting Started…") {
                    FocusCueService.shared.showMainWindow()
                    NotificationCenter.default.post(name: .openOnboarding, object: nil)
                }
                Divider()
                Button("FocusCue Help") {
                    if let url = URL(string: "https://github.com/saransh1337/FocusCue") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
