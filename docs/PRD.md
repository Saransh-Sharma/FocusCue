# FocusCue Product Requirements Document (PRD)

## Document status

- Product: FocusCue
- Scope: macOS application + related local/remote output surfaces
- Coverage: current shipped behavior plus near-term roadmap
- Audience: users, product, engineering, QA, release owners

## Product definition

FocusCue is a macOS teleprompter workspace that keeps script delivery close to camera position while supporting speech-aware reading, multi-surface output, and local-first script management.

FocusCue enables presenters to:
- Prepare scripts in a multi-page workspace.
- Deliver naturally using voice-aware progression and highlighting.
- Run teleprompter output on primary overlay, external displays, and browser-based remote surfaces.
- Preserve work through autosave, page-level draft persistence, and native `.focuscue` files.

## Goals

1. Reduce presenter cognitive load during live delivery.
2. Keep script progress synchronized with spoken delivery across supported listening modes.
3. Provide flexible output surfaces without fragmenting the core authoring workflow.
4. Preserve script data safely with recoverable persistence and clear save semantics.
5. Keep setup and operation reliable for solo presenters and production workflows.

## Non-goals

1. General document collaboration (multi-user real-time editing).
2. Cross-platform native clients beyond macOS in current scope.
3. Cloud-first account system as a core requirement.
4. Full DAW/video editor functionality.
5. Generic slide authoring (FocusCue imports presenter notes but does not author slides).

## Personas and JTBD

### Persona A: Solo presenter

- Context: meetings, webinars, recordings.
- JTBD: "When I present live, I want my script to stay near my camera and advance with my speaking pace so I can maintain eye contact and reduce mistakes."

### Persona B: Content creator / educator

- Context: long-form lessons and scripted explainers.
- JTBD: "When I record structured content, I want to prepare, reorganize, and iterate script pages quickly while preserving my progress between sessions."

### Persona C: Operator / production support

- Context: mirrored rigs, external displays, remote monitors.
- JTBD: "When running production setups, I want stable external and browser outputs that reflect live progress with predictable controls and fallback behavior."

## Functional requirements

### FR-1 Script authoring and organization

| Requirement | Status |
| --- | --- |
| Multi-page workspace with Live Transcripts and Archive modules | Shipped |
| Add, rename, reorder, move, and delete pages | Shipped |
| Editable script text with live dirty-state indicators | Shipped |
| Page-level draft save and save-all dirty behavior | Shipped |

### FR-2 Playback and progression

| Requirement | Status |
| --- | --- |
| Start playback from selected live page | Shipped |
| Progress state reflected in overlay output | Shipped |
| Auto next page with countdown delay | Shipped |
| Manual next/previous/page jump interactions | Shipped |

### FR-3 Listening and speech guidance

| Requirement | Status |
| --- | --- |
| Word Tracking mode (speech-aligned highlighting) | Shipped |
| Voice-Activated mode (speak-to-scroll) | Shipped |
| Classic mode (timer-based scroll) | Shipped |
| Apple on-device backend support | Shipped |
| Deepgram cloud backend support | Shipped |
| Smart Resync using OpenAI API key | Shipped |

### FR-4 Output surfaces

| Requirement | Status |
| --- | --- |
| Pinned notch overlay mode | Shipped |
| Floating overlay and follow-cursor mode | Shipped |
| Fullscreen overlay mode | Shipped |
| External display teleprompter/mirror output | Shipped |
| Browser remote output server | Shipped |

### FR-5 File operations and import

| Requirement | Status |
| --- | --- |
| Save/open native `.focuscue` workspace files | Shipped |
| URL scheme read entrypoint (`focuscue://read?text=...`) | Shipped |
| macOS Services entrypoint for selected text | Shipped |
| `.pptx` presenter notes import | Shipped |

### FR-6 Guidance, setup, and system integration

| Requirement | Status |
| --- | --- |
| First-run onboarding with permissions flow | Shipped |
| Settings for appearance, guidance, surfaces, remote | Shipped |
| Update checks against GitHub releases | Shipped |
| Signed/notarized release workflow support | Shipped |

## Non-functional requirements

| Area | Requirement |
| --- | --- |
| Reliability | Editing and playback operations should not lose script state under normal termination paths; autosave and draft index should flush on app termination. |
| Responsiveness | Main editing UI should remain interactive while background import/parsing and network calls run asynchronously. |
| Safety/Privacy | API keys must be stored in Keychain, not plaintext config files. |
| Permissions | Microphone and speech recognition access should use explicit user prompts and clear fallback guidance when denied. |
| UX continuity | Workspace selection, page context, and read-state transitions should remain coherent when jumping pages or switching modes. |
| Distribution | Build/release pipeline should support code signing, notarization, and DMG distribution artifacts. |

## Shipped capabilities (current)

### Workspace and page model

- `ScriptWorkspace` with `livePages`, `archivePages`, `selectedPageID`, `nextPageCounter`.
- `FocusCueDocumentV3` schema wrapper for native document save/load.
- Auto-title generation and custom-title behavior for pages.

### Playback and overlay

- Multi-mode overlay controller with pinned/floating/follow-cursor/fullscreen modes.
- Read progress synchronization to overlay content, external display, and browser remote state.
- Page picker, done-state transitions, and auto-advance countdown.

### Speech and AI

- Apple Speech + Deepgram backend support with selected microphone routing.
- Fuzzy spoken-word matching and annotation-aware progression logic.
- Optional Smart Resync and draft refinement via OpenAI API key.

### Persistence and operations

- UserDefaults autosave (`WorkspacePersistence`) and file-backed page drafts (`DraftFileStore`).
- Dirty-state detection using digest comparison against saved draft references.
- `.pptx` notes extraction and conversion into live transcript pages.

## Planned (near-term) roadmap

The following roadmap items are intended for near-term releases and are not yet committed as shipped behavior.

### R1: Diagnostic observability for speech and output health

- Goal: improve field debugging for microphone routing, recognition dropouts, and output synchronization.
- Planned acceptance criteria:
  1. Add an internal diagnostics panel with current backend, selected mic UID, and active output surfaces.
  2. Add structured debug event stream for key state transitions (start, stop, resume, page advance, backend switch).
  3. Ensure diagnostics can be toggled without changing normal user-facing behavior.

### R2: Stronger recovery affordances for unsaved and failed draft pages

- Goal: make recovery paths explicit when draft file relocation/trash/save fails.
- Planned acceptance criteria:
  1. Surface save-failure details for affected page IDs in a recoverable UI state.
  2. Provide explicit retry action at page level and batch level.
  3. Preserve non-failed pages and avoid blocking playback when unrelated saves fail.

### R3: Remote output hardening and operator quality-of-life

- Goal: improve reliability for browser remote sessions on variable local networks.
- Planned acceptance criteria:
  1. Add connection state banner (connected clients, last message time).
  2. Add explicit remote session reset action from settings.
  3. Add clear port conflict guidance when selected port is unavailable.

### R4: Expanded test coverage for core state machines

- Goal: reduce regressions in service orchestration and persistence behavior.
- Planned acceptance criteria:
  1. Unit tests for page movement, dirty-state transitions, and schema guardrails.
  2. Integration tests for save/open/import flows across `.focuscue` and `.pptx` paths.
  3. Smoke tests validating build and launch command paths in CI.

## Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Speech backend instability or permission denials | Playback unusable in speech-dependent modes | Keep Classic mode available and provide clear permission recovery actions in onboarding/settings. |
| Draft persistence path failures | Unsaved page confusion or partial save behavior | Maintain digest-based dirty tracking, explicit save-failed markers, and termination-time flush. |
| Network/port collisions for browser server | Remote surface unavailable | Allow configurable port, restart path, and operator diagnostics. |
| Release-signing misconfiguration | Distribution delays | Maintain secrets checklist and staged release validation pipeline. |

## Release-readiness checklist

1. Build validation passes for Debug and Release configurations.
2. Manual smoke test for each overlay mode (pinned, floating, follow-cursor, fullscreen).
3. Manual smoke test for listening modes (Classic, Voice-Activated, Word Tracking).
4. Confirm external display and browser remote output behavior.
5. Confirm `.focuscue` save/open, `.pptx` import, and unsaved-change prompts.
6. Validate onboarding permission flows on a clean profile.
7. Validate update check path and release metadata integrity.
8. For tagged releases: code signing, notarization, DMG generation, and GitHub release upload complete.

## Primary implementation references

- [`../FocusCue/FocusCueService.swift`](../FocusCue/FocusCueService.swift)
- [`../FocusCue/ContentView.swift`](../FocusCue/ContentView.swift)
- [`../FocusCue/NotchOverlayController.swift`](../FocusCue/NotchOverlayController.swift)
- [`../FocusCue/SpeechRecognizer.swift`](../FocusCue/SpeechRecognizer.swift)
- [`../FocusCue/BrowserServer.swift`](../FocusCue/BrowserServer.swift)
- [`../FocusCue/ExternalDisplayController.swift`](../FocusCue/ExternalDisplayController.swift)
- [`../FocusCue/WorkspacePersistence.swift`](../FocusCue/WorkspacePersistence.swift)
- [`../FocusCue/DraftFileStore.swift`](../FocusCue/DraftFileStore.swift)
- [`../FocusCue/SettingsView.swift`](../FocusCue/SettingsView.swift)
- [`../FocusCue/OnboardingWizardView.swift`](../FocusCue/OnboardingWizardView.swift)
- [`../build.sh`](../build.sh)
- [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml)
- [`../.github/workflows/release.yml`](../.github/workflows/release.yml)
