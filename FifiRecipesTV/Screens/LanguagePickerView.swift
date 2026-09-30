import SwiftUI

/// First-run language picker — large focusable tiles with each language's
/// native and English names; also reachable from Settings as a full cover.
struct LanguagePickerView: View {
    @EnvironmentObject private var app: AppState
    @FocusState private var focused: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image("Emblem")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .accessibilityHidden(true)
                Text(app.s[.appName])
                    .fifiFont(.largeTitle, weight: .heavy)
                    .foregroundStyle(Palette.leafDeep)
                Text(app.s[.chooseLanguage])
                    .fifiFont(.title3)
                    .foregroundStyle(Palette.inkDim)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 340), spacing: 26)],
                spacing: 26
            ) {
                ForEach(app.manifest?.languages ?? [], id: \.code) { lang in
                    languageTile(lang)
                }
            }
            .padding(.horizontal, FifiLayout.screenMargin)
            .padding(.bottom, 60)
        }
        .onAppear { focused = app.lang }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("languagePicker")
    }

    private func languageTile(_ lang: LanguageInfo) -> some View {
        let selected = lang.code == app.lang
        return Button {
            app.setLanguage(lang.code)
        } label: {
            VStack(spacing: 4) {
                Text(lang.nativeName)
                    .fifiFont(.title3, weight: .bold)
                    .foregroundStyle(Palette.ink)
                if lang.englishName != lang.nativeName {
                    Text(lang.englishName)
                        .fifiFont(.callout)
                        .foregroundStyle(Palette.inkDim)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 110)
            .padding(.vertical, 12)
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Palette.leaf)
                        .padding(14)
                }
            }
            .background(selected ? Palette.leafSoft : Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(selected ? Palette.leaf : Palette.cardBorder,
                            lineWidth: selected ? 4 : 2))
        }
        .buttonStyle(FifiCardButton(cornerRadius: 22, focusedScale: 1.04))
        .focused($focused, equals: lang.code)
        .accessibilityIdentifier("lang-\(lang.code)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
