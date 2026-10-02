import SwiftUI
import UIKit

/// Remote image with the branded produce placeholder and a soft fade-in —
/// same behaviour as the TV app's Img component.
///
/// Loads through `.task(id: url)` rather than AsyncImage: inside lazy stacks
/// AsyncImage can land in `.failure` when its request is cancelled by a
/// re-render or recycle (e.g. when images.json swaps a card's thumbnail URL
/// for the 2x one) and never retries, leaving placeholders on slow networks.
/// Here a cancelled load simply restarts the next time the view appears.
struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var cornerRadius: CGFloat = 0

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else {
                placeholder.overlay {
                    if url != nil && !failed {
                        ProgressView().tint(Palette.leafDeep)
                    }
                }
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
        .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else {
            image = nil
            return
        }
        if let cached = RemoteImageCache.shared.image(for: url) {
            image = cached
            failed = false
            return
        }
        // Keep showing the previous image (say, the card thumbnail) while
        // the sharper one loads.
        failed = false
        do {
            let loaded = try await RemoteImageLoader.load(url)
            RemoteImageCache.shared.insert(loaded.image, for: url)
            withAnimation(.easeIn(duration: 0.3)) { image = loaded.image }
        } catch {
            if !Task.isCancelled && image == nil { failed = true }
        }
    }

    private var placeholder: some View {
        ZStack {
            Palette.leafSoft
            TomatoMark()
                .frame(width: 64, height: 64)
                .opacity(0.85)
        }
    }
}

/// Decoded images shared across views, so rails that recycle cards don't
/// download or decode the same photo twice.
@MainActor
final class RemoteImageCache {
    static let shared = RemoteImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func insert(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
}

/// Fetches and decodes off the main thread. URLs carry the manifest version
/// (AppState.assetURL), so a disk URLCache is safe and survives relaunches.
enum RemoteImageLoader {
    struct Loaded: @unchecked Sendable { let image: UIImage }

    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 16 << 20, diskCapacity: 256 << 20)
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    /// Retries transient failures (cellular hand-offs, timeouts) twice.
    static func load(_ url: URL) async throws -> Loaded {
        var lastError: Error = URLError(.unknown)
        for attempt in 0..<3 {
            try Task.checkCancellation()
            do {
                let (data, response) = try await session.data(from: url)
                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    throw URLError(.badServerResponse)
                }
                guard let decoded = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                return Loaded(image: decoded.preparingForDisplay() ?? decoded)
            } catch {
                try Task.checkCancellation()
                lastError = error
                if attempt < 2 {
                    try await Task.sleep(nanoseconds: UInt64(attempt + 1) * 800_000_000)
                }
            }
        }
        throw lastError
    }
}

/// Little tomato glyph matching the TV app's placeholder SVG.
struct TomatoMark: View {
    var body: some View {
        Canvas { ctx, size in
            let r = size.width * 0.30
            let c = CGPoint(x: size.width / 2, y: size.height * 0.56)
            ctx.fill(
                Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                with: .color(Color(hex: 0xFF5A4E)))
            var leaf = Path()
            leaf.move(to: CGPoint(x: size.width * 0.37, y: size.height * 0.30))
            leaf.addLine(to: CGPoint(x: size.width * 0.45, y: size.height * 0.32))
            leaf.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.22))
            leaf.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.32))
            leaf.addLine(to: CGPoint(x: size.width * 0.63, y: size.height * 0.30))
            leaf.addLine(to: CGPoint(x: size.width * 0.57, y: size.height * 0.38))
            leaf.addQuadCurve(
                to: CGPoint(x: size.width * 0.43, y: size.height * 0.38),
                control: CGPoint(x: size.width * 0.50, y: size.height * 0.42))
            leaf.closeSubpath()
            ctx.fill(leaf, with: .color(Color(hex: 0x4CAF50)))
        }
        .accessibilityHidden(true)
    }
}

/// Warm paper backdrop used under every screen.
struct PaperBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Palette.paper, Palette.paperDeep],
            startPoint: .top, endPoint: .bottom)
        .overlay(alignment: .topTrailing) {
            RadialGradient(
                colors: [Color(hex: 0xFFCD82).opacity(0.5), .clear],
                center: .topTrailing, startRadius: 0, endRadius: 620)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            RadialGradient(
                colors: [Color(hex: 0xC4E6A0).opacity(0.45), .clear],
                center: .bottomLeading, startRadius: 0, endRadius: 620)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
