import SwiftUI

enum Theme {
    static let background = Color.black
    static let card = Color(white: 0.085)
    static let elevated = Color(white: 0.15)
    static let stroke = Color.white.opacity(0.09)
    static let secondaryText = Color(white: 0.62)
    static let tertiaryText = Color(white: 0.42)
    static let cornerRadius: CGFloat = 18

    static func number(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded).monospacedDigit()
    }
}

struct CardModifier: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }

    /// 黒背景＋ダークなナビゲーションバー/タブバーにそろえる
    func winterScreen() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.white.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule())
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Theme.elevated.opacity(configuration.isPressed ? 0.6 : 1), in: Capsule())
            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
    }
}

/// 「18 /28」のような、数字＋小さい単位の表示
struct StatValue: View {
    let value: String
    var suffix: String = ""
    var size: CGFloat = 30

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value)
                .font(Theme.number(size))
            if !suffix.isEmpty {
                Text(suffix)
                    .font(Theme.number(size * 0.5))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

struct ProgressBar: View {
    let value: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.14))
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.35), value: value)
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}
