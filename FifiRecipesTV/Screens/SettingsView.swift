import SwiftUI

/// Settings: language row (opens the picker), About, version info.
/// Presented as focusable cards in a centred column — the 10-foot pattern.
struct SettingsView: View {
    @EnvironmentObject private var app: AppState
    @State private var showPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                Button { showPicker = true } label: {
                    settingsRow(icon: "globe") {
                        HStack {
                            Text(app.s[.language])
                                .fifiFont(.title3, weight: .bold)
                                .foregroundStyle(Palette.ink)
                            Spacer()
                            Text(languageLabel)
                                .fifiFont(.callout, weight: .medium)
                                .foregroundStyle(Palette.leafDeep)
                        }
                    }
                }
                .buttonStyle(FifiCardButton(cornerRadius: 26, focusedScale: 1.02))
                .accessibilityIdentifier("settingsLanguageRow")

                settingsRow(icon: "info.circle") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(app.s[.about])
                            .fifiFont(.title3, weight: .bold)
                            .foregroundStyle(Palette.ink)
                        Text(app.s[.aboutText])
                            .fifiFont(.body)
                            .foregroundStyle(Palette.inkDim)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("fifi.cooking")
                            .fifiFont(.callout, weight: .medium)
                            .foregroundStyle(Palette.leafDeep)
                    }
                }

                settingsRow(icon: "cube.box") {
                    HStack {
                        Text(app.s[.version])
                            .fifiFont(.title3, weight: .bold)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                        Text("fifi.cooking · \(app.manifest?.version ?? "—")")
                            .fifiFont(.callout)
                            .foregroundStyle(Palette.inkDim)
                    }
                }
            }
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, FifiLayout.screenMargin)
            .padding(.vertical, 50)
        }
        .fullScreenCover(isPresented: $showPicker) {
            LanguagePickerView()
                .environmentObject(app)
                .environment(\.fifiLanguage, app.lang)
                .background { PaperBackground() }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settingsScreen")
    }

    private var languageLabel: String {
        guard let info = app.langInfo else { return app.lang }
        return "\(info.nativeName) (\(info.englishName))"
    }

    private func settingsRow<Content: View>(
        icon: String, @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 24) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Palette.leafDeep)
                .frame(width: 72, height: 72)
                .background(Palette.leafSoft, in: RoundedRectangle(cornerRadius: 18))
            content()
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Palette.cardBorder, lineWidth: 2))
    }
}
