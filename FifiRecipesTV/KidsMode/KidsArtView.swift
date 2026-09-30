import SwiftUI

/// One kids-mode drawing. The PNGs in Assets.xcassets are pre-rendered from
/// the TV app's hand-drawn SVG library (scripts/render pipeline); unknown ids
/// fall back to "star", matching the TV KidsArt component.
struct KidsArtView: View {
    let id: String

    var body: some View {
        Image(resolvedID)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }

    private var resolvedID: String {
        UIImage(named: id) != nil ? id : "star"
    }
}

/// Warm polka-dot canvas like the website's Cooking with Kids section.
struct KidsCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(KidsPalette.canvas))
            let step: CGFloat = 72
            let r: CGFloat = 4
            var y: CGFloat = 0
            while y < size.height + step {
                var x: CGFloat = 0
                while x < size.width + step {
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(KidsPalette.dot))
                    x += step
                }
                y += step
            }
        }
        .ignoresSafeArea()
    }
}

/// Rainbow strip header used at the top of kids screens.
struct RainbowBar: View {
    var body: some View {
        KidsPalette.rainbow
            .frame(height: 14)
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }
}

/// Chunky rounded kids button (the "Let's cook" / nav buttons) — capsule
/// that lifts and brightens under remote focus.
struct KidsButton: View {
    let title: String
    var gradient: LinearGradient = KidsPalette.goGradient
    var border: Color = KidsPalette.checkBorder
    var foreground: Color = .white
    var id: String? = nil
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(title)
                .fifiFont(.title2, weight: .heavy)
                .foregroundStyle(foreground)
                .padding(.horizontal, 48)
                .padding(.vertical, 22)
                .background(gradient, in: Capsule())
                .overlay(Capsule().stroke(border, lineWidth: 4))
                .shadow(color: KidsPalette.ink.opacity(0.22), radius: 0, y: 8)
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused && !reduceMotion ? 1.07 : 1)
        .brightness(isFocused ? 0.05 : 0)
        .animation(.easeOut(duration: reduceMotion ? 0 : 0.15), value: isFocused)
        .accessibilityIdentifier(id ?? "")
    }
}
