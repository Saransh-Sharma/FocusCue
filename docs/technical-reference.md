# FocusCue Technical Reference

This reference documents core runtime modules, interfaces, contracts, and operational constraints.

## Module-level reference (keyed to source files)

| Module/File | Primary responsibility | Key types |
| --- | --- | --- |
| [`../FocusCue/FocusCueService.swift`](../FocusCue/FocusCueService.swift) | Central orchestration for workspace, playback, file IO, persistence coordination, output synchronization | `FocusCueService`, `StartAvailabilityReason` |
| [`../FocusCue/NotchOverlayController.swift`](../FocusCue/NotchOverlayController.swift) | Overlay window lifecycle, mode-specific panel behavior, page picker and countdown interactions | `NotchOverlayController`, `OverlayContent`, `NotchFrameTracker` |
| [`../FocusCue/SpeechRecognizer.swift`](../FocusCue/SpeechRecognizer.swift) | Speech capture, backend integration, fuzzy matching, progression updates, resync triggers | `SpeechRecognizer`, `AudioInputDevice` |
| [`../FocusCue/BrowserServer.swift`](../FocusCue/BrowserServer.swift) | HTTP viewer + WebSocket broadcast for remote output | `BrowserServer`, `BrowserState` |
| [`../FocusCue/ExternalDisplayController.swift`](../FocusCue/ExternalDisplayController.swift) | Fullscreen external/mirror output panel lifecycle | `ExternalDisplayController`, `ExternalDisplayView` |
| [`../FocusCue/WorkspacePersistence.swift`](../FocusCue/WorkspacePersistence.swift) | UserDefaults autosave and restore | `WorkspacePersistence` |
| [`../FocusCue/DraftFileStore.swift`](../FocusCue/DraftFileStore.swift) | File-backed page draft/index persistence and relocation | `DraftFileStore`, `DraftWorkspaceIndex`, `DraftPageDocument`, `DraftPageReference` |
| [`../FocusCue/SidebarModels.swift`](../FocusCue/SidebarModels.swift) | Canonical workspace/page data types and sidebar display models | `FocusCueDocumentV3`, `ScriptWorkspace`, `ScriptPage`, `SidebarSectionModel` |
| [`../FocusCue/NotchSettings.swift`](../FocusCue/NotchSettings.swift) | Persisted configuration and API-key accessors | `NotchSettings` + setting enums |
| [`../FocusCue/SettingsView.swift`](../FocusCue/SettingsView.swift) | Settings UI, previews, advanced remote controls | `SettingsView`, `NotchPreviewController` |
| [`../FocusCue/MainWindowComponents.swift`](../FocusCue/MainWindowComponents.swift) | Reusable main-window component library and interaction widgets | `FCWindowHeader`, `FCPageRail`, `FCPlaybackHeroPanel`, `FCCommandCenter` |
| [`../FocusCue/MainWindowTheme.swift`](../FocusCue/MainWindowTheme.swift) | Tokenized design system for color, typography, spacing, motion, effects | `FCTheme`, token enums |
| [`../FocusCue/ScriptDraftService.swift`](../FocusCue/ScriptDraftService.swift) | Free-run recording and AI script refinement workflow | `ScriptDraftService` |
| [`../FocusCue/LLMResyncService.swift`](../FocusCue/LLMResyncService.swift) | Pause-triggered AI sync offset reconciliation | `LLMResyncService`, `ResyncResult` |

## Core contracts and behaviors

## `FocusCueService`

### Core runtime guarantees

1. Maintains a valid selected page whenever workspace contains pages.
2. Keeps `readPageIDs`, draft references, and dirty state reconciled against current workspace IDs.
3. Ensures playback state updates are propagated to all active output surfaces.
4. Separates saved baseline (`savedWorkspace`) from working state for unsaved-change logic.

### High-impact methods

| Method | Contract |
| --- | --- |
| `startSelectedLivePage()` | Starts playback only if start availability is `ready`. |
| `readText(_:)` | Shows overlay and synchronizes content to external/browser surfaces. |
| `savePageDraft(_:)` | Persists one page draft and updates dirty/save-failed tracking. |
| `saveAllDirtyPages()` | Iterates deterministic page order and attempts page-level save. |
| `openFileAtURL(_:)` | Attempts V3 decode + schema validation; rejects legacy/unsupported formats. |
| `importPresentation(from:)` | Runs note extraction asynchronously and loads resulting texts as workspace pages. |
| `confirmDiscardIfNeeded()` | Prompts to save/discard/cancel when dirty page set is non-empty. |

## `NotchOverlayController`

### Core behaviors

- Supports pinned, floating, follow-cursor, and fullscreen panel strategies.
- Uses `OverlayContent` as shared UI state for words, page picker metadata, and navigation intents.
- Polls for progression control events (`shouldAdvancePage`, `jumpToPageIndex`, `shouldDismiss`) and forwards to service.
- Uses `speechRecognizer` for voice-driven progression in non-classic modes.

## `SpeechRecognizer`

### Behavior modes

- Apple backend: on-device speech with authorization checks and retry/restart behavior.
- Deepgram backend: WebSocket streaming audio and transcript updates.
- Optional Smart Resync: OpenAI-assisted forward-only offset correction at speaking pauses.

### Matching model

- Combines character-level fuzzy matching and word-level matching.
- Uses annotation-aware logic to skip non-speech tokens (e.g. bracket cues).
- Maintains `recognizedCharCount` as canonical progression metric.

## `BrowserServer`

### Runtime contract

- Serves a built-in browser viewer page over HTTP on `browserServerPort`.
- Streams JSON state over WebSocket on `browserServerPort + 1`.
- Broadcast cadence: timer-driven updates every 0.1s while content is active.

## `ExternalDisplayController`

### Runtime contract

- Targets non-main display by configured ID fallback.
- Renders synchronized progression with optional mirror transform.
- Dismisses external panel when primary speech progression signals completion.

## Persistence classes

### `WorkspacePersistence`

- Stores autosave payload in UserDefaults key `focuscue.workspace.v3`.
- Uses delayed save scheduling and immediate flush API for shutdown paths.

### `DraftFileStore`

- Stores workspace index and per-page files in `~/Documents/FocusCue` tree.
- Supports page-file relocation when module changes (Live/Archive).
- Provides page trash path for deleted pages.

## Settings surface and effect matrix

The settings surface is defined by `NotchSettings` and operated by `SettingsView`.

| Setting | Persisted key | Runtime effect |
| --- | --- | --- |
| `speechBackend` | `speechBackend` | Switches speech recognition backend (Apple/Deepgram). |
| `deepgramAPIKey` | Keychain | Enables Deepgram streaming when backend is cloud mode. |
| `openaiAPIKey` | Keychain | Enables Smart Resync and draft refinement API calls. |
| `llmResyncEnabled` | `llmResyncEnabled` | Enables pause-triggered AI offset correction in recognition flow. |
| `refinementModel` | `refinementModel` | Selects OpenAI model for draft refinement requests. |
| `speechLocale` | `speechLocale` | Sets locale for Apple speech recognizer initialization. |
| `listeningMode` | `listeningMode` | Chooses progression model (word tracking, voice-activated, classic). |
| `selectedMicUID` | `selectedMicUID` | Routes capture to selected input device when supported. |
| `scrollSpeed` | `scrollSpeed` | Drives timer-based word progression in classic/voice-activated modes. |
| `overlayMode` | `overlayMode` | Selects overlay panel strategy (pinned/floating/fullscreen). |
| `notchDisplayMode` | `notchDisplayMode` | Controls pinned overlay display routing (follow mouse/fixed display). |
| `pinnedScreenID` | `pinnedScreenID` | Fixed target display for pinned mode. |
| `followCursorWhenUndocked` | `followCursorWhenUndocked` | Enables follow-cursor behavior in floating mode. |
| `floatingGlassEffect` | `floatingGlassEffect` | Enables glass-style floating background rendering. |
| `glassOpacity` | `glassOpacity` | Adjusts floating glass dark overlay opacity. |
| `fullscreenScreenID` | `fullscreenScreenID` | Sets fullscreen overlay target display. |
| `externalDisplayMode` | `externalDisplayMode` | Enables external output and mirror behavior. |
| `externalScreenID` | `externalScreenID` | Sets external target display ID. |
| `mirrorAxis` | `mirrorAxis` | Sets transform axis for mirror mode output. |
| `showElapsedTime` | `showElapsedTime` | Toggles elapsed timer overlays across surfaces. |
| `hideFromScreenShare` | `hideFromScreenShare` | Applies panel sharing policy for screen recording/sharing contexts. |
| `autoNextPage` | `autoNextPage` | Enables automatic page advance countdown at end of page. |
| `autoNextPageDelay` | `autoNextPageDelay` | Sets countdown seconds before auto page advance. |
| `browserServerEnabled` | `browserServerEnabled` | Starts/stops browser server listeners. |
| `browserServerPort` | `browserServerPort` | Sets HTTP port (WebSocket uses +1). |

## Contract table: URL scheme

| Interface | Example | Behavior |
| --- | --- | --- |
| `focuscue://read?text=...` | `focuscue://read?text=Welcome%20team` | Triggers `FocusCueService.handleURL(_:)` and starts direct read flow for provided text. |

Related files:
- [`../Info.plist`](../Info.plist)
- [`../FocusCue/FocusCueService.swift`](../FocusCue/FocusCueService.swift)

## Contract table: Browser JSON payload (`BrowserState`)

| Field | Type | Meaning |
| --- | --- | --- |
| `words` | `[String]` | Tokenized script words currently loaded in remote surface. |
| `highlightedCharCount` | `Int` | Current progression offset in characters. |
| `totalCharCount` | `Int` | Total script character count for active content. |
| `audioLevels` | `[Double]` | Recent audio waveform levels for visual indicator. |
| `isListening` | `Bool` | Whether speech capture is currently active. |
| `isDone` | `Bool` | True when progression reached total count. |
| `fontColor` | `String` | CSS-ready color for highlight text. |
| `hasNextPage` | `Bool` | Whether next page is available in sequence. |
| `isActive` | `Bool` | Whether content is actively being broadcast. |
| `highlightWords` | `Bool` | Indicates word-based highlighting mode for viewer behavior. |
| `lastSpokenText` | `String` | Recent recognized spoken text snippet. |

Related file:
- [`../FocusCue/BrowserServer.swift`](../FocusCue/BrowserServer.swift)

## Contract table: document formats and schema wrappers

| Format | Wrapper type | Primary use |
| --- | --- | --- |
| `.focuscue` | `FocusCueDocumentV3` | Native workspace save/open exchange format. |
| `workspace.index.json` | `DraftWorkspaceIndex` | Draft workspace snapshot + page file references. |
| `.focuscuepage.json` | `DraftPageDocument` | Per-page draft payload with module and page data. |

Related files:
- [`../FocusCue/SidebarModels.swift`](../FocusCue/SidebarModels.swift)
- [`../FocusCue/DraftFileStore.swift`](../FocusCue/DraftFileStore.swift)
- [`../FocusCue/FocusCueService.swift`](../FocusCue/FocusCueService.swift)

## Extension points

1. Add new listening modes by extending `ListeningMode`, progression logic in overlay/speech flows, and settings UI.
2. Add alternate speech providers behind `SpeechRecognizer` backend routing.
3. Add new output surfaces by following controller pattern used by browser/external output.
4. Extend document schema via new versioned wrappers with explicit compatibility handling.

## Known constraints

1. Browser server is local-network oriented and does not implement authenticated internet exposure.
2. Legacy array-only `.focuscue` format is rejected (no in-app migration path).
3. Deepgram and OpenAI features require valid user-provided API keys.
4. Some speech operations depend on runtime permission grants and hardware mic availability.
5. Overlay interaction model varies by mode (e.g., follow-cursor click-through behavior).
