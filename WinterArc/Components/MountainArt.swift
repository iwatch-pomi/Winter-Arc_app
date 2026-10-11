import SwiftUI

/// 正規化座標 (0...1) の点をつないだ多角形
struct PolygonShape: Shape {
    let points: [CGPoint]
    /// true なら最後に下端まで閉じる（山の稜線用）
    var closeToBottom = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        func map(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height)
        }
        if closeToBottom {
            path.move(to: CGPoint(x: rect.minX + first.x * rect.width, y: rect.maxY))
            path.addLine(to: map(first))
        } else {
            path.move(to: map(first))
        }
        for point in points.dropFirst() {
            path.addLine(to: map(point))
        }
        if closeToBottom, let last = points.last {
            path.addLine(to: CGPoint(x: rect.minX + last.x * rect.width, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

private func pts(_ values: [(CGFloat, CGFloat)]) -> [CGPoint] {
    values.map { CGPoint(x: $0.0, y: $0.1) }
}

/// モノクロの雪山イラスト（写真の代わり）
struct MountainArtView: View {
    var showClimber = true
    var showStars = true

    private static let farRange = pts([(0, 0.62), (0.1, 0.5), (0.2, 0.56), (0.3, 0.44), (0.4, 0.52), (0.5, 0.47),
                                       (0.78, 0.5), (0.88, 0.42), (1, 0.5)])
    private static let mainRange = pts([(0, 0.78), (0.12, 0.64), (0.22, 0.68), (0.36, 0.5), (0.45, 0.45),
                                        (0.53, 0.3), (0.62, 0.17), (0.69, 0.27), (0.75, 0.31), (0.84, 0.46),
                                        (0.92, 0.5), (1, 0.6)])
    private static let shadowFace = pts([(0.62, 0.17), (0.69, 0.27), (0.75, 0.31), (0.84, 0.46), (0.92, 0.5),
                                         (1, 0.6), (1, 1), (0.74, 1), (0.66, 0.5), (0.64, 0.3)])
    private static let snowCap = pts([(0.53, 0.3), (0.62, 0.17), (0.69, 0.27), (0.665, 0.3), (0.64, 0.27),
                                      (0.615, 0.33), (0.59, 0.29), (0.56, 0.34)])
    private static let foreground = pts([(0, 0.88), (0.2, 0.86), (0.42, 0.82), (0.56, 0.77), (0.6, 0.765),
                                         (0.66, 0.775), (0.8, 0.83), (1, 0.86)])
    private static let stars: [CGPoint] = pts([(0.08, 0.08), (0.21, 0.18), (0.33, 0.06), (0.44, 0.14), (0.78, 0.07),
                                               (0.87, 0.19), (0.94, 0.1), (0.15, 0.3), (0.71, 0.12)])

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.3), Color(white: 0.13), Color(white: 0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                if showStars {
                    ForEach(Array(Self.stars.enumerated()), id: \.offset) { item in
                        Circle()
                            .fill(Color.white.opacity(0.55))
                            .frame(width: 2, height: 2)
                            .position(x: item.element.x * size.width, y: item.element.y * size.height)
                    }
                }
                PolygonShape(points: Self.farRange, closeToBottom: true)
                    .fill(LinearGradient(colors: [Color(white: 0.36), Color(white: 0.12)], startPoint: .top, endPoint: .bottom))
                PolygonShape(points: Self.mainRange, closeToBottom: true)
                    .fill(LinearGradient(
                        colors: [Color(white: 0.78), Color(white: 0.42), Color(white: 0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                PolygonShape(points: Self.shadowFace)
                    .fill(Color.black.opacity(0.38))
                PolygonShape(points: Self.snowCap)
                    .fill(Color.white.opacity(0.95))
                PolygonShape(points: Self.foreground, closeToBottom: true)
                    .fill(Color(white: 0.02))
                if showClimber {
                    ClimberShape()
                        .fill(Color(white: 0.02))
                        .frame(width: size.height * 0.05, height: size.height * 0.11)
                        .position(x: size.width * 0.6, y: size.height * (0.765 - 0.055))
                }
            }
        }
        .clipped()
    }
}

/// 山頂に立つ人のシルエット
struct ClimberShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        // 頭
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.3, y: rect.minY, width: w * 0.4, height: h * 0.18))
        // 胴体＋リュック
        path.addRoundedRect(
            in: CGRect(x: rect.minX + w * 0.15, y: rect.minY + h * 0.19, width: w * 0.7, height: h * 0.42),
            cornerSize: CGSize(width: w * 0.2, height: w * 0.2)
        )
        // 脚
        path.addRect(CGRect(x: rect.minX + w * 0.2, y: rect.minY + h * 0.58, width: w * 0.24, height: h * 0.42))
        path.addRect(CGRect(x: rect.minX + w * 0.56, y: rect.minY + h * 0.58, width: w * 0.24, height: h * 0.42))
        return path
    }
}

/// ロゴの二連山マーク
struct LogoMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h * 0.35))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.45, y: rect.minY + h * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.65, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct LogoView: View {
    var size: CGFloat = 20

    var body: some View {
        HStack(spacing: 8) {
            LogoMark()
                .stroke(Color.white, style: StrokeStyle(lineWidth: max(1.2, size * 0.08), lineJoin: .round))
                .frame(width: size * 1.5, height: size * 0.8)
            Text("Winter Arc")
                .font(.system(size: size, weight: .regular, design: .serif))
        }
    }
}

#Preview {
    MountainArtView()
        .frame(height: 320)
        .preferredColorScheme(.dark)
}
