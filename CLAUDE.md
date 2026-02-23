# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Verify

```bash
# Debug build (use this to verify changes compile)
xcodebuild -project FocusCue.xcodeproj -scheme FocusCue -configuration Debug -destination "platform=macOS" CODE_SIGNING_ALLOWED=NO -quiet

# Universal binary + DMG (local release)
./build.sh
```

There are no test targets. No linter is configured. **Fix all warnings before committing.**

## Project Overview

FocusCue is a native macOS menubar teleprompter app. It overlays scrolling script text on screen and tracks the user's speech to highlight words in real time. Built entirely in Swift/SwiftUI with zero external dependencies.

**Target:** macOS 15.7+ (Sequoia), universal binary (arm64 + x86_64).

## Architecture

**Central service:** `FocusCueService` (singleton, `@Observable`) owns the `ScriptWorkspace` model and all mutations. Every mutation flows through `commitWorkspaceChange()` which normalizes state, reconciles drafts, tracks dirty state, and schedules autosave.

**Data model:** `ScriptWorkspace` contains `livePages: [ScriptPage]` (active) and `archivePages: [ScriptPage]` (storage). On-disk format is `.focuscue` (JSON-encoded `FocusCueDocumentV3`, schema version 3).

**Two persistence layers:**
- `WorkspacePersistence` — debounced UserDefaults autosave (workspace snapshot, 0.35s)
- `DraftFileStore` — per-page files at `~/Documents/FocusCue/` as `.focuscuepage.json` + `workspace.index.json`

**Overlay system:** `NotchOverlayController` manages an `NSPanel` in three modes: pinned-to-notch, floating window, or fullscreen. `SpeechRecognizer` drives word highlighting via `recognizedCharCount` which `SpeechScrollView` (in `MarqueeTextView.swift`) consumes.

**Listening modes:** Word Tracking (Apple Speech / Deepgram with optional GPT-4o-mini resync), Voice-Activated (scroll on audio, pause on silence), Classic (constant-speed auto-scroll, no mic).

**Browser remote:** `BrowserServer` runs local HTTP + WebSocket to mirror the teleprompter in any browser on the same network.

## Key Conventions

**State management:** All observable models use `@Observable` macro (not `ObservableObject`). Singletons accessed as `FocusCueService.shared`, `NotchSettings.shared`, etc. SwiftUI views observe via `@State private var service = FocusCueService.shared`. Settings persist via `didSet { UserDefaults.standard.set(...) }`. API keys go in Keychain via `KeychainStore`.

**Design token system (`MainWindowTheme.swift`):** All main-window UI must use `FCColorToken`, `FCTypographyToken`, `FCSpacingToken`, `FCShapeToken`, etc. via `FCTheme`. Do not use ad hoc constants for colors, spacing, radii, or typography. Animations must go through `FCTheme.animation()` / `FCTheme.spring()` to respect reduce-motion. Reference: `docs/design-tokens.md`.

**Reusable components (`MainWindowComponents.swift`):** `FCGlassPanel`, `FCWindowBackdrop`, `FCWindowHeader`, `FCPageRail`. Responsive layout breakpoints: compact width < 1220pt, compact height < 760pt.

**Accessibility:** 4.5:1 contrast minimum for body text, 32x32pt minimum touch targets, reduce-motion replaces movement with opacity transitions (max 12pt movement).

## Swift Style

- Prefer `let` over `var`; use `async`/`await` and `@MainActor` over Combine/completion handlers
- Prefer `struct`/`enum` over `class` unless identity semantics are needed
- Keep SwiftUI view bodies under ~40 lines; extract `@ViewBuilder` subviews
- Avoid force-unwrap (`!`) and force-cast (`as!`) outside tests/previews
- Avoid comments; if needed, explain "why" not "what"
- Avoid unnecessary types/protocols/extensions; inline when used in one place

## Commit Discipline

- Commit after every discrete action with concise imperative messages
- Do not batch unrelated changes; keep commits small and reviewable
- For releases: bump version + build number, commit, push, `gh release create` (no `--draft`)
