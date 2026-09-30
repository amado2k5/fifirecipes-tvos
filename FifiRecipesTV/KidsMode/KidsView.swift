import SwiftUI

/// Kids home: polka-dot canvas, rainbow strip, group filter chips and the
/// kids card grid. Scoped to the kids font faces via .kidsFontScope().
struct KidsView: View {
    @EnvironmentObject private var app: AppState
    @State private var group = "all"
    @State private var noCookOnly = false

    private static let groups = ["breakfast", "snack", "savoury", "sweet", "drink"]

    private var cards: [KidsCard] {
        app.kids.values
            .filter { (group == "all" || $0.group == group) && (!noCookOnly || $0.noCook) }
            .sorted { $0.id < $1.id }
    }

    var body: some View {
        ZStack {
            KidsCanvas()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    RainbowBar()
                    header
                    filterChips
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 320), spacing: 30)],
                        spacing: 30
                    ) {
                        ForEach(cards) { card in
                            Button {
                                app.kidsPath.append(AppRoute.kidsReady(card.id))
                            } label: {
                                KidsCardView(card: card, minutesLabel: app.s[.minutesShort])
                            }
                            .buttonStyle(FifiCardButton(cornerRadius: 30))
                            .accessibilityIdentifier("kidsCard-\(card.id)")
                        }
                    }
                }
                .padding(.horizontal, FifiLayout.screenMargin)
                .padding(.vertical, 30)
            }
        }
        .kidsFontScope()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("kidsScreen")
    }

    private var header: some View {
        HStack(spacing: 22) {
            KidsArtView(id: "chef")
                .frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.s[.kids])
                    .fifiFont(.largeTitle, weight: .heavy)
                    .foregroundStyle(KidsPalette.ink)
                Text(app.s[.tagline])
                    .fifiFont(.title3, weight: .medium)
                    .foregroundStyle(KidsPalette.dim)
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                kidsChip(id: "all", label: app.s[.all], emoji: "🌈",
                         active: group == "all" && !noCookOnly,
                         color: KidsPalette.purple) {
                    group = "all"; noCookOnly = false
                }
                ForEach(Self.groups, id: \.self) { g in
                    let st = KidsGroupStyle.forGroup(g)
                    kidsChip(id: g, label: groupLabel(g), emoji: st.emoji,
                             active: group == g && !noCookOnly,
                             color: st.chip) {
                        group = g; noCookOnly = false
                    }
                }
                kidsChip(id: "nocook", label: app.s[.noCook], emoji: "❄️",
                         active: noCookOnly,
                         color: Color(hex: 0x4FC3F7)) {
                    noCookOnly.toggle()
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
        }
        .scrollClipDisabled()
    }

    private func groupLabel(_ group: String) -> String {
        switch group {
        case "breakfast": return app.s[.groupBreakfast]
        case "snack": return app.s[.groupSnack]
        case "savoury": return app.s[.groupSavoury]
        case "sweet": return app.s[.groupSweet]
        case "drink": return app.s[.groupDrink]
        default: return group
        }
    }

    private func kidsChip(
        id: String, label: String, emoji: String, active: Bool,
        color: Color, action: @escaping () -> Void
    ) -> some View {
        KidsChipButton(label: "\(emoji) \(label)", active: active,
                       color: color, id: "kidsFilter-\(id)", action: action)
    }
}

/// Focus-aware filter chip for the kids catalogue.
private struct KidsChipButton: View {
    let label: String
    let active: Bool
    let color: Color
    let id: String
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(label)
                .fifiFont(.title3, weight: .bold)
                .foregroundStyle(active ? .white : KidsPalette.chipText)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(active ? color : .white.opacity(0.8), in: Capsule())
                .overlay(Capsule().stroke(active ? color : KidsPalette.chipIdle, lineWidth: 4))
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused && !reduceMotion ? 1.08 : 1)
        .brightness(isFocused ? 0.05 : 0)
        .animation(.easeOut(duration: reduceMotion ? 0 : 0.15), value: isFocused)
        .accessibilityIdentifier(id)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}
