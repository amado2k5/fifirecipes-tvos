import SwiftUI

/// Loads a kids recipe detail (shared by the ready and steps screens).
@MainActor
final class KidsRecipeLoader: ObservableObject {
    enum State { case loading, loaded, failed }
    @Published private(set) var state = State.loading
    @Published private(set) var recipe: KidsRecipeDetail?
    private let id: String
    private var loadedLang = ""

    init(id: String) { self.id = id }

    func load(lang: String) {
        guard recipe == nil || loadedLang != lang else { return }
        loadedLang = lang
        state = .loading
        Task {
            do {
                recipe = try await APIClient.shared.kidsRecipe(lang: lang, id: id)
                state = .loaded
            } catch {
                state = .failed
            }
        }
    }
}

/// "Get ready" screen: hero card, ready checklist, tickable ingredients,
/// tools, allergen banner, steps preview and the Let's cook button.
struct KidsReadyView: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var loader: KidsRecipeLoader
    @State private var ticked: Set<Int> = []

    // Pushed screens need a declared default focus or the remote's focus
    // stays stranded on the tab bar.
    enum Focus: Hashable { case ingredient(Int), cook }
    @FocusState private var focus: Focus?

    init(id: String) {
        _loader = StateObject(wrappedValue: KidsRecipeLoader(id: id))
    }

    var body: some View {
        ZStack {
            KidsCanvas()
            content
        }
        .kidsFontScope()
        .task { loader.load(lang: app.lang) }
        .onChange(of: app.lang) { loader.load(lang: $1) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("kidsReady")
    }

    @ViewBuilder
    private var content: some View {
        switch loader.state {
        case .loading:
            LoadingView(label: app.s[.loading])
        case .failed:
            ErrorView { loader.reset(); loader.load(lang: app.lang) }
        case .loaded:
            if let recipe = loader.recipe { ready(recipe) }
        }
    }

    @ViewBuilder
    private func ready(_ recipe: KidsRecipeDetail) -> some View {
        let style = KidsGroupStyle.forGroup(recipe.group)
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                RainbowBar()
                heroCard(recipe, style: style)
                readyRow
                ingredientsSection(recipe)
                stepsPreview(recipe)
                KidsButton(title: "🍳 \(app.s[.letsCook])", id: "kidsStartCooking") {
                    app.kidsPath.append(AppRoute.kidsSteps(recipe.id))
                }
                .focused($focus, equals: .cook)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.horizontal, FifiLayout.screenMargin)
            .padding(.vertical, 30)
        }
        .defaultFocus($focus, .ingredient(0))
    }

    private func heroCard(_ recipe: KidsRecipeDetail, style: KidsGroupStyle) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 26) {
                KidsArtView(id: recipe.cover)
                    .frame(width: 150, height: 150)
                    .padding(16)
                    .background(.white.opacity(0.9), in: Circle())
                VStack(alignment: .leading, spacing: 10) {
                    Text(app.s[.getReady])
                        .fifiFont(.title3, weight: .bold)
                        .foregroundStyle(KidsPalette.dim)
                    Text(recipe.title)
                        .fifiFont(.largeTitle, weight: .heavy)
                        .foregroundStyle(KidsPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let intro = recipe.intro {
                        Text(intro)
                            .fifiFont(.callout)
                            .foregroundStyle(KidsPalette.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    kidsMeta("\(app.s[.ages]) \(recipe.ages)")
                    kidsMeta("⏱ \(recipe.minutes) \(app.s[.minutesShort])")
                    if let srv = recipe.servings { kidsMeta("🍽 \(srv) \(app.s[.servings])") }
                    if recipe.noCook {
                        kidsMeta("❄ \(app.s[.noCook])", bg: KidsPalette.frostBg, fg: KidsPalette.frostText)
                    } else {
                        kidsMeta("👨‍👧 \(app.s[.grownUp])", bg: KidsPalette.hotBg, fg: KidsPalette.hotText)
                    }
                }
            }
            .scrollClipDisabled()
            if let allergens = recipe.allergens, !allergens.isEmpty {
                Text("⚠ \(app.s[.contains]): " +
                     allergens.map { Strings.allergenName(lang: app.lang, code: $0) }.joined(separator: ", "))
                    .fifiFont(.title3, weight: .bold)
                    .foregroundStyle(KidsPalette.warnText)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(KidsPalette.warnBg, in: RoundedRectangle(cornerRadius: 18))
                    .accessibilityIdentifier("allergenBanner")
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.card.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(style.border, lineWidth: 4))
    }

    private func kidsMeta(_ text: String, bg: Color = KidsPalette.meta, fg: Color = KidsPalette.ink) -> some View {
        Text(text)
            .fifiFont(.callout, weight: .bold)
            .foregroundStyle(fg)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(bg, in: Capsule())
    }

    private var readyRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                readyPill(art: "wash-hands", label: app.s[.washHands])
                readyPill(art: "apron", label: app.s[.wearApron])
                readyPill(art: "grown-up", label: app.s[.grownUp])
            }
        }
        .scrollClipDisabled()
    }

    private func readyPill(art: String, label: String) -> some View {
        HStack(spacing: 12) {
            KidsArtView(id: art).frame(width: 46, height: 46)
            Text(label)
                .fifiFont(.callout, weight: .bold)
                .foregroundStyle(KidsPalette.ink)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.white.opacity(0.85), in: Capsule())
        .overlay(Capsule().stroke(KidsPalette.cardBorder, lineWidth: 4))
    }

    private func ingredientsSection(_ recipe: KidsRecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(app.s[.ingredients])
                .fifiFont(.title2, weight: .heavy)
                .foregroundStyle(KidsPalette.ink)
            Text(app.s[.tickHint])
                .fifiFont(.callout, weight: .medium)
                .foregroundStyle(KidsPalette.dim)
            VStack(spacing: 14) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { i, ing in
                    let on = ticked.contains(i)
                    KidsIngredientRow(art: ing.art, text: ing.text, on: on) {
                        if on { ticked.remove(i) } else { ticked.insert(i) }
                    }
                    .focused($focus, equals: .ingredient(i))
                    .accessibilityIdentifier("kidsIngredient-\(i)")
                }
            }
            if let tools = recipe.tools, !tools.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(app.s[.tools])
                        .fifiFont(.title3, weight: .bold)
                        .foregroundStyle(KidsPalette.dim)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(tools, id: \.self) { tool in
                                KidsArtView(id: tool).frame(width: 64, height: 64)
                            }
                        }
                    }
                    .scrollClipDisabled()
                }
                .padding(20)
                .background(.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(KidsPalette.cardBorder, lineWidth: 4))
            }
        }
    }

    private func stepsPreview(_ recipe: KidsRecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(app.s[.steps])
                .fifiFont(.title2, weight: .heavy)
                .foregroundStyle(KidsPalette.ink)
            Text(Strings.fill(app.s[.stepOf], ["n": 1, "t": recipe.steps.count]))
                .fifiFont(.callout, weight: .medium)
                .foregroundStyle(KidsPalette.dim)
            VStack(spacing: 14) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, st in
                    HStack(alignment: .top, spacing: 18) {
                        Text("\(i + 1)")
                            .fifiFont(.title3, weight: .heavy)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(KidsPalette.stepOrange, in: Circle())
                        VStack(alignment: .leading, spacing: 10) {
                            Text(st.text)
                                .fifiFont(.body, weight: .medium)
                                .foregroundStyle(KidsPalette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            stepBadges(st)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(KidsPalette.cardBorder, lineWidth: 4))
                }
            }
            if let tip = recipe.tip {
                Text("⭐ \(app.s[.tip]): \(tip)")
                    .fifiFont(.callout, weight: .bold)
                    .foregroundStyle(KidsPalette.tipText)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KidsPalette.tipBg)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    private func stepBadges(_ st: KidsStep) -> some View {
        HStack(spacing: 14) {
            if st.adult != nil {
                HStack(spacing: 8) {
                    KidsArtView(id: "grown-up").frame(width: 30, height: 30)
                    Text(app.s[.grownUp])
                        .fifiFont(.callout, weight: .bold)
                        .foregroundStyle(KidsPalette.warnText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(KidsPalette.warnBg, in: RoundedRectangle(cornerRadius: 12))
            }
            if let items = st.items?.prefix(5) {
                ForEach(Array(items), id: \.self) { item in
                    KidsArtView(id: item).frame(width: 42, height: 42)
                }
            }
        }
    }
}

/// Focus-aware tickable ingredient row for the kids ready screen.
private struct KidsIngredientRow: View {
    let art: String
    let text: String
    let on: Bool
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(on ? KidsPalette.checkGreen : KidsPalette.chipIdle)
                    .frame(width: 48, height: 48)
                KidsArtView(id: art).frame(width: 52, height: 52)
                Text(text)
                    .fifiFont(.body, weight: .medium)
                    .foregroundStyle(KidsPalette.ink)
                    .strikethrough(on)
                    .opacity(on ? 0.6 : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(on ? KidsPalette.checkSoft : .white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(on ? KidsPalette.checkGreen : KidsPalette.cardBorder,
                            lineWidth: isFocused ? 5 : 4))
        }
        .buttonStyle(.plain)
        .scaleEffect(isFocused && !reduceMotion ? 1.02 : 1)
        .animation(.easeOut(duration: reduceMotion ? 0 : 0.15), value: isFocused)
    }
}

extension KidsRecipeLoader {
    func reset() {
        recipe = nil
        loadedLang = ""
    }
}
