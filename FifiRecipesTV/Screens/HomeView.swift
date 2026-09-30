import SwiftUI

/// Home: focusable hero card from the "featured" feed row, then one
/// horizontal rail per feed row (featured, recent, per-chapter, kids).
/// Rails scroll horizontally; the focus engine handles remote navigation.
struct HomeView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 44, pinnedViews: []) {
                hero
                ForEach(app.feed.rows, id: \.key) { row in
                    RailView(row: row)
                }
            }
            .padding(.bottom, 60)
            .padding(.top, 20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("homeScreen")
    }

    @ViewBuilder
    private var hero: some View {
        let featured = app.feed.rows.first { $0.key == "featured" }?.items ?? []
        if let id = featured.first, let card = app.index[id] {
            Button {
                app.homePath.append(AppRoute.recipe(card.id))
            } label: {
                ZStack(alignment: .bottomLeading) {
                    RemoteImage(url: heroURL(card))
                        .frame(height: 460)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    LinearGradient(
                        colors: [.clear, Palette.ink.opacity(0.8)],
                        startPoint: .init(x: 0.5, y: 0.2), endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 14) {
                        Text(app.s[.tagline])
                            .fifiFont(.callout, weight: .medium)
                            .foregroundStyle(.white.opacity(0.9))
                        Text(card.title)
                            .fifiFont(.largeTitle, weight: .heavy)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 12) {
                            MetaChip(text: card.prepTime ?? "", tone: .leaf)
                                .opacity(card.prepTime == nil ? 0 : 1)
                            MetaChip(text: card.cookTime ?? "", tone: .tomato)
                                .opacity(card.cookTime == nil ? 0 : 1)
                            MetaChip(text: card.servings ?? "", tone: .sun)
                                .opacity(card.servings == nil ? 0 : 1)
                        }
                    }
                    .padding(40)
                }
            }
            .buttonStyle(FifiCardButton(cornerRadius: 32, focusedScale: 1.02))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Palette.cardBorder, lineWidth: 2))
            .shadow(color: Palette.ink.opacity(0.10), radius: 20, y: 10)
            .padding(.horizontal, FifiLayout.screenMargin)
            .accessibilityLabel(card.title)
            .accessibilityIdentifier("heroCard")
        }
    }

    private func heroURL(_ card: RecipeCard) -> URL? {
        let info = app.images[card.id]
        return app.assetURL(info?.full2x ?? info?.full ?? card.image)
    }
}

/// One titled horizontal rail of recipe or kids cards.
struct RailView: View {
    @EnvironmentObject private var app: AppState
    let row: FeedRow

    var body: some View {
        if !row.items.isEmpty {
            VStack(alignment: .leading, spacing: 18) {
                Text(row.title)
                    .fifiFont(.title2, weight: .bold)
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, FifiLayout.screenMargin)
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 30) {
                        ForEach(row.items, id: \.self) { id in
                            railItem(id)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, FifiLayout.screenMargin)
                    // Extra breathing room so focused cards can scale/lift
                    // without clipping against neighbours.
                    .padding(.vertical, 30)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(row.title)
        }
    }

    @ViewBuilder
    private func railItem(_ id: String) -> some View {
        if row.key == "kids" {
            if let card = app.kids[id] {
                Button {
                    app.homePath.append(AppRoute.kidsReady(card.id))
                } label: {
                    KidsCardView(card: card, minutesLabel: app.s[.minutesShort])
                        .frame(width: FifiLayout.railCardWidth)
                        .kidsFontScope()
                }
                .buttonStyle(FifiCardButton(cornerRadius: 30))
                .accessibilityIdentifier("kidsRailCard-\(id)")
            }
        } else if let card = app.index[id] {
            Button {
                app.homePath.append(AppRoute.recipe(card.id))
            } label: {
                RecipeCardView(card: card)
                    .frame(width: FifiLayout.railCardWidth)
            }
            .buttonStyle(FifiCardButton())
            .accessibilityIdentifier("railCard-\(id)")
        }
    }
}
