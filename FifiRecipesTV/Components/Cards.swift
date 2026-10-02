import SwiftUI
import UIKit

/// Shared 10-foot layout constants for the 1920×1080 canvas.
enum FifiLayout {
    /// Standard tvOS safe margin — matches the system's overscan padding.
    static let screenMargin: CGFloat = 90
    /// Rail card width (recipe + kids cards inside horizontal rows).
    static let railCardWidth: CGFloat = 400
}

/// Focus-driven card chrome for every tappable poster/tile on tvOS:
/// scale + lift + leaf border while focused. Honors Reduce Motion.
struct FifiCardButton: ButtonStyle {
    var cornerRadius: CGFloat = 24
    var focusedScale: CGFloat = 1.05
    var borderColor: Color = Palette.leaf

    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isFocused && !reduceMotion ? focusedScale : 1)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused ? 5 : 0)
                    .padding(isFocused ? -4 : 0))
            .shadow(
                color: Palette.ink.opacity(isFocused ? 0.28 : 0),
                radius: isFocused ? 24 : 0, y: isFocused ? 12 : 0)
            .animation(.easeOut(duration: reduceMotion ? 0 : 0.18), value: isFocused)
    }
}

/// Focus-aware capsule/pill button (retry, "let's cook", prev/next).
struct FifiCapsuleButton: ButtonStyle {
    var fill: Color = Palette.leaf
    var text: Color = .white
    var border: Color = .clear
    var borderWidth: CGFloat = 0

    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isFocused ? text : text)
            .background(fill, in: Capsule())
            .overlay(Capsule().stroke(border, lineWidth: borderWidth))
            .scaleEffect(isFocused && !reduceMotion ? 1.06 : 1)
            .shadow(color: KidsPalette.ink.opacity(isFocused ? 0.3 : 0.12), radius: 0, y: isFocused ? 8 : 5)
            .brightness(isFocused ? 0.04 : 0)
            .animation(.easeOut(duration: reduceMotion ? 0 : 0.15), value: isFocused)
    }
}

/// Chip styling, matching the TV app's MetaPill tones.
enum ChipTone {
    case leaf, tomato, sun

    var bg: Color {
        switch self {
        case .leaf: return Palette.leafSoft
        case .tomato: return Palette.tomatoSoft
        case .sun: return Palette.sunSoft
        }
    }

    var fg: Color {
        switch self {
        case .leaf: return Palette.leafDeep
        case .tomato: return Palette.tomato
        case .sun: return Palette.ink
        }
    }
}

struct MetaChip: View {
    var label: String?
    let text: String
    var tone: ChipTone = .leaf

    var body: some View {
        HStack(spacing: 8) {
            if let label {
                Text(label)
                    .opacity(0.7)
            }
            Text(text)
        }
        .fifiFont(.callout, weight: .medium)
        .foregroundStyle(tone.fg)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(tone.bg, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// Frosted off-white panel behind text that sits on or next to a photo:
/// blurred material for depth, a warm paper tint so dark ink keeps its
/// contrast whatever the image underneath looks like.
struct TitlePanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(36)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Palette.card.opacity(0.86)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Palette.cardBorder, lineWidth: 2))
                    .shadow(color: Palette.ink.opacity(0.12), radius: 28, y: 9)
            }
    }
}

extension View {
    func titlePanel() -> some View { modifier(TitlePanel()) }
}

/// Recipe card used in rails, grids and search results.
struct RecipeCardView: View {
    let card: RecipeCard
    @EnvironmentObject private var app: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay { RemoteImage(url: imageURL) }
                .clipped()
                .overlay(alignment: .topTrailing) {
                    if card.hasVideo == true {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Palette.tomato, in: Circle())
                            .shadow(radius: 6)
                            .padding(14)
                    }
                }
                .clipped()
            VStack(alignment: .leading, spacing: 6) {
                Text(card.title)
                    .fifiFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(card.cookingMethod ?? card.category ?? " ")
                    .fifiFont(.callout)
                    .foregroundStyle(Palette.inkDim)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        }
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Palette.cardBorder, lineWidth: 2))
        .shadow(color: Palette.ink.opacity(0.08), radius: 10, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(card.title)
        .accessibilityHint(card.cookingMethod ?? card.category ?? "")
        .accessibilityAddTraits(.isButton)
    }

    private var imageURL: URL? {
        // card2x beats the 800px card thumbnail when present — on a 1080p+
        // screen every card is effectively Retina.
        let info = app.images[card.id]
        return app.assetURL(info?.card2x ?? info?.card ?? card.image)
    }
}

/// Chapter card for the Chapters grid.
struct ChapterCardView: View {
    let chapter: Chapter
    @EnvironmentObject private var app: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay { RemoteImage(url: app.assetURL(chapter.coverImage)) }
                .clipped()
            HStack {
                Text(chapter.name)
                    .fifiFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
                Text("\(chapter.recipeCount)")
                    .fifiFont(.callout, weight: .medium)
                    .foregroundStyle(Palette.leafDeep)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Palette.leafSoft, in: Capsule())
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
        }
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Palette.cardBorder, lineWidth: 2))
        .shadow(color: Palette.ink.opacity(0.08), radius: 10, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chapter.name), \(chapter.recipeCount)")
        .accessibilityAddTraits(.isButton)
    }
}

/// Kids-mode card: group-colored card + kids-art cover + meta line.
struct KidsCardView: View {
    let card: KidsCard
    let minutesLabel: String

    var body: some View {
        let style = KidsGroupStyle.forGroup(card.group)
        VStack(spacing: 14) {
            KidsArtView(id: card.cover)
                .frame(width: 140, height: 140)
                .padding(16)
                .background(.white.opacity(0.9), in: Circle())
            Text(card.title)
                .fifiFont(.title3, weight: .bold)
                .foregroundStyle(KidsPalette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 80)
            Text(metaLine)
                .fifiFont(.callout, weight: .medium)
                .foregroundStyle(KidsPalette.dim)
                .padding(.bottom, 16)
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
        .background(style.card)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(style.border, lineWidth: 4))
        .shadow(color: KidsPalette.ink.opacity(0.18), radius: 0, y: 7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.title), \(metaLine)")
        .accessibilityAddTraits(.isButton)
    }

    private var metaLine: String {
        var s = "\(card.ages) · \(card.minutes) \(minutesLabel)"
        if card.noCook { s += " · ❄" }
        return s
    }
}

/// YouTube video row card — opens the YouTube Apple TV app on select.
struct VideoCardView: View {
    let video: VideoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay { RemoteImage(url: URL(string: "https://i.ytimg.com/vi/\(video.id)/hqdefault.jpg")) }
                .clipped()
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Palette.tomato.opacity(0.92), in: Circle())
                        .shadow(radius: 10)
                }
                .overlay(alignment: .bottomTrailing) {
                    if let d = video.duration {
                        Text(d)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
                            .padding(12)
                    }
                }
                .clipped()
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .fifiFont(.callout, weight: .medium)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                if let ch = video.channel {
                    Text(ch)
                        .fifiFont(.footnote)
                        .foregroundStyle(Palette.inkDim)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        }
        .frame(width: 380)
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Palette.cardBorder, lineWidth: 2))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(video.title)
        .accessibilityAddTraits(.isButton)
    }
}
