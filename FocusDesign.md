---
version: alpha
name: FocusCue Design System
description: Dark-first design system for FocusCue's macOS teleprompter workspace, live overlays, external displays, browser remote, onboarding, and settings.
colors:
  canvas-black: "#131313"
  surface-slate: "#2D2D2D"
  surface-raised: "#1B1B1B"
  surface-inset: "#0F0F0F"
  frame-gray: "#313131"
  hazard-white: "#FFFFFF"
  absolute-black: "#000000"
  text-primary: "#FFFFFF"
  text-secondary: "#949494"
  text-muted: "#E9E9E9"
  text-inverted: "#131313"
  cue-mint: "#3CFFD0"
  cue-mint-border: "#309875"
  resync-violet: "#5200FF"
  violet-rule: "#3D00BF"
  hover-blue: "#3860BE"
  focus-cyan: "#1EAEDB"
  read-yellow: "#FFD60A"
  recording-pink: "#FF6191"
  teleprompter-orange: "#FF9E0A"
  success-green: "#22C55E"
  warning-amber: "#FACC15"
  error-violet: "#5200FF"
  disabled-gray: "#5A5A5A"
  divider-white: "#FFFFFF"
typography:
  display-hero:
    fontFamily: "CondensedDisplay, Impact, Helvetica Neue, sans-serif"
    fontSize: 72px
    fontWeight: 900
    lineHeight: 0.9
    letterSpacing: 0.01em
  display-compact:
    fontFamily: "CondensedDisplay, Impact, Helvetica Neue, sans-serif"
    fontSize: 60px
    fontWeight: 900
    lineHeight: 0.95
    letterSpacing: 0.01em
  title-lg:
    fontFamily: "SF Pro Display, Helvetica Neue, Arial, sans-serif"
    fontSize: 34px
    fontWeight: 700
    lineHeight: 1
    letterSpacing: 0em
  title-md:
    fontFamily: "SF Pro Display, Helvetica Neue, Arial, sans-serif"
    fontSize: 24px
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: 0em
  title-sm:
    fontFamily: "SF Pro Text, Helvetica Neue, Arial, sans-serif"
    fontSize: 20px
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: 0em
  body:
    fontFamily: "SF Pro Text, Helvetica Neue, Arial, sans-serif"
    fontSize: 16px
    fontWeight: 500
    lineHeight: 1.6
    letterSpacing: 0em
  body-compact:
    fontFamily: "SF Pro Text, Helvetica Neue, Arial, sans-serif"
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: 0em
  script-lg:
    fontFamily: "SF Pro Display, Helvetica Neue, Arial, sans-serif"
    fontSize: 24px
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: 0em
  script-xl:
    fontFamily: "SF Pro Display, Helvetica Neue, Arial, sans-serif"
    fontSize: 48px
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: 0em
  script-display:
    fontFamily: "SF Pro Display, Helvetica Neue, Arial, sans-serif"
    fontSize: 72px
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: 0em
  label-caps:
    fontFamily: "SF Mono, ui-monospace, monospace"
    fontSize: 12px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: 0.14em
  mono-timestamp:
    fontFamily: "SF Mono, ui-monospace, monospace"
    fontSize: 11px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: 0.12em
  mono-button:
    fontFamily: "SF Mono, ui-monospace, monospace"
    fontSize: 12px
    fontWeight: 600
    lineHeight: 2
    letterSpacing: 0.13em
  counter:
    fontFamily: "SF Mono, ui-monospace, monospace"
    fontSize: 10px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0.15em
spacing:
  micro-2: 2px
  micro-4: 4px
  micro-6: 6px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 20px
  xl: 24px
  xxl: 32px
  feature: 40px
  hero: 48px
  section: 64px
  outer-mobile: 24px
  outer-desktop: 48px
  timeline-gap: 14px
  grid-gutter: 24px
rounded:
  xs: 2px
  sm: 4px
  md: 20px
  lg: 24px
  xl: 30px
  xxl: 40px
  overlay: 16px
  full: 999px
components:
  window-shell:
    background: "{colors.canvas-black}"
    foreground: "{colors.text-primary}"
    border: "1px solid {colors.frame-gray}"
    radius: "{rounded.lg}"
    padding: "{spacing.md}"
  panel:
    background: "{colors.surface-slate}"
    foreground: "{colors.text-primary}"
    border: "1px solid {colors.hazard-white}"
    radius: "{rounded.md}"
    padding: "{spacing.xl}"
  feature-panel:
    background: "{colors.canvas-black}"
    foreground: "{colors.text-primary}"
    border: "1px solid {colors.cue-mint}"
    radius: "{rounded.lg}"
    padding: "{spacing.xxl}"
  primary-button:
    background: "{colors.cue-mint}"
    foreground: "{colors.absolute-black}"
    border: "none"
    radius: "{rounded.lg}"
    padding: "10px 24px"
    typography: "{typography.mono-button}"
    hover: "background {colors.hover-blue}; foreground {colors.hazard-white}"
    active: "background {colors.disabled-gray}; opacity 0.65"
    focus: "background {colors.focus-cyan}; border 1px solid {colors.resync-violet}"
    disabled: "background {colors.disabled-gray}; foreground {colors.text-secondary}; opacity 0.55"
  secondary-button:
    background: "{colors.surface-slate}"
    foreground: "{colors.text-muted}"
    border: "1px solid {colors.frame-gray}"
    radius: "{rounded.lg}"
    padding: "10px 24px"
    typography: "{typography.body-compact}"
    hover: "background {colors.hazard-white}; foreground {colors.absolute-black}"
    focus: "border 1px solid {colors.focus-cyan}"
  outline-button:
    background: "transparent"
    foreground: "{colors.cue-mint}"
    border: "1px solid {colors.cue-mint}"
    radius: "{rounded.xxl}"
    padding: "10px 20px"
    typography: "{typography.mono-button}"
    hover: "background {colors.cue-mint}; foreground {colors.absolute-black}"
  timeline-row:
    background: "{colors.canvas-black}"
    foreground: "{colors.text-primary}"
    border: "1px solid {colors.hazard-white}"
    rail: "1px solid {colors.violet-rule}"
    radius: "{rounded.md}"
    padding: "{spacing.lg}"
    typography: "{typography.body-compact}"
    hover: "headline color {colors.hover-blue}"
    active: "border 1px solid {colors.cue-mint}"
  script-editor:
    background: "{colors.surface-inset}"
    foreground: "{colors.text-primary}"
    border: "1px solid {colors.frame-gray}"
    radius: "{rounded.md}"
    padding: "{spacing.xl}"
    typography: "{typography.body}"
    focus: "border 1px solid {colors.cue-mint}"
    error: "border 1px solid {colors.error-violet}"
  chip:
    background: "{colors.surface-slate}"
    foreground: "{colors.text-muted}"
    border: "1px solid {colors.frame-gray}"
    radius: "{rounded.full}"
    padding: "4px 10px"
    typography: "{typography.label-caps}"
  input:
    background: "{colors.canvas-black}"
    foreground: "{colors.text-primary}"
    placeholder: "{colors.text-secondary}"
    border: "1px solid {colors.text-secondary}"
    radius: "{rounded.xs}"
    padding: "8px 10px"
    typography: "{typography.body-compact}"
    focus: "border 1px solid {colors.cue-mint}"
    error: "border 1px solid {colors.error-violet}"
  mode-segment:
    background: "{colors.canvas-black}"
    foreground: "{colors.text-secondary}"
    border: "1px solid {colors.frame-gray}"
    radius: "{rounded.full}"
    padding: "8px 12px"
    typography: "{typography.label-caps}"
    selected: "background {colors.cue-mint}; foreground {colors.absolute-black}"
    locked: "foreground {colors.disabled-gray}; border 1px solid {colors.disabled-gray}"
  overlay-readout:
    background: "{colors.absolute-black}"
    foreground: "{colors.text-primary}"
    border: "1px solid {colors.frame-gray}"
    radius: "{rounded.overlay}"
    padding: "{spacing.md}"
    typography: "{typography.script-lg}"
    active-word: "{colors.read-yellow}"
    spoken-word: "{colors.cue-mint}"
  status-notice:
    background: "{colors.surface-slate}"
    foreground: "{colors.text-muted}"
    border: "1px solid {colors.frame-gray}"
    radius: "{rounded.md}"
    padding: "{spacing.md}"
    typography: "{typography.body-compact}"
---

# FocusCue Design System

## Overview

FocusCue is a camera-first teleprompter workspace. Its interface should feel like a live production console attached to a precise script timeline: dark, legible, fast to scan, and unmistakably focused on delivery.

The system is dark-first. The default screen is `canvas-black`, with solid panels, 1px rules, uppercase metadata, and saturated control accents. The app should not feel like a soft glass dashboard, a marketing site, or a generic document editor. It should feel like a tool used right before and during a real recording, livestream, or presentation.

The design language has three modes:

- **Writing mode:** quiet, dense, and stable. The script editor and page rail should lower cognitive load while preserving save state, page order, and playback readiness.
- **Live mode:** high contrast and minimal. Overlay, floating, fullscreen, external display, and browser remote surfaces should remove all nonessential chrome.
- **Operator mode:** precise and diagnostic. Settings, onboarding, permissions, remote status, and import states should communicate system readiness clearly.

Script readability outranks visual style. Current spoken words, unread words, annotations, page progress, microphone state, and output status must always remain clearer than decorative identity.

## Colors

The palette is built from a near-black canvas, white text, slate panels, and a small set of saturated functional accents. Color is applied as a solid signal, not as a soft atmospheric wash.

- **Canvas Black (`#131313`):** The default app background and the baseline for overlay surfaces.
- **Surface Slate (`#2D2D2D`):** Secondary panels, inactive grouped controls, and settings cards.
- **Surface Inset (`#0F0F0F`):** Script editor wells, remote output canvas, and embedded readout zones.
- **Frame Gray (`#313131`):** Image frames, panel separators, and quiet borders.
- **Hazard White (`#FFFFFF`):** Primary text and high-attention borders on dark surfaces.
- **Cue Mint (`#3CFFD0`):** The ready, start, synced, active, selected, and primary-action accent.
- **Cue Mint Border (`#309875`):** The restrained mint used when pure mint would vibrate.
- **Resync Violet (`#5200FF`):** Smart resync, AI-assisted recovery, alert, and interruption color.
- **Violet Rule (`#3D00BF`):** Timeline rail and structural rule accent.
- **Hover Blue (`#3860BE`):** Universal hover color for link-like text.
- **Focus Cyan (`#1EAEDB`):** Keyboard focus only. Do not use it as decoration.
- **Read Yellow (`#FFD60A`):** Active read progress and current-word highlighting when a warmer cue is needed.
- **Recording Pink (`#FF6191`):** Recording, microphone capture, and stop/urgent delivery controls.
- **Teleprompter Orange (`#FF9E0A`):** Output routing, external display, mirror rig, and import states.

Use accent fills sparingly. A mint fill means "this is ready or primary." A violet fill means "this is exceptional, assisted, or needs attention." Yellow, pink, and orange must stay tied to live reading, recording, and output workflows.

Do not create gradients, glows, tinted blobs, or soft background washes from these colors. A colored panel should be a deliberate block. A colored border should be a deliberate rule.

## Typography

Typography carries the product's rhythm: large display type for rare brand moments, compact sans text for the app, uppercase mono for operator metadata, and high-legibility script text for delivery.

- **Display:** Use `display-hero` and `display-compact` only for the app title, onboarding hero moments, and major feature cards. Display type must be 60px or larger. Never use display type for buttons, settings, navigation, or body copy.
- **UI headlines:** Use `title-lg`, `title-md`, and `title-sm` for panel titles, section headings, onboarding steps, and feature callouts.
- **Body:** Use `body` for readable explanatory text and `body-compact` for helper copy, captions, secondary descriptions, settings rows, and import guidance.
- **Script:** Use `script-lg`, `script-xl`, and `script-display` for reading surfaces. Script type should be semibold, high contrast, and spacious enough for camera-adjacent reading.
- **Mono labels:** Use `label-caps`, `mono-timestamp`, `mono-button`, and `counter` for page metadata, timestamps, mode labels, badges, counters, compact buttons, timer readouts, and remote connection state.

Mono labels are always uppercase. Lowercase mono text is not part of this system. Timestamps, page counts, save badges, locked markers, listening modes, output labels, browser status, and import file types should all use uppercase mono with visible tracking.

Annotations such as `[pause]`, `[smile]`, or `[look camera]` should be distinct but quiet: italic or muted, never competing with spoken words. Annotation styling should make stage direction obvious without breaking reading flow.

## Layout

FocusCue layouts use a dense 8px rhythm with strict reading zones and clear operator rails.

The main window should keep the current mental model:

- Left rail: pages, live/archive grouping, dirty state, locks, save markers, and ordering.
- Center: script editor as the dominant working surface.
- Lower or side action area: run controls, listening mode, document actions, settings, and onboarding entry.

Spacing should follow these defaults:

- 2, 4, and 6px for label clusters, badges, icon-label alignment, and dense control internals.
- 8px for repeated compact rows.
- 12-16px for timeline items, mode controls, settings rows, and action tile gaps.
- 20-32px for panel padding.
- 40-48px for onboarding and major feature moments only.
- 64px for large section separation in docs or marketing-like views, not app panels.

The page rail should behave like a script timeline. Live Transcripts and Archive are not generic lists; they are ordered rails with page numbers, read state, save state, and playback eligibility. A vertical rule, numbered rows, and uppercase metadata should communicate sequence.

On compact widths, keep a single-column flow: page rail first, script editor second, run/action controls third. Do not shrink script text below readable limits to preserve a desktop layout.

## Elevation & Depth

Depth is flat and explicit. Use borders, insets, active underlines, and solid fills instead of shadows.

Elevation levels:

| Level | Treatment | Use |
|---|---|---|
| 0 | `canvas-black`, no border | Root app canvas, fullscreen teleprompter |
| 1 | `surface-inset` with `frame-gray` border | Script editor, browser remote canvas, text wells |
| 2 | `surface-slate` with `frame-gray` border | Settings cards, secondary panels, inactive controls |
| 3 | `canvas-black` with `hazard-white` border | Timeline rows, primary dark panels |
| 4 | `cue-mint` border or fill | Ready, selected, synced, primary action |
| 5 | `resync-violet` border or fill | Smart resync, alert, AI-assisted recovery |
| 6 | `recording-pink`, `read-yellow`, or `teleprompter-orange` fill | Live recording, current progress, external output |

Avoid drop shadows as hierarchy. A shadow may be used only as a platform escape hatch for a detached floating panel that would otherwise disappear against arbitrary desktop content. Even then, keep it subtle and secondary to the 1px frame.

No decorative blur fields, glow rings, soft orbs, or atmospheric gradients. Overlay readability fades are allowed only when they protect script legibility at the top or bottom edge of a scrolling prompter.

## Shapes

The radius scale communicates hierarchy:

- **2px:** Inputs, text fields, validation wells, and precise system forms.
- **4px:** Inline media, screenshots, image frames, and embedded previews.
- **16px:** Floating overlay and compact live readout containers.
- **20px:** Standard panels, timeline rows, settings cards, and dense content containers.
- **24px:** Feature panels, primary pills, and important grouped controls.
- **30px:** Promotional or onboarding action pills.
- **40px:** Large outline pills and high-emphasis secondary actions.
- **999px:** Capsules, chips, badges, icon circles, status dots, and segmented control tracks.

Do not use square cards. If a rectangular element is interactive or content-bearing, it should sit on this radius scale.

## Components

### Main Window Shell

The main window is the authoring cockpit. Use `canvas-black` for the root, `surface-slate` or `canvas-black` for panels, and 1px rules for separation. Remove decorative background circles, blurred color fields, glass-card stacking, and heavy shadows in the target presentation layer.

The header should identify FocusCue without becoming a landing-page hero. Use compact title typography, a small icon, and a concise status or entitlement widget. The product name may use display type only in onboarding or brand-focused empty states, not in the daily main window.

### Page Rail / Script Timeline

The page rail should read as a sequence:

- Use a vertical `violet-rule` rail or left border for live page groups.
- Page numbers, module names, counts, save markers, and lock labels use uppercase mono.
- Selected page uses a `cue-mint` border or inset underline.
- Dirty page uses `warning-amber`; save-failed uses `resync-violet`.
- Read pages use a solid `success-green` dot or check.
- Locked pages use muted text and a clear lock marker, not reduced opacity alone.

Rows should not lift or scale on hover. Hover changes the row headline/title color to `hover-blue` or reveals row actions.

### Script Editor

The script editor is the quietest surface in the app. It should feel stable enough for long script writing.

- Background: `surface-inset` or `canvas-black`.
- Text: `text-primary`, with selection/read overlays using functional accents.
- Border: `frame-gray` at rest, `cue-mint` when focused.
- Save-failed state: `resync-violet` border plus concise helper text.
- Empty state: a muted prompt with one mint outline action.

Do not put the editor inside nested cards. The editor itself is the surface.

### Action Bar and Run Controls

The primary run button is a mint pill with black uppercase mono text. It should be the strongest control on the authoring screen.

- Ready to start: `cue-mint` fill, `absolute-black` text.
- Running or stop: `recording-pink` fill or border, direct stop label.
- Output-related actions: `teleprompter-orange`.
- Smart draft or resync actions: `resync-violet`.
- Secondary actions: dark slate pills or outlined icon tiles.

Do not use gradients or glow shadows for run controls. State is communicated through fill, border, label, and icon.

### Listening Mode Selector

Listening modes are a segmented operator control. Each mode must show its current state and requirements:

- Word Tracking: mint selected state when ready, violet notice if speech recognition is unavailable.
- Voice-Activated: mint selected state, pink recording/mic activity when live.
- Classic: neutral selected state because it does not require speech.

Locked or unavailable modes must include a lock marker and concise reason. Do not rely on disabled opacity alone.

### Overlay / Notch Prompt

The pinned overlay stays black and minimal. It should preserve the feeling of the Mac notch while making script progress clear.

- Background: `absolute-black`.
- Radius: dynamic, but aligned with the 16-20px overlay scale.
- Script: `script-lg`, user-adjustable by settings.
- Current word or read progress: `read-yellow`, `cue-mint`, or the selected prompter color.
- Last spoken text: muted, compact, and visually secondary.
- Waveform: low-contrast bars that brighten with live input.
- Timer/counter: uppercase mono.

Page picker, done state, and auto-next countdown should use the same flat border/fill language.

### Floating and Fullscreen Prompter

Floating overlay uses `absolute-black` or `surface-inset` with a 16px radius and a 1px frame. It must avoid decorative shine. If the user enables a platform glass effect, treat it as an optional material behind an otherwise token-driven readout.

Fullscreen prompter and external display prompter should strip away the app chrome. The only persistent elements should be script, progress/audio telemetry, elapsed time if enabled, and essential next/done affordances.

### External Display and Browser Remote

External display and browser remote are delivery surfaces, not control dashboards.

- Use full-screen `absolute-black`.
- Use `script-xl` or `script-display` depending on viewport width.
- Preserve large horizontal padding for eye-line reading.
- Bottom status bar may include waveform, last spoken text, mic state, progress, and connection status.
- Waiting state should use a simple drawn/symbolic signal, not emoji.
- Connection text, port, and remote status use uppercase mono.

Browser remote should mirror external display typography and color behavior closely enough that users can switch between them without relearning the output surface.

### Onboarding

Onboarding introduces the production workflow, not a marketing story. Use fewer words, stronger choices, and visible state.

- Welcome may use `display-compact` with a solid mint or white accent.
- Mode and surface selection uses large option panels with 1px borders.
- Permission steps use serious notices: muted body text, explicit action pills, and clear recovery paths.
- Ready state uses a simple success marker and a primary mint action.

Avoid celebratory visual noise. Onboarding should make setup feel controlled.

### Settings

Settings are an operator panel. Use dense rows, strong tab rails, clear labels, and explicit state badges.

- Tab rail selected state uses `cue-mint` underline or border.
- Section cards use `surface-slate` and 1px `frame-gray`.
- Destructive or risky settings use violet or pink bordered notices.
- API key fields use the input token and never expose key material in decorative previews.
- Remote browser port and output routing should use mono counters and status badges.

Settings should make it obvious what affects the current live run, what requires permission, and what is only available in a specific distribution profile.

### Import / Drop Zone

The drop zone is an interruption state. Use a large dashed `teleprompter-orange` or `cue-mint` border, a concise title, and a clear accepted-file label.

Avoid pulsing glows. If motion is used, animate border opacity only. File type labels such as `PPTX` use uppercase mono chips.

### Empty, Error, Permission, Locked, and Done States

- **Empty:** muted text, one primary action, optional mono hint.
- **Error:** violet border, concise cause, explicit retry or settings action.
- **Permission denied:** serious notice with direct system-settings action.
- **Locked:** visible lock marker, muted row, upgrade or explanation action only when useful.
- **Done:** solid success marker, short label, no confetti or decorative burst.

States must include enough text to recover without making the screen feel like documentation.

## Do's and Don'ts

### Do

- Do use `canvas-black` as the default app and output canvas.
- Do use solid accent fills for primary state changes.
- Do use 1px borders, rails, and active underlines for hierarchy.
- Do use uppercase mono for timestamps, counters, mode labels, badges, compact buttons, and page metadata.
- Do keep script text large, high contrast, and visually dominant during delivery.
- Do use `cue-mint` for ready, active, synced, selected, and start states.
- Do use `resync-violet` for smart resync, alert, AI-assisted recovery, and exceptional error states.
- Do use `hover-blue` for link-like hover text.
- Do keep browser remote and external display surfaces minimal.
- Do respect Reduce Motion with opacity, border, and color changes instead of movement.

### Don't

- Don't make the default app surface light.
- Don't use soft dashboard glass, decorative blur fields, color orbs, glow shadows, or atmospheric gradients.
- Don't use drop shadows for normal hierarchy.
- Don't put UI cards inside other cards.
- Don't use display type below 60px or inside controls.
- Don't use lowercase mono text.
- Don't use accent colors as faint background washes.
- Don't add new accent colors unless they map to a real FocusCue state.
- Don't let control chrome compete with the script during live delivery.
- Don't use emoji in browser remote, waiting states, settings notices, or onboarding.
