import SwiftUI

/// Full recipe page for the 10-foot UI — hero banner, meta chips, nutrition,
/// tickable ingredient checklist, numbered steps, grouped alternative
/// methods, tips, the "From Fatma's notebook" card and the videos rail.
/// Content is centred in a readable ~1240pt column under the hero.
struct RecipeDetailView: View {
    @EnvironmentObject private var app: AppState
    let id: String

    @State private var file: RecipeFile?
    @State private var videos: [VideoItem] = []
    @State private var failed = false
    @State private var ticked: Set<Int> = []
    @State private var youtubeMissing = false
    // Pushed screens need a declared default focus or the focus engine
    // leaves the remote's focus on the tab bar, stranding navigation.
    @FocusState private var focusedIngredient: Int?

    var body: some View {
        Group {
            if failed {
                ErrorView { load() }
            } else if let loc {
                content(loc)
            } else {
                LoadingView(label: app.s[.loading])
            }
        }
        .navigationTitle(file.map { RecipeLocalization.localize($0, lang: app.lang).title } ?? "")
        .task(id: "\(id)|\(app.lang)") { load() }
        .alert(app.s[.openInYouTube], isPresented: $youtubeMissing) {
            Button(app.s[.close], role: .cancel) {}
        } message: {
            Text(app.s[.youtubeAppNeeded])
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("recipeDetail")
    }

    private var loc: RecipeLocalization.Localized? {
        file.map { RecipeLocalization.localize($0, lang: app.lang) }
    }

    private func load() {
        failed = false
        file = nil
        let api = APIClient.shared
        Task {
            do { file = try await api.recipe(id: id) }
            catch { failed = true }
        }
        Task {
            videos = (try? await api.videos(id: id))
                .map { APIClient.pickVideos($0, lang: app.lang) } ?? []
        }
    }

    @ViewBuilder
    private func content(_ loc: RecipeLocalization.Localized) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                header(loc)
                VStack(alignment: .leading, spacing: 36) {
                    if let notes = loc.culturalNotes {
                        culturalCard(notes)
                    }
                    ingredientsSection(loc)
                    stepsSection(loc)
                    alternativeSection(loc)
                    tipsSection(loc)
                    videosSection
                }
                .frame(maxWidth: 1240, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 60)
            .padding(.top, 10)
        }
        .defaultFocus($focusedIngredient, 0)
    }

    // MARK: - Hero + meta

    @ViewBuilder
    private func header(_ loc: RecipeLocalization.Localized) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            RemoteImage(url: heroURL, cornerRadius: 30)
                .frame(maxWidth: .infinity)
                .frame(height: 480)
                .shadow(color: Palette.ink.opacity(0.10), radius: 18, y: 9)
                .padding(.horizontal, FifiLayout.screenMargin)

            VStack(alignment: .leading, spacing: 16) {
                if let chapter = loc.chapter {
                    Text(chapter)
                        .fifiFont(.title3, weight: .bold)
                        .foregroundStyle(Palette.leafDeep)
                }
                Text(loc.title)
                    .fifiFont(.largeTitle, weight: .heavy)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let sub = loc.subtitle {
                    Text(sub)
                        .fifiFont(.title2)
                        .italic()
                        .foregroundStyle(Palette.inkDim)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        if let v = loc.prepTime { MetaChip(label: app.s[.prep], text: v, tone: .leaf) }
                        if let v = loc.cookTime { MetaChip(label: app.s[.cook], text: v, tone: .tomato) }
                        if let v = loc.servings { MetaChip(label: app.s[.servings], text: v, tone: .sun) }
                        if let v = loc.category { MetaChip(text: v, tone: .leaf) }
                        if let v = loc.cookingMethod { MetaChip(text: v, tone: .tomato) }
                    }
                }
                .scrollClipDisabled()
                if let est = file?.estimate, est.kcal != nil || est.protein != nil || est.carbs != nil || est.fat != nil {
                    HStack(spacing: 20) {
                        if let v = est.kcal { Text("\(v) \(app.s[.kcal])") }
                        if let v = est.protein { Text("· \(v)g \(app.s[.protein])") }
                        if let v = est.carbs { Text("· \(v)g \(app.s[.carbs])") }
                        if let v = est.fat { Text("· \(v)g \(app.s[.fat])") }
                    }
                    .fifiFont(.callout)
                    .foregroundStyle(Palette.inkDim)
                }
            }
            .padding(.horizontal, FifiLayout.screenMargin)
        }
    }

    private var heroURL: URL? {
        let info = app.images[id]
        return app.assetURL(info?.full2x ?? info?.full ?? app.index[id]?.image)
    }

    private func culturalCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(app.s[.culturalNotes])
                .fifiFont(.title3, weight: .bold)
                .foregroundStyle(Palette.leafDeep)
            Text(notes)
                .fifiFont(.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.sunSoft)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .leading) {
            Palette.sun
                .frame(width: 8)
                .clipShape(UnevenRoundedRectangle(
                    cornerRadii: .init(topLeading: 24, bottomLeading: 24)))
        }
        .padding(.horizontal, FifiLayout.screenMargin)
    }

    // MARK: - Sections

    private func sectionTitle(_ text: String, dot: Color) -> some View {
        HStack(spacing: 16) {
            Circle().fill(dot).frame(width: 22, height: 22)
            Text(text)
                .fifiFont(.title2, weight: .bold)
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, FifiLayout.screenMargin)
    }

    private func ingredientsSection(_ loc: RecipeLocalization.Localized) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle(app.s[.ingredients], dot: Palette.leaf)
            Text(app.s[.tickHint])
                .fifiFont(.callout, weight: .medium)
                .foregroundStyle(Palette.inkDim)
                .padding(.horizontal, FifiLayout.screenMargin)
            VStack(spacing: 0) {
                ForEach(Array(loc.ingredients.enumerated()), id: \.offset) { i, ing in
                    let isOn = ticked.contains(i)
                    Button {
                        if isOn { ticked.remove(i) } else { ticked.insert(i) }
                    } label: {
                        HStack(spacing: 20) {
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(isOn ? Palette.leaf : Palette.cardBorder)
                                .frame(width: 44, height: 44)
                            // Amount sits under the name, not beside it: amounts can be whole
                            // phrases ("500g fresh leaves, finely chopped with Makhrata") that
                            // would otherwise squeeze the name into a one-word-wide column.
                            VStack(alignment: .leading, spacing: 6) {
                                Text(ing.name)
                                    .fifiFont(.body, weight: .medium)
                                    .foregroundStyle(Palette.ink)
                                    .strikethrough(isOn)
                                    .opacity(isOn ? 0.6 : 1)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let amount = ing.amount {
                                    Text(amount)
                                        .fifiFont(.body, weight: .bold)
                                        .foregroundStyle(Palette.leafDeep)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(FifiRowButton())
                    .focused($focusedIngredient, equals: i)
                    .accessibilityIdentifier("ingredient-\(i)")
                    if i < loc.ingredients.count - 1 {
                        Palette.cardBorder.frame(height: 2).padding(.leading, 28)
                    }
                }
            }
            .background(Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Palette.cardBorder, lineWidth: 2))
            .padding(.horizontal, FifiLayout.screenMargin)
        }
    }

    private var coreSteps: [RecipeLocalization.Step] {
        (loc?.steps ?? []).filter { $0.alternative == nil }
    }

    private var alternativeGroups: [(label: String, steps: [RecipeLocalization.Step])] {
        var order: [String] = []
        var map: [String: [RecipeLocalization.Step]] = [:]
        for st in loc?.steps ?? [] {
            guard let alt = st.alternative else { continue }
            if map[alt] == nil { order.append(alt); map[alt] = [] }
            map[alt]?.append(st)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    private var tips: [RecipeLocalization.Step] {
        (loc?.steps ?? []).filter(\.isTip)
    }

    private func stepCard(_ st: RecipeLocalization.Step) -> some View {
        HStack(alignment: .top, spacing: 24) {
            Text("\(st.n)")
                .fifiFont(.title3, weight: .heavy)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Palette.leaf, in: Circle())
            Text(st.text)
                .fifiFont(.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(26)
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Palette.cardBorder, lineWidth: 2))
    }

    private func stepsSection(_ loc: RecipeLocalization.Localized) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle(app.s[.steps], dot: Palette.tomato)
            VStack(spacing: 16) {
                ForEach(coreSteps, id: \.n) { st in stepCard(st) }
            }
            .padding(.horizontal, FifiLayout.screenMargin)
        }
    }

    @ViewBuilder
    private func alternativeSection(_ loc: RecipeLocalization.Localized) -> some View {
        if !alternativeGroups.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                sectionTitle(app.s[.alternativeMethods], dot: Palette.berry)
                VStack(spacing: 16) {
                    ForEach(alternativeGroups, id: \.label) { group in
                        ForEach(group.steps, id: \.n) { st in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(group.label)
                                    .fifiFont(.callout, weight: .bold)
                                    .foregroundStyle(Palette.berry)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Palette.berry.opacity(0.15), in: Capsule())
                                Text(st.text)
                                    .fifiFont(.body)
                                    .foregroundStyle(Palette.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(26)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.tomatoSoft.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .stroke(Palette.berry.opacity(0.3), lineWidth: 2))
                        }
                    }
                }
                .padding(.horizontal, FifiLayout.screenMargin)
            }
        }
    }

    @ViewBuilder
    private func tipsSection(_ loc: RecipeLocalization.Localized) -> some View {
        if !tips.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                sectionTitle(app.s[.tips], dot: Palette.sun)
                VStack(spacing: 16) {
                    ForEach(tips, id: \.n) { st in
                        Text("💡 \(st.text)")
                            .fifiFont(.body, weight: .medium)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(26)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.sunSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .stroke(Palette.cardBorder, lineWidth: 2))
                    }
                }
                .padding(.horizontal, FifiLayout.screenMargin)
            }
        }
    }

    @ViewBuilder
    private var videosSection: some View {
        if !videos.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                sectionTitle(app.s[.videos], dot: Palette.tomato)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 26) {
                        ForEach(videos, id: \.id) { v in
                            Button {
                                Task { if !(await VideoOpener.open(v)) { youtubeMissing = true } }
                            } label: {
                                VideoCardView(video: v)
                            }
                            .buttonStyle(FifiCardButton(cornerRadius: 22))
                            .accessibilityIdentifier("video-\(v.id)")
                        }
                    }
                    .padding(.horizontal, FifiLayout.screenMargin)
                    .padding(.vertical, 30)
                }
                .scrollClipDisabled()
            }
        }
    }
}

/// Row-level focus style for list items inside a card (ingredient ticks) —
/// a soft leaf wash + inset highlight instead of scaling the whole card.
struct FifiRowButton: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isFocused ? Palette.leafSoft.opacity(0.8) : Color.clear)
            .overlay(alignment: .leading) {
                Palette.leaf
                    .frame(width: isFocused ? 6 : 0)
            }
            .animation(.easeOut(duration: reduceMotion ? 0 : 0.15), value: isFocused)
    }
}
