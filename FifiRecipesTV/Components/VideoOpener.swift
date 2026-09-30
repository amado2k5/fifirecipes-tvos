import UIKit

/// YouTube handoff for tvOS. WKWebView doesn't exist on tvOS, so videos open
/// in the YouTube Apple TV app via its universal link. When the app isn't
/// installed the open call fails and callers show the `youtubeAppNeeded`
/// hint instead.
enum VideoOpener {
    static func watchURL(_ video: VideoItem) -> URL? {
        URL(string: "https://www.youtube.com/watch?v=\(video.id)")
    }

    /// Opens the video in the YouTube app. `false` means no app could handle
    /// the link — show the install hint.
    @MainActor
    @discardableResult
    static func open(_ video: VideoItem) async -> Bool {
        guard let url = watchURL(video) else { return false }
        return await UIApplication.shared.open(url)
    }
}
