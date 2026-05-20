//
//  MainWindowTheme.swift
//  FocusCue
//

import AppKit
import SwiftUI

enum FCColorToken: CaseIterable {
    case canvasBlack
    case surfaceSlate
    case surfaceRaised
    case surfaceInset
    case frameGray
    case hazardWhite
    case absoluteBlack
    case textMuted
    case textInverted
    case cueMint
    case cueMintBorder
    case resyncViolet
    case violetRule
    case hoverBlue
    case focusCyan
    case readYellow
    case recordingPink
    case teleprompterOrange
    case disabledGray
    case bgCanvas
    case bgCanvasTop
    case bgCanvasBottom
    case borderFocus
    case textPrimary
    case textSecondary
    case textTertiary
    case accentPrimary
    case stateSuccess
    case stateWarning
    case stateError

    func color(in scheme: ColorScheme) -> Color {
        switch self {
        case .canvasBlack, .bgCanvas, .bgCanvasTop, .bgCanvasBottom:
            return .fcHex(0x131313)
        case .surfaceSlate:
            return .fcHex(0x2D2D2D)
        case .surfaceRaised:
            return .fcHex(0x1B1B1B)
        case .surfaceInset:
            return .fcHex(0x0F0F0F)
        case .frameGray:
            return .fcHex(0x313131)
        case .hazardWhite, .textPrimary:
            return .fcHex(0xFFFFFF)
        case .absoluteBlack:
            return .fcHex(0x000000)
        case .textSecondary:
            return .fcHex(0x949494)
        case .textMuted:
            return .fcHex(0xE9E9E9)
        case .textTertiary:
            return .fcHex(0x949494).opacity(0.72)
        case .textInverted:
            return .fcHex(0x131313)
        case .cueMint, .accentPrimary:
            return .fcHex(0x3CFFD0)
        case .cueMintBorder:
            return .fcHex(0x309875)
        case .resyncViolet, .stateError:
            return .fcHex(0x5200FF)
        case .violetRule:
            return .fcHex(0x3D00BF)
        case .hoverBlue:
            return .fcHex(0x3860BE)
        case .focusCyan, .borderFocus:
            return .fcHex(0x1EAEDB)
        case .readYellow:
            return .fcHex(0xFFD60A)
        case .recordingPink:
            return .fcHex(0xFF6191)
        case .teleprompterOrange:
            return .fcHex(0xFF9E0A)
        case .stateSuccess:
            return .fcHex(0x22C55E)
        case .stateWarning:
            return .fcHex(0xFACC15)
        case .disabledGray:
            return .fcHex(0x5A5A5A)
        }
    }
}

enum FCTypographyToken: CaseIterable {
    case displayHero
    case displayCompact
    case titleLg
    case titleMd
    case titleSm
    case body
    case bodyCompact
    case scriptLg
    case scriptXl
    case scriptDisplay
    case labelCaps
    case monoTimestamp
    case monoButton
    case counter
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
        case .displayHero, .scriptDisplay: return 72
        case .displayCompact, .display: return 60
        case .titleLg, .titleL: return 34
        case .titleMd, .titleM: return 24
        case .titleSm, .heading: return 20
        case .body, .bodyL: return 16
        case .bodyCompact, .bodyM, .label: return 13
        case .scriptLg: return 24
        case .scriptXl: return 48
        case .labelCaps, .mono, .monoButton, .caption: return 12
        case .monoTimestamp: return 11
        case .counter: return 10
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .displayHero: return 65
        case .displayCompact, .display: return 57
        case .titleLg, .titleL: return 34
        case .titleMd, .titleM: return 25
        case .titleSm, .heading: return 22
        case .body, .bodyL: return 26
        case .bodyCompact, .bodyM, .label: return 19
        case .scriptLg: return 32
        case .scriptXl: return 65
        case .scriptDisplay: return 97
        case .labelCaps, .monoButton: return 14
        case .monoTimestamp: return 13
        case .counter: return 14
        case .caption, .mono: return 16
        }
    }

    var weight: Font.Weight {
        switch self {
        case .displayHero, .displayCompact, .display:
            return .black
        case .titleLg, .titleMd, .titleSm, .titleL, .titleM, .heading:
            return .bold
        case .scriptLg, .scriptXl, .scriptDisplay, .labelCaps, .monoButton, .monoTimestamp, .counter, .mono:
            return .semibold
        case .body, .bodyL, .bodyCompact, .bodyM:
            return .medium
        case .caption, .label:
            return .medium
        }
    }

    var design: Font.Design {
        switch self {
        case .labelCaps, .monoTimestamp, .monoButton, .counter, .mono:
            return .monospaced
        case .displayHero, .displayCompact, .display:
            return .default
        default:
            return .default
        }
    }

    var width: Font.Width? {
        switch self {
        case .displayHero, .displayCompact, .display:
            return .condensed
        default:
            return nil
        }
    }

    var font: Font {
        .system(size: size, weight: weight, design: design)
    }

    var tracking: CGFloat {
        switch self {
        case .labelCaps, .monoButton:
            return 1.6
        case .monoTimestamp:
            return 1.3
        case .counter:
            return 1.5
        default:
            return 0
        }
    }
}

enum FCSpacingToken: CGFloat, CaseIterable {
    case s2 = 2
    case s6 = 6
    case s4 = 4
    case s8 = 8
    case s12 = 12
    case s16 = 16
    case s20 = 20
    case s24 = 24
    case s32 = 32
    case s40 = 40
    case s48 = 48
    case s64 = 64
}

enum FCShapeToken: CGFloat, CaseIterable {
    case radius2 = 2
    case radius4 = 4
    case radius10 = 10
    case radius16 = 16
    case radius20 = 20
    case radius14 = 14
    case radius18 = 18
    case radius24 = 24
    case radius30 = 30
    case radius40 = 40
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
        case .card, .sheet, .overlay:
            return .thinMaterial
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
            .fontWidth(token.width)
            .tracking(token.tracking)
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
