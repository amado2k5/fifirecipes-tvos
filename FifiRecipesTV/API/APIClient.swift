import Foundation

enum APIError: Error, Equatable {
    case http(Int, String)
    case badURL(String)
    case decoding(String)
}

/// Static JSON client for https://fifi.cooking/data/.
/// Mirrors the Fire TV client's behaviour: endpoint templates come from the
/// manifest (with defaults), every data request is versioned with ?v=, and
/// responses flow through URLCache plus a small in-memory session cache.
actor APIClient {
    static let shared = APIClient()

    /// Launch-arg `-fifi.apiOrigin <url>` overrides the host for UI tests.
    static var origin: String {
        UserDefaults.standard.string(forKey: "fifi.apiOrigin") ?? "https://fifi.cooking"
    }

    private let session: URLSession
    private var manifest: TvManifest?
    private var endpoints = EndpointTemplates.default
    private var inflight: [String: Task<Data, Error>] = [:]

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.urlCache = URLCache(memoryCapacity: 32 << 20, diskCapacity: 128 << 20)
            config.requestCachePolicy = .useProtocolCachePolicy
            self.session = URLSession(configuration: config)
        }
    }

    init(testSession session: URLSession) {
        self.session = session
    }

    // MARK: - Manifest

    @discardableResult
    func loadManifest() async throws -> TvManifest {
        let m: TvManifest = try await fetchData("\(Self.origin)/data/tv/manifest.json", cacheIt: false)
            .decoded()
        manifest = m
        endpoints = m.endpoints
        return m
    }

    var manifestVersion: String? { manifest?.version }

    // MARK: - Low-level fetch

    private func fetchData(_ urlString: String, cacheIt: Bool = true) async throws -> Data {
        guard let url = URL(string: urlString) else { throw APIError.badURL(urlString) }
        if cacheIt, let task = inflight[urlString] { return try await task.value }
        let task = Task<Data, Error> { [session] in
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw APIError.http(http.statusCode, urlString)
            }
            return data
        }
        if cacheIt { inflight[urlString] = task }
        defer { inflight[urlString] = nil }
        return try await task.value
    }

    func clearCache() {
        inflight.removeAll()
        session.configuration.urlCache?.removeAllCachedResponses()
    }

    // MARK: - Endpoint plumbing

    private func fill(_ template: String, _ vars: [String: String]) -> String {
        vars.reduce(template) { t, pair in
            t.replacingOccurrences(
                of: "{\(pair.key)}",
                with: pair.value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pair.value
            )
        }
    }

    /// Versioned path: appends ?v=<manifest version> once the manifest is loaded.
    func versionedPath(_ path: String) -> String {
        guard let v = manifest?.version,
              let escaped = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return path }
        return "\(path)?v=\(escaped)"
    }

    private func get<T: Decodable>(
        _ type: T.Type,
        endpoint: KeyPath<EndpointTemplates, String>,
        vars: [String: String] = [:]
    ) async throws -> T {
        let path = versionedPath(fill(endpoints[keyPath: endpoint], vars))
        return try await fetchData(Self.origin + path).decoded()
    }

    /// Site-relative asset path (/recipe-images/x.jpg) or external URL.
    func assetURL(_ path: String?) -> URL? {
        AssetURL.resolve(path, version: manifest?.version)
    }

    // MARK: - Typed endpoints

    func index(lang: String) async throws -> [RecipeCard] {
        try await get([RecipeCard].self, endpoint: \.index, vars: ["lang": lang])
    }

    func feed(lang: String) async throws -> Feed {
        try await get(Feed.self, endpoint: \.feed, vars: ["lang": lang])
    }

    func chapters(lang: String) async throws -> [Chapter] {
        try await get([Chapter].self, endpoint: \.chapters, vars: ["lang": lang])
    }

    /// Kids catalogue — a 404 means "this language has no kids content",
    /// so fall back to English per docs/tv-api.md.
    func kids(lang: String) async throws -> [KidsCard] {
        do {
            return try await get([KidsCard].self, endpoint: \.kids, vars: ["lang": lang])
        } catch APIError.http(404, _) {
            return try await get([KidsCard].self, endpoint: \.kids, vars: ["lang": "en"])
        }
    }

    func kidsRecipe(lang: String, id: String) async throws -> KidsRecipeDetail {
        do {
            return try await get(
                KidsRecipeDetail.self, endpoint: \.kidsRecipe,
                vars: ["lang": lang, "id": id])
        } catch APIError.http(404, _) {
            return try await get(
                KidsRecipeDetail.self, endpoint: \.kidsRecipe,
                vars: ["lang": "en", "id": id])
        }
    }

    func recipe(id: String) async throws -> RecipeFile {
        try await get(RecipeFile.self, endpoint: \.recipe, vars: ["id": id])
    }

    func videos(id: String) async throws -> VideoFile {
        try await get(VideoFile.self, endpoint: \.videos, vars: ["id": id])
    }

    func search(lang: String) async throws -> SearchIndex {
        try await get(SearchIndex.self, endpoint: \.search, vars: ["lang": lang])
    }

    func images() async throws -> ImagesMap {
        try await get(ImagesMap.self, endpoint: \.images)
    }

    /// Picks the language bucket the TV app uses: requested, else ar, else en.
    static func pickVideos(_ file: VideoFile, lang: String) -> [VideoItem] {
        file[lang] ?? file["ar"] ?? file["en"] ?? []
    }
}

enum AssetURL {
    /// Resolves a site-relative asset path (or an absolute URL) against the
    /// API origin, appending ?v=<manifest version> once known — deploys ship a
    /// new version, which naturally busts stale URLCache entries.
    static func resolve(_ path: String?, version: String?, origin: String = APIClient.origin) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") { return URL(string: path) }
        var p = path
        if let v = version, let e = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            p += "?v=\(e)"
        }
        return URL(string: origin + p)
    }
}

extension Data {
    func decoded<T: Decodable>(as type: T.Type = T.self) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: self)
        } catch {
            throw APIError.decoding("\(T.self): \(error.localizedDescription)")
        }
    }
}
