import SwiftUI

enum FCSettingsNoticeKind {
    case info
    case warning
    case success

    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }

    var tint: FCColorToken {
        switch self {
        case .info: return .focusCyan
        case .warning: return .stateWarning
        case .success: return .stateSuccess
        }
    }
}

struct FCSettingsShell<Sidebar: View, Content: View, Footer: View>: View {
    let sidebarWidth: CGFloat
    @ViewBuilder let sidebar: Sidebar
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        sidebarWidth: CGFloat = 170,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.sidebarWidth = sidebarWidth
        self.sidebar = sidebar()
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let shape = RoundedRectangle(cornerRadius: FCShapeToken.radius18.rawValue, style: .continuous)

        ZStack {
            FCWindowBackdrop()

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    sidebar
                        .frame(width: sidebarWidth)
                        .padding(.vertical, FCSpacingToken.s12.rawValue)
                        .padding(.horizontal, FCSpacingToken.s8.rawValue)
                        .background(theme.color(.surfaceRaised))

                    Rectangle()
                        .fill(theme.color(.frameGray))
                        .frame(width: 1)

                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(FCSpacingToken.s12.rawValue)
                }

                Rectangle()
                    .fill(theme.color(.frameGray))
                    .frame(height: 1)

                footer
                    .padding(.horizontal, FCSpacingToken.s12.rawValue)
                    .padding(.vertical, FCSpacingToken.s8.rawValue)
                    .background(theme.color(.surfaceRaised))
            }
            .background(theme.color(.surfaceSlate), in: shape)
            .clipShape(shape)
            .overlay(
                shape
                    .stroke(theme.color(.frameGray), lineWidth: FCStrokeToken.thin.rawValue)
            )
            .padding(FCSpacingToken.s12.rawValue)
        }
    }
}

struct FCSettingsTabRail<Tab: Identifiable & Hashable, Label: View>: View {
    let title: String
    let tabs: [Tab]
    @Binding var selectedTab: Tab
    let label: (Tab, Bool) -> Label

    init(
        title: String,
        tabs: [Tab],
        selectedTab: Binding<Tab>,
        @ViewBuilder label: @escaping (Tab, Bool) -> Label
    ) {
        self.title = title
        self.tabs = tabs
        self._selectedTab = selectedTab
        self.label = label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FCSpacingToken.s8.rawValue) {
            Text(title.uppercased())
                .foregroundStyle(theme.color(.textTertiary))
                .fcTypography(.caption)
                .padding(.horizontal, FCSpacingToken.s8.rawValue)

            ForEach(tabs, id: \.self) { tab in
                FCSettingsTabItem(isSelected: tab == selectedTab) {
                    selectedTab = tab
                } label: {
                    label(tab, tab == selectedTab)
                }
            }

            Spacer()
        }
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var theme: FCTheme {
        FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
    }
}

struct FCSettingsTabItem<Label: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let label: Label

    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        Button(action: action) {
            label
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, FCSpacingToken.s8.rawValue)
                .padding(.vertical, FCSpacingToken.s8.rawValue)
                .background(
                    RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                        .fill(backgroundColor(theme: theme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                        .stroke(borderColor(theme: theme), lineWidth: isSelected ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue)
                )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous))
        .onHover { hovering in
            withAnimation(theme.animation(.fast)) {
                isHovered = hovering
            }
        }
    }

    private func backgroundColor(theme: FCTheme) -> Color {
        if isSelected {
            return theme.color(.canvasBlack)
        }
        if isHovered {
            return theme.color(.surfaceRaised)
        }
        return theme.color(.surfaceSlate)
    }

    private func borderColor(theme: FCTheme) -> Color {
        if isSelected {
            return theme.color(.cueMint)
        }
        return isHovered ? theme.color(.hoverBlue) : theme.color(.frameGray)
    }
}

struct FCSettingsSectionCard<Content: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let trailing: Trailing
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) where Trailing == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.trailing = EmptyView()
        self.content = content()
    }

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let shape = RoundedRectangle(cornerRadius: FCShapeToken.radius14.rawValue, style: .continuous)

        VStack(alignment: .leading, spacing: FCSpacingToken.s12.rawValue) {
            HStack(alignment: .top, spacing: FCSpacingToken.s8.rawValue) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(theme.color(.textPrimary))
                        .fcTypography(.label)
                    if let subtitle {
                        Text(subtitle)
                            .foregroundStyle(theme.color(.textSecondary))
                            .fcTypography(.caption)
                    }
                }
                Spacer(minLength: 0)
                trailing
            }

            content
        }
        .padding(FCSpacingToken.s12.rawValue)
        .background(theme.color(.surfaceSlate), in: shape)
        .clipShape(shape)
        .overlay(
            shape
                .stroke(theme.color(.frameGray), lineWidth: FCStrokeToken.thin.rawValue)
        )
    }
}

struct FCSettingsOptionCard<Content: View>: View {
    let isSelected: Bool
    let accent: FCColorToken
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        isSelected: Bool,
        accent: FCColorToken = .cueMint,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)
        let shape = RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)

        content
            .padding(.horizontal, FCSpacingToken.s12.rawValue)
            .padding(.vertical, FCSpacingToken.s8.rawValue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                shape
                    .fill(isSelected ? theme.color(.canvasBlack) : theme.color(.surfaceInset))
            )
            .overlay(
                shape
                    .stroke(
                        isSelected ? theme.color(accent) : theme.color(.frameGray),
                        lineWidth: isSelected ? FCStrokeToken.medium.rawValue : FCStrokeToken.thin.rawValue
                    )
            )
    }
}

struct FCSettingsInlineNotice: View {
    let kind: FCSettingsNoticeKind
    let text: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        HStack(alignment: .top, spacing: FCSpacingToken.s8.rawValue) {
            Image(systemName: kind.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.color(kind.tint))
            Text(text)
                .foregroundStyle(theme.color(.textSecondary))
                .fcTypography(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(FCSpacingToken.s12.rawValue)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                .fill(theme.color(.surfaceInset))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FCShapeToken.radius10.rawValue, style: .continuous)
                .stroke(theme.color(kind.tint), lineWidth: FCStrokeToken.thin.rawValue)
        )
    }
}

struct FCSettingsStatusBadge: View {
    let label: String
    let kind: FCSettingsNoticeKind

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = FCTheme(colorScheme: colorScheme, reduceMotion: reduceMotion)

        HStack(spacing: 4) {
            Circle()
                .fill(theme.color(kind.tint))
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundStyle(theme.color(kind.tint))
                .fcTypography(.caption)
        }
        .padding(.horizontal, FCSpacingToken.s8.rawValue)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(theme.color(.canvasBlack))
                .overlay(Capsule(style: .continuous).stroke(theme.color(kind.tint), lineWidth: FCStrokeToken.thin.rawValue))
        )
    }
}
