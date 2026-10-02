import SwiftUI

/// Chapters tab: grid of chapter cards.
struct ChaptersView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 420), spacing: 30)],
                spacing: 30
            ) {
                ForEach(app.chapters) { chapter in
                    Button {
                        app.chaptersPath.append(AppRoute.chapter(chapter.id))
                    } label: {
                        ChapterCardView(chapter: chapter)
                    }
                    .buttonStyle(FifiCardButton())
                    .accessibilityIdentifier("chapter-\(chapter.id)")
                }
            }
            .padding(.horizontal, FifiLayout.screenMargin)
            .padding(.vertical, 40)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chaptersScreen")
    }
}

/// Chapter detail: virtualized grid of the chapter's recipes — chapters can
/// hold 300+ cards, so LazyVGrid does the windowing.
struct ChapterDetailView: View {
    @EnvironmentObject private var app: AppState
    @FocusState private var focusedCard: String?
    let chapterID: Int

    private var cards: [RecipeCard] {
        app.index.values.filter { $0.chapter == chapterID }
            .sorted { $0.id < $1.id }
    }

    private var title: String {
        app.chapters.first { $0.id == chapterID }?.name
            ?? cards.first?.chapterName
            ?? app.s[.chapters]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .firstTextBaseline, spacing: 24) {
                    Text(title)
                        .fifiFont(.largeTitle, weight: .heavy)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Text("\(cards.count)")
                        .fifiFont(.title3, weight: .medium)
                        .foregroundStyle(Palette.leafDeep)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Palette.leafSoft, in: Capsule())
                }
                .padding(.horizontal, FifiLayout.screenMargin)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 360), spacing: 30)],
                    spacing: 30
                ) {
                    ForEach(cards) { card in
                        Button {
                            app.chaptersPath.append(AppRoute.recipe(card.id))
                        } label: {
                            RecipeCardView(card: card)
                        }
                        .buttonStyle(FifiCardButton())
                        .focused($focusedCard, equals: card.id)
                    }
                }
                .padding(.horizontal, FifiLayout.screenMargin)
            }
            .padding(.vertical, 30)
        }
        // No .navigationTitle: the heading above already shows it, and tvOS
        // would pin a second copy over the scrolling grid.
        .defaultFocus($focusedCard, cards.first?.id ?? "")
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chapterDetail")
    }
}
