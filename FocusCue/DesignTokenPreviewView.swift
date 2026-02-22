//
//  DesignTokenPreviewView.swift
//  FocusCue
//

import SwiftUI

#if DEBUG
struct DesignTokenPreviewView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        ScrollView {
            VStack(alignment: .leading, spacing: FCSpacingToken.s20.rawValue) {
                Text("FocusCue Design Tokens")
                    .foregroundStyle(theme.color(.textPrimary))
                    .fcTypography(.titleM)

                VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                    Text("Colors")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.label)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                        ForEach(FCColorToken.allCases, id: \.self) { token in
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                                    .fill(theme.color(token))
                                    .frame(height: 48)
                                Text(String(describing: token))
                                    .foregroundStyle(theme.color(.textTertiary))
                                    .lineLimit(1)
                                    .fcTypography(.caption)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
                    Text("Typography")
                        .foregroundStyle(theme.color(.textSecondary))
                        .fcTypography(.label)

                    ForEach(FCTypographyToken.allCases, id: \.self) { token in
                        Text(String(describing: token))
                            .foregroundStyle(theme.color(.textPrimary))
                            .fcTypography(token)
                    }
                }
            }
            .padding(FCSpacingToken.s24.rawValue)
        }
        .background(theme.color(.bgCanvas))
    }
}

#Preview {
    DesignTokenPreviewView()
}
#endif
