import SwiftUI

@main
struct FifiRecipesTVApp: App {
    @StateObject private var app = AppState()

    init() {
        // Screenshot/UI-test hooks:
        //   -fifi.reset 1        → wipe the persisted language (first-run picker)
        //   -fifi.language ar    → preselect a language (skips the picker)
        //   -fifi.apiOrigin URL  → point the API elsewhere (offline test)
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-fifi.reset") {
            UserDefaults.standard.removeObject(forKey: "fifi.language")
        }
        if let i = args.firstIndex(of: "-fifi.language"), args.indices.contains(i + 1) {
            UserDefaults.standard.set(args[i + 1], forKey: "fifi.language")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .environment(\.fifiLanguage, app.lang)
                .environment(\.layoutDirection, app.layoutDirection)
                .onAppear { app.start() }
                .tint(Palette.tomato)
        }
    }
}
