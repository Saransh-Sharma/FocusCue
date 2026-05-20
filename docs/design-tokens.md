# FocusCue Design Tokens

## Purpose

This file documents the tokenized presentation layer used by FocusCue's macOS app surfaces. The visual source of truth is `/Users/saransh1337/Developer/Projects/FocusCue/FocusDesign.md`; the code source of truth is `/Users/saransh1337/Developer/Projects/FocusCue/FocusCue/MainWindowTheme.swift`.

The system is dark-first and production-console oriented. New UI should use `FCTheme`, `FCColorToken`, `FCTypographyToken`, `FCSpacingToken`, and `FCShapeToken` instead of ad hoc visual constants.

## Color Tokens

| Token | Value | Usage |
|---|---:|---|
| `canvasBlack` | `#131313` | Root app canvas and default app background |
| `surfaceSlate` | `#2D2D2D` | Settings cards, secondary panels, inactive controls |
| `surfaceRaised` | `#1B1B1B` | Header/sidebar raised strips and active containers |
| `surfaceInset` | `#0F0F0F` | Script editor, remote output wells, embedded readouts |
| `absoluteBlack` | `#000000` | Live overlay, fullscreen, external display, browser remote |
| `frameGray` | `#313131` | 1px borders, dividers, control frames |
| `hazardWhite` / `textPrimary` | `#FFFFFF` | High-priority text and critical borders |
| `textSecondary` | `#949494` | Secondary text and helper copy |
| `textMuted` | `#E9E9E9` | Muted but readable text on black |
| `cueMint` | `#3CFFD0` | Ready, start, selected, synced, active states |
| `cueMintBorder` | `#309875` | Restrained mint border when fill would vibrate |
| `resyncViolet` | `#5200FF` | Smart resync, assisted recovery, exceptional errors |
| `violetRule` | `#3D00BF` | Timeline rail and structural rule accent |
| `hoverBlue` | `#3860BE` | Link-like hover and secondary navigation emphasis |
| `focusCyan` | `#1EAEDB` | Keyboard focus only |
| `readYellow` | `#FFD60A` | Current read progress and active word cues |
| `recordingPink` | `#FF6191` | Recording, microphone capture, stop/urgent controls |
| `teleprompterOrange` | `#FF9E0A` | Output routing, import, external display states |
| `stateSuccess` | `#22C55E` | Read/done/success markers |
| `stateWarning` | `#FACC15` | Dirty or incomplete states |
| `disabledGray` | `#5A5A5A` | Locked and unavailable controls |

The only retained compatibility aliases are `accentPrimary`, `borderFocus`, and legacy background canvas names used by older preview/debug code. Production UI should use explicit FocusDesign token names.

## Typography Tokens

| Token | Size | Role |
|---|---:|---|
| `displayHero` | `72` | Rare brand/onboarding title moments |
| `displayCompact` | `60` | Compact brand/onboarding display |
| `titleLg` | `34` | Major panel and onboarding headings |
| `titleMd` | `24` | Section titles |
| `titleSm` | `20` | Dense panel headings |
| `body` | `16` | Readable explanatory text |
| `bodyCompact` | `13` | Helper copy, settings rows, captions |
| `scriptLg` / `scriptXl` / `scriptDisplay` | `24 / 48 / 72` | Teleprompter reading surfaces |
| `labelCaps`, `monoTimestamp`, `monoButton`, `counter` | `10-12` | Uppercase operator metadata, buttons, counters |

Mono labels are uppercase in UI copy. Use display typography only for onboarding or brand-focused empty states, never for normal controls.

## Shape, Spacing, And Motion

- Spacing follows the FocusDesign 8px rhythm with `2`, `4`, and `6` for dense internals and `20-32` for panel padding.
- Standard panels use `20px`; feature/primary groups use `24px`; overlays use `16px`; capsules use `999px`.
- Normal hierarchy uses borders, insets, underlines, and solid fills. Do not use gradients, glows, decorative blur fields, or shadows for regular app surfaces.
- Motion must go through `FCTheme.animation()` or `FCTheme.spring()` so Reduce Motion can fall back to lower-movement transitions.

## Component Rules

- Main window: `canvasBlack` root, `surfaceSlate`/`surfaceInset` panels, timeline rail, editor-dominant layout.
- Page rail: violet structural rail, uppercase mono metadata, mint selected state, amber dirty state, violet save-failed state, visible lock marker.
- Script editor: `surfaceInset`, frame-gray rest border, mint focus border, no nested cards.
- Run controls: mint Start with black uppercase mono text; recording-pink Stop; orange output/import; violet assisted recovery.
- Settings: dense operator rows, slate cards, clear state badges, no decorative previews of secrets.
- Delivery surfaces: `absoluteBlack`, large script text, minimal telemetry, read-yellow/cue-mint progress.

## Banned Patterns

- No light default app surface.
- No soft dashboard glass, decorative blur fields, color orbs, glow shadows, or atmospheric gradients.
- No drop shadows for normal hierarchy.
- No nested cards.
- No lowercase mono labels.
- No emoji in browser remote, waiting states, settings notices, onboarding, or delivery UI.
- No new accent colors unless they map to a real FocusCue state.
