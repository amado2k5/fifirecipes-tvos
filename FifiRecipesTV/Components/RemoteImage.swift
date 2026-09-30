import SwiftUI

/// Remote image with the branded produce placeholder and a soft fade-in —
/// same behaviour as the TV app's Img component. Bytes come through
/// URLSession.shared, which is configured with a generous URLCache and the
/// manifest-versioned URLs produced by AppState.assetURL.
struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var cornerRadius: CGFloat = 0

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.3))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: contentMode)
            case .empty:
                placeholder.overlay { ProgressView().tint(Palette.leafDeep) }
            case .failure:
                placeholder
            @unknown default:
                placeholder
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            Palette.leafSoft
            TomatoMark()
                .frame(width: 64, height: 64)
                .opacity(0.85)
        }
    }
}

/// Little tomato glyph matching the TV app's placeholder SVG.
struct TomatoMark: View {
    var body: some View {
        Canvas { ctx, size in
            let r = size.width * 0.30
            let c = CGPoint(x: size.width / 2, y: size.height * 0.56)
            ctx.fill(
                Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                with: .color(Color(hex: 0xFF5A4E)))
            var leaf = Path()
            leaf.move(to: CGPoint(x: size.width * 0.37, y: size.height * 0.30))
            leaf.addLine(to: CGPoint(x: size.width * 0.45, y: size.height * 0.32))
            leaf.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.22))
            leaf.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.32))
            leaf.addLine(to: CGPoint(x: size.width * 0.63, y: size.height * 0.30))
            leaf.addLine(to: CGPoint(x: size.width * 0.57, y: size.height * 0.38))
            leaf.addQuadCurve(
                to: CGPoint(x: size.width * 0.43, y: size.height * 0.38),
                control: CGPoint(x: size.width * 0.50, y: size.height * 0.42))
            leaf.closeSubpath()
            ctx.fill(leaf, with: .color(Color(hex: 0x4CAF50)))
        }
        .accessibilityHidden(true)
    }
}

/// Warm paper backdrop used under every screen.
struct PaperBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Palette.paper, Palette.paperDeep],
            startPoint: .top, endPoint: .bottom)
        .overlay(alignment: .topTrailing) {
            RadialGradient(
                colors: [Color(hex: 0xFFCD82).opacity(0.5), .clear],
                center: .topTrailing, startRadius: 0, endRadius: 620)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            RadialGradient(
                colors: [Color(hex: 0xC4E6A0).opacity(0.45), .clear],
                center: .bottomLeading, startRadius: 0, endRadius: 620)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
