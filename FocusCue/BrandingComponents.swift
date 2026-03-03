import SwiftUI

struct FCBrandIconView: View {
    let size: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(size: CGFloat, cornerRadius: CGFloat, shadowRadius: CGFloat = 0) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }

    private var brandImage: NSImage? {
        NSImage(named: "BrandIcon") ?? NSImage(named: "AppIcon")
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        Group {
            if let brandImage {
                Image(nsImage: brandImage)
                    .resizable()
                    .interpolation(.high)
            } else {
                shape
                    .fill(theme.color(.surfaceGlassStrong))
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .shadow(
            color: shadowRadius > 0 ? theme.color(.accentInfo).opacity(0.18) : .clear,
            radius: shadowRadius,
            y: shadowRadius > 0 ? 2 : 0
        )
    }
}
