import SwiftUI

/// Native tvOS search: the system's remote-driven search field (with Siri
/// dictation) plus a results grid. Same matching rule as the other clients:
/// every whitespace-separated term must appear in the haystack.
struct SearchView: View {
    @EnvironmentObject private var app: AppState
    @State private var query = ""
    @State private var haystack: SearchIndex?

    private let maxResults = 48

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                    if results.isEmpty {
                        Text(app.s[.noResults])
                            .fifiFont(.title3, weight: .medium)
                            .foregroundStyle(Palette.inkDim)
                            .padding(.horizontal, FifiLayout.screenMargin)
                            .padding(.top, 30)
                            .accessibilityIdentifier("noResults")
                    } else {
                        Text("\(app.s[.resultsFor]) “\(query.trimmingCharacters(in: .whitespaces))”")
                            .fifiFont(.title3, weight: .bold)
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, FifiLayout.screenMargin)
                            .padding(.top, 30)
                    }
                }
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 360), spacing: 30)],
                    spacing: 30
                ) {
                    ForEach(results, id: \.self) { id in
                        if let card = app.index[id] {
                            Button {
                                app.searchPath.append(AppRoute.recipe(id))
                            } label: {
                                RecipeCardView(card: card)
                            }
                            .buttonStyle(FifiCardButton())
                        }
                    }
                }
                .padding(.horizontal, FifiLayout.screenMargin)
            }
            .padding(.bottom, 60)
        }
        .searchable(text: $query, prompt: app.s[.searchTitle])
        .task(id: app.lang) { await loadHaystack() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("searchScreen")
    }

    private var results: [String] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty, let haystack else { return [] }
        let terms = q.split(whereSeparator: { $0 == " " })
        var out: [String] = []
        for (id, text) in haystack where terms.allSatisfy({ text.contains($0) }) && app.index[id] != nil {
            out.append(id)
            if out.count >= maxResults { break }
        }
        return out
    }

    private func loadHaystack() async {
        haystack = (try? await APIClient.shared.search(lang: app.lang)) ?? [:]
    }
}
