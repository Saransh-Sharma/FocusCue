//
//  MainWindowTheme.swift
//  FocusCue
//

import AppKit
import SwiftUI

enum FCColorToken: CaseIterable {
    case bgCanvas
    case bgCanvasTop
    case bgCanvasBottom
    case surfaceGlass
    case surfaceGlassStrong
    case surfaceOverlay
    case borderSubtle
    case borderFocus
    case textPrimary
    case textSecondary
    case textTertiary
    case accentPrimary
    case accentInfo
    case accentCTA
    case stateSuccess
    case stateWarning
    case stateError

    func color(in scheme: ColorScheme) -> Color {
        switch (self, scheme) {
        case (.bgCanvas, .dark): return .fcHex(0x090B10)
        case (.bgCanvas, _): return .fcHex(0xF5F7FB)
        case (.bgCanvasTop, .dark): return .fcHex(0x131824)
        case (.bgCanvasTop, _): return .fcHex(0xFFFFFF)
        case (.bgCanvasBottom, .dark): return .fcHex(0x090B10)
        case (.bgCanvasBottom, _): return .fcHex(0xEAF0F9)
        case (.surfaceGlass, .dark): return .fcRGBA(21, 27, 39, 0.78)
        case (.surfaceGlass, _): return .fcRGBA(255, 255, 255, 0.74)
        case (.surfaceGlassStrong, .dark): return .fcRGBA(27, 34, 48, 0.90)
        case (.surfaceGlassStrong, _): return .fcRGBA(255, 255, 255, 0.90)
        case (.surfaceOverlay, .dark): return .fcRGBA(14, 18, 26, 0.86)
        case (.surfaceOverlay, _): return .fcRGBA(245, 251, 255, 0.82)
        case (.borderSubtle, .dark): return .fcRGBA(186, 201, 227, 0.22)
        case (.borderSubtle, _): return .fcRGBA(152, 170, 199, 0.34)
        case (.borderFocus, .dark): return .fcRGBA(126, 182, 255, 0.56)
        case (.borderFocus, _): return .fcRGBA(61, 142, 255, 0.62)
        case (.textPrimary, .dark): return .fcHex(0xF2F6FF)
        case (.textPrimary, _): return .fcHex(0x0E1525)
        case (.textSecondary, .dark): return .fcHex(0xB2C1D9)
        case (.textSecondary, _): return .fcHex(0x475774)
        case (.textTertiary, .dark): return .fcHex(0x8A98AF)
        case (.textTertiary, _): return .fcHex(0x6C7B95)
        case (.accentPrimary, .dark): return .fcHex(0x35D0C1)
        case (.accentPrimary, _): return .fcHex(0x1DB6A8)
        case (.accentInfo, .dark): return .fcHex(0x71A9FF)
        case (.accentInfo, _): return .fcHex(0x3C8DFF)
        case (.accentCTA, .dark): return .fcHex(0xFFB36D)
        case (.accentCTA, _): return .fcHex(0xF59A43)
        case (.stateSuccess, .dark): return .fcHex(0x34D399)
        case (.stateSuccess, _): return .fcHex(0x1FA972)
        case (.stateWarning, .dark): return .fcHex(0xF4B45F)
        case (.stateWarning, _): return .fcHex(0xD98A2A)
        case (.stateError, .dark): return .fcHex(0xFF7B87)
        case (.stateError, _): return .fcHex(0xD4545D)
        @unknown default:
            return .accentColor
        }
    }
}

enum FCTypographyToken: CaseIterable {
    case display
    case titleL
    case titleM
    case heading
    case bodyL
    case bodyM
    case label
    case caption
    case mono

    var size: CGFloat {
        switch self {
        case .display: return 34
        case .titleL: return 28
        case .titleM: return 22
        case .heading: return 18
        case .bodyL: return 15
        case .bodyM: return 14
        case .label: return 13
        case .caption: return 12
        case .mono: return 12
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .display: return 40
        case .titleL: return 34
        case .titleM: return 28
        case .heading: return 24
        case .bodyL: return 22
        case .bodyM: return 20
        case .label: return 18
        case .caption: return 16
        case .mono: return 16
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display, .titleL, .titleM, .heading, .label, .mono:
            return .semibold
        case .bodyL, .bodyM:
            return .regular
        case .caption:
            return .medium
        }
    }

    var design: Font.Design {
        self == .mono ? .monospaced : .default
    }

    var font: Font {
        .system(size: size, weight: weight, design: design)
    }
}

enum FCSpacingToken: CGFloat, CaseIterable {
    case s4 = 4
    case s8 = 8
    case s12 = 12
    case s16 = 16
    case s20 = 20
    case s24 = 24
    case s32 = 32
    case s40 = 40
}

enum FCShapeToken: CGFloat, CaseIterable {
    case radius10 = 10
    case radius14 = 14
    case radius18 = 18
    case radius24 = 24
    case capsule = 999
}

enum FCStrokeToken: CGFloat, CaseIterable {
    case thin = 1
    case medium = 1.5
    case bold = 2
}

enum FCEffectToken: CaseIterable {
    case shadowSoft
    case shadowFloat
    case focusGlow

    var yOffset: CGFloat {
        switch self {
        case .shadowSoft: return 6
        case .shadowFloat: return 14
        case .focusGlow: return 0
        }
    }

    var blur: CGFloat {
        switch self {
        case .shadowSoft: return 20
        case .shadowFloat: return 36
        case .focusGlow: return 20
        }
    }

    var opacity: Double {
        switch self {
        case .shadowSoft: return 0.12
        case .shadowFloat: return 0.18
        case .focusGlow: return 0.26
        }
    }
}

enum FCMaterialToken: CaseIterable {
    case card
    case sheet
    case overlay

    var material: Material {
        switch self {
        case .card: return .ultraThinMaterial
        case .sheet: return .regularMaterial
        case .overlay: return .thinMaterial
        }
    }
}

enum FCMotionToken {
    enum Duration: Double, CaseIterable {
        case fast = 0.16
        case base = 0.24
        case slow = 0.32
        case emphasized = 0.42
    }

    enum Curve: CaseIterable {
        case standard
        case enter
        case exit

        func animation(duration: Double) -> Animation {
            switch self {
            case .standard:
                return .easeInOut(duration: duration)
            case .enter:
                return .timingCurve(0.18, 0.90, 0.22, 1.00, duration: duration)
            case .exit:
                return .timingCurve(0.40, 0.00, 1.00, 1.00, duration: duration)
            }
        }
    }

    enum Spring: CaseIterable {
        case snappy
        case soft
        case emphasis

        var response: Double {
            switch self {
            case .snappy: return 0.30
            case .soft: return 0.42
            case .emphasis: return 0.56
            }
        }

        var dampingFraction: Double {
            switch self {
            case .snappy: return 0.86
            case .soft: return 0.88
            case .emphasis: return 0.80
            }
        }
    }
}

struct FCTheme {
    let colorScheme: ColorScheme
    let reduceMotion: Bool

    func color(_ token: FCColorToken) -> Color {
        token.color(in: colorScheme)
    }

    func material(_ token: FCMaterialToken) -> Material {
        token.material
    }

    func animation(_ duration: FCMotionToken.Duration, curve: FCMotionToken.Curve = .standard) -> Animation {
        if reduceMotion {
            return .easeInOut(duration: FCMotionToken.Duration.fast.rawValue)
        }
        return curve.animation(duration: duration.rawValue)
    }

    func spring(_ token: FCMotionToken.Spring) -> Animation {
        if reduceMotion {
            return .easeInOut(duration: FCMotionToken.Duration.fast.rawValue)
        }
        return .spring(response: token.response, dampingFraction: token.dampingFraction)
    }
}

extension View {
    func fcTypography(_ token: FCTypographyToken) -> some View {
        let extraLeading = max(0, token.lineHeight - token.size)
        return self
            .font(token.font)
            .lineSpacing(extraLeading)
    }
}

private extension Color {
    static func fcHex(_ hex: UInt32, alpha: Double = 1.0) -> Color {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b, opacity: alpha)
    }

    static func fcRGBA(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double) -> Color {
        Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, opacity: alpha)
    }
}
