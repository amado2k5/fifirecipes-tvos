import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        content
            .background { PaperBackground() }
    }

    @ViewBuilder
    private var content: some View {
        switch app.phase {
        case .loading:
            SplashView()
        case .failed:
            ErrorView { app.retry() }
        case .pickingLanguage:
            LanguagePickerView()
        case .ready:
            MainTabs()
        }
    }
}

/// Splash shown while the manifest/first payload loads.
struct SplashView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        VStack(spacing: 24) {
            Image("Emblem")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .accessibilityHidden(true)
            Text(app.s[.appName])
                .fifiFont(.largeTitle, weight: .heavy)
                .foregroundStyle(Palette.leafDeep)
            Text(app.s[.tagline])
                .fifiFont(.title3)
                .foregroundStyle(Palette.inkDim)
            ProgressView()
                .tint(Palette.leafDeep)
                .padding(.top, 12)
                .accessibilityLabel(app.s[.loading])
        }
        .padding()
    }
}

struct MainTabs: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        TabView(selection: $app.selectedTab) {
            NavigationStack(path: $app.homePath) {
                HomeView()
                    .fifiDestinations()
            }
            .tabItem { Label(app.s[.home], systemImage: "house.fill") }
            .tag(Tab.home)

            NavigationStack(path: $app.chaptersPath) {
                ChaptersView()
                    .fifiDestinations()
            }
            .tabItem { Label(app.s[.chapters], systemImage: "books.vertical.fill") }
            .tag(Tab.chapters)

            NavigationStack(path: $app.searchPath) {
                SearchView()
                    .fifiDestinations()
            }
            .tabItem { Label(app.s[.search], systemImage: "magnifyingglass") }
            .tag(Tab.search)

            NavigationStack(path: $app.kidsPath) {
                KidsView()
                    .fifiDestinations()
            }
            .tabItem { Label(app.s[.kids], systemImage: "face.smiling.inverse") }
            .tag(Tab.kids)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(app.s[.settings], systemImage: "gearshape.fill") }
            .tag(Tab.settings)
        }
        .tint(Palette.leaf)
    }
}

extension View {
    /// Shared navigation destinations for every tab stack.
    func fifiDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .recipe(let id):
                RecipeDetailView(id: id)
            case .chapter(let id):
                ChapterDetailView(chapterID: id)
            case .kidsReady(let id):
                KidsReadyView(id: id)
            case .kidsSteps(let id):
                KidsStepsView(id: id)
            case .kidsDone(let id, let title):
                KidsDoneView(id: id, title: title)
            }
        }
    }
}
