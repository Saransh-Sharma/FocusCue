# FocusCue User Workflows

This guide describes end-to-end workflows for users and operators, plus troubleshooting steps mapped to each flow.

## Workflow 1: First launch and onboarding

### Objective

Get FocusCue ready for use with the correct permissions and an initial script path.

### Steps

1. Launch FocusCue for the first time.
2. Complete onboarding steps (welcome, modes, surfaces, microphone, speech recognition, ready).
3. Grant microphone and speech recognition access when prompted.
4. Choose either:
   - Start with guided template.
   - Open Settings for deeper configuration.

### Expected behavior

- Onboarding appears when `focuscue.onboarding.completed` is false.
- Permission status reflects current system grants and can open system settings shortcuts.
- Completion records onboarding as finished and returns to main workspace.

### Relevant implementation

- [`../FocusCue/OnboardingWizardView.swift`](../FocusCue/OnboardingWizardView.swift)
- [`../FocusCue/PermissionCenter.swift`](../FocusCue/PermissionCenter.swift)
- [`../FocusCue/ContentView.swift`](../FocusCue/ContentView.swift)

## Workflow 2: Script creation, editing, and page organization

### Objective

Create and manage a multi-page script across Live Transcripts and Archive.

### Steps

1. Add pages from the page rail.
2. Edit content in Script Editor.
3. Rename pages if needed.
4. Drag/drop reorder within section.
5. Move pages between Live Transcripts and Archive.
6. Save current page or save all dirty pages.

### Expected behavior

- New pages are created in Live Transcripts.
- Auto-title updates from first meaningful line unless a custom title is set.
- Dirty and save-failed markers appear in page rows.
- Deleting a page removes it from workspace and trashes associated draft page file when available.

### Relevant implementation

- [`../FocusCue/ContentView.swift`](../FocusCue/ContentView.swift)
- [`../FocusCue/MainWindowComponents.swift`](../FocusCue/MainWindowComponents.swift)
- [`../FocusCue/FocusCueService.swift`](../FocusCue/FocusCueService.swift)
- [`../FocusCue/SidebarModels.swift`](../FocusCue/SidebarModels.swift)

## Workflow 3: Start and stop playback

### Objective

Run teleprompter playback from the selected live page and stop cleanly.

### Steps

1. Select a page in Live Transcripts with non-empty text.
2. Click Start.
3. Read with the selected listening mode.
4. Advance manually or allow auto-next (if enabled).
5. Stop via overlay controls, ESC (in supported modes), or completion.

### Expected behavior

- Start is blocked with explicit reason when preconditions fail.
- Overlay appears in selected output mode.
- Read progress updates current page highlighting and output surfaces.
- On dismissal, app clears read state and restores foreground focus.

### Relevant implementation

- [`../FocusCue/ContentView.swift`](../FocusCue/ContentView.swift)
- [`../FocusCue/FocusCueService.swift`](../FocusCue/FocusCueService.swift)
- [`../FocusCue/NotchOverlayController.swift`](../FocusCue/NotchOverlayController.swift)

## Workflow 4: Overlay mode selection and behavior

### Objective

Choose the right teleprompter surface behavior for context.

### Modes

- Pinned to notch region.
- Floating window (optionally with follow-cursor behavior).
- Fullscreen teleprompter surface.

### Steps

1. Open Settings -> Teleprompter.
2. Select overlay mode.
3. Configure mode-specific options:
   - Pinned display strategy.
   - Floating glass effect, opacity, follow-cursor.
   - Fullscreen target display.
4. Start playback and validate behavior.

### Expected behavior

- Preview panel reflects settings when not in fullscreen mode.
- ESC closes overlay in fullscreen/floating modes with key monitor enabled.
- Follow-cursor mode runs with click-through overlay plus separate stop button.

### Relevant implementation

- [`../FocusCue/SettingsView.swift`](../FocusCue/SettingsView.swift)
- [`../FocusCue/NotchSettings.swift`](../FocusCue/NotchSettings.swift)
- [`../FocusCue/NotchOverlayController.swift`](../FocusCue/NotchOverlayController.swift)

## Workflow 5: External display and remote browser output

### Objective

Broadcast script output to additional surfaces for production and monitoring.

### External display flow

1. Open Settings -> External.
2. Set external mode to Teleprompter or Mirror.
3. Select target display.
4. Start playback.

Expected:
- External panel opens on selected non-main display.
- Mirror mode applies selected axis transform.
- Dismissal follows overlay completion state.

### Browser remote flow

1. Open Settings -> Remote.
2. Enable remote connection.
3. Use shown URL/QR on same network.
4. Start playback.

Expected:
- HTTP listener serves viewer page.
- WebSocket stream sends live `BrowserState` payload updates.
- Disabling server stops listeners and sends inactive state.

### Relevant implementation

- [`../FocusCue/ExternalDisplayController.swift`](../FocusCue/ExternalDisplayController.swift)
- [`../FocusCue/BrowserServer.swift`](../FocusCue/BrowserServer.swift)
- [`../FocusCue/SettingsView.swift`](../FocusCue/SettingsView.swift)

## Workflow 6: Import presentation notes and save `.focuscue`

### Objective

Convert slide notes into script pages and preserve workspace as native FocusCue documents.

### Steps

1. Open document panel or drag `.pptx` into main window.
2. Let import parse presenter notes into pages.
3. Review/edit generated pages.
4. Save workspace to `.focuscue`.
5. Reopen `.focuscue` later from Open command or Finder association.

### Expected behavior

- `.pptx` notes are extracted asynchronously and loaded into live pages.
- `.key` files are rejected with explicit export instructions.
- Save writes `FocusCueDocumentV3` payload with schema version guard.
- Unsupported legacy schema/open attempts show explicit alert messaging.

### Relevant implementation

- [`../FocusCue/FocusCueService.swift`](../FocusCue/FocusCueService.swift)
- [`../FocusCue/PresentationNotesExtractor.swift`](../FocusCue/PresentationNotesExtractor.swift)
- [`../FocusCue/SidebarModels.swift`](../FocusCue/SidebarModels.swift)

## Troubleshooting by workflow

| Workflow | Symptom | Likely cause | Resolution |
| --- | --- | --- | --- |
| First launch | Permission step never turns green | Access denied/restricted in system settings | Use onboarding/settings "Open System Settings" action and re-open app focus. |
| Script management | Save indicators persist after save-all | Page save failed or digest mismatch remains | Retry page save; verify page still exists and draft path is writable. |
| Playback start | Start disabled or error alert on start | Selected page is in Archive or has empty text | Move page to Live Transcripts and ensure non-empty content. |
| Overlay behavior | Overlay appears on unexpected display | Display mode setting mismatch | Reconfigure pinned/fixed/follow-mouse or fullscreen display target in settings. |
| Speech tracking | Progress stalls in voice modes | Mic/speech permissions missing, backend key missing, or no input signal | Verify permissions, backend selection, API keys, and selected mic UID. |
| Remote output | Browser viewer cannot connect | Server disabled, port conflict, wrong local IP/network | Enable remote server, confirm URL/port, restart server, ensure same network. |
| Import/export | `.focuscue` open fails | Unsupported/invalid schema payload | Use current schema-generated files; re-save from current app build. |
| Import/export | `.pptx` import returns no pages | Notes missing or unsupported deck content | Confirm presenter notes exist in source deck and retry with exported `.pptx`. |

## Operational checklist for live sessions

1. Confirm selected page is in Live Transcripts and non-empty.
2. Validate listening mode and backend configuration.
3. Confirm mic device and permission status.
4. Validate overlay mode and target display placement.
5. If external/remote is used, verify those surfaces before going live.
6. Save dirty pages before session start.
