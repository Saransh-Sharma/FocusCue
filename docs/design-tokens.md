# FocusCue Design Tokens

## Purpose
This file defines the tokenized visual system used by the premium main window and onboarding wizard. All new UI in these surfaces should consume these tokens instead of ad hoc constants.

Source of truth in code: `/Users/saransh1337/Developer/Projects/FocusCue/FocusCue/MainWindowTheme.swift`.

## Color Tokens
| Token | Light | Dark | Usage |
|---|---|---|---|
| `fc.bg.canvas` | `#F5F7FB` | `#090B10` | Window background base |
| `fc.bg.canvasTop` | `#FFFFFF` | `#131824` | Gradient top |
| `fc.bg.canvasBottom` | `#EAF0F9` | `#090B10` | Gradient bottom |
| `fc.surface.glass` | `rgba(255,255,255,0.74)` | `rgba(21,27,39,0.78)` | Primary cards |
| `fc.surface.glassStrong` | `rgba(255,255,255,0.90)` | `rgba(27,34,48,0.90)` | Active cards |
| `fc.surface.overlay` | `rgba(245,251,255,0.82)` | `rgba(14,18,26,0.86)` | Overlays |
| `fc.border.subtle` | `rgba(152,170,199,0.34)` | `rgba(186,201,227,0.22)` | Subtle borders |
| `fc.border.focus` | `rgba(61,142,255,0.62)` | `rgba(126,182,255,0.56)` | Focus ring |
| `fc.text.primary` | `#0E1525` | `#F2F6FF` | Primary text |
| `fc.text.secondary` | `#475774` | `#B2C1D9` | Secondary text |
| `fc.text.tertiary` | `#6C7B95` | `#8A98AF` | Meta labels |
| `fc.accent.primary` | `#1DB6A8` | `#35D0C1` | Primary CTA |
| `fc.accent.info` | `#3C8DFF` | `#71A9FF` | Informational accents |
| `fc.accent.cta` | `#F59A43` | `#FFB36D` | Featured CTA |
| `fc.state.success` | `#1FA972` | `#34D399` | Success states |
| `fc.state.warning` | `#D98A2A` | `#F4B45F` | Warning states |
| `fc.state.error` | `#D4545D` | `#FF7B87` | Error states |

## Typography Tokens
| Token | Family | Size/Line | Weight | Usage |
|---|---|---|---|---|
| `fc.type.display` | SF Pro Display | 34/40 | Semibold | Main hero |
| `fc.type.titleL` | SF Pro Display | 28/34 | Semibold | Section title |
| `fc.type.titleM` | SF Pro Display | 22/28 | Semibold | Card title |
| `fc.type.heading` | SF Pro Text | 18/24 | Semibold | Subsection heading |
| `fc.type.bodyL` | SF Pro Text | 15/22 | Regular | Long body |
| `fc.type.bodyM` | SF Pro Text | 14/20 | Regular | Standard body |
| `fc.type.label` | SF Pro Text | 13/18 | Semibold | Controls/chips |
| `fc.type.caption` | SF Pro Text | 12/16 | Medium | Metadata |
| `fc.type.mono` | SF Mono | 12/16 | Semibold | Counters |

## Motion Tokens
### Durations
- `fc.motion.duration.fast = 0.16s`
- `fc.motion.duration.base = 0.24s`
- `fc.motion.duration.slow = 0.32s`
- `fc.motion.duration.emphasized = 0.42s`

### Curves
- `fc.motion.curve.standard = easeInOut`
- `fc.motion.curve.enter = cubic(0.18, 0.90, 0.22, 1.00)`
- `fc.motion.curve.exit = cubic(0.40, 0.00, 1.00, 1.00)`

### Springs
- `fc.motion.spring.snappy = response 0.30, damping 0.86`
- `fc.motion.spring.soft = response 0.42, damping 0.88`
- `fc.motion.spring.emphasis = response 0.56, damping 0.80`

## Shape, Spacing, and Effects
### Spacing scale
`4, 8, 12, 16, 20, 24, 32, 40`

### Radius scale
`10, 14, 18, 24, capsule(999)`

### Stroke widths
`1, 1.5, 2`

### Shadow tokens
- `fc.shadow.soft: y=6, blur=20, opacity=0.12`
- `fc.shadow.float: y=14, blur=36, opacity=0.18`
- `fc.shadow.focusGlow: accent glow, opacity=0.26`

### Material tokens
- `fc.material.card = .ultraThinMaterial`
- `fc.material.sheet = .regularMaterial`
- `fc.material.overlay = .thinMaterial`

## Accessibility Constraints
- Body-text contrast target minimum: 4.5:1.
- Interactive controls should not go below 32x32 points.
- When `Reduce Motion` is enabled:
  - avoid movement greater than 12 points,
  - replace move/spring emphasis with opacity-first transitions.
- Focus-visible state should use `fc.border.focus` with subtle glow.

## Implementation Notes
- The token preview utility view is at `/Users/saransh1337/Developer/Projects/FocusCue/FocusCue/DesignTokenPreviewView.swift` and is debug-only.
- Any new main-window or onboarding UI should consume `FCTheme` and token enums.
