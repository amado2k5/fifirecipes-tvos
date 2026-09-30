import SwiftUI

/// Full-screen error state with retry — used for every endpoint failure,
/// matching the TV app's ErrorScreen.
struct ErrorView: View {
    @EnvironmentObject private var app: AppState
    var onRetry: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            Image("Emblem")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .saturation(0.6)
                .opacity(0.9)
            Text(app.s[.errorTitle])
                .fifiFont(.title2, weight: .bold)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(app.s[.errorBody])
                .fifiFont(.body)
                .foregroundStyle(Palette.inkDim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 760)
            Button(action: onRetry) {
                Label(app.s[.retry], systemImage: "arrow.clockwise")
                    .fifiFont(.headline, weight: .bold)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 22)
            }
            .buttonStyle(FifiCapsuleButton(fill: Palette.leaf))
            .accessibilityIdentifier("retryButton")
            .padding(.top, 8)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("errorScreen")
    }
}

/// Skeleton shimmer while content loads.
struct ShimmerBox: View {
    var cornerRadius: CGFloat = 20
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Palette.cardBorder.opacity(0.6))
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { tl in
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Palette.cardBorder.opacity(0.6))
                    .overlay {
                        let t = tl.date.timeIntervalSinceReferenceDate
                        let x = CGFloat(t.truncatingRemainder(dividingBy: 1.6)) / 1.6
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Palette.card.opacity(0.9), .clear],
                                    startPoint: .init(x: x - 0.3, y: 0.5),
                                    endPoint: .init(x: x + 0.3, y: 0.5)))
                    }
                    .clipped()
            }
        }
    }
}

/// Card-shaped skeleton grid, shown while a screen's first payload arrives.
struct LoadingGridView: View {
    var body: some View {
        ScrollView {
            ShimmerBox(cornerRadius: 30).frame(height: 340).padding(.horizontal, 90)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 30)], spacing: 30) {
                ForEach(0..<8, id: \.self) { _ in
                    VStack(spacing: 0) {
                        ShimmerBox(cornerRadius: 0).aspectRatio(16 / 9, contentMode: .fill)
                        ShimmerBox(cornerRadius: 0).frame(height: 80)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
            .padding(.horizontal, 90)
            .padding(.top, 30)
        }
        .accessibilityLabel(Text("Loading"))
    }
}

/// Simple centered spinner text for small inline loads.
struct LoadingView: View {
    let label: String
    var body: some View {
        VStack(spacing: 20) {
            ProgressView().tint(Palette.leafDeep)
            Text(label)
                .fifiFont(.body)
                .foregroundStyle(Palette.inkDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
