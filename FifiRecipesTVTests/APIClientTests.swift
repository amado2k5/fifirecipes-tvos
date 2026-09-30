import XCTest
@testable import FifiRecipesTV

/// In-memory URLProtocol so API tests never touch the network.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: (@Sendable (URL) -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        // Strip the version query so fixtures can key on the bare path.
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        comps?.query = nil
        let (status, data) = handler(comps?.url ?? url)
        let response = HTTPURLResponse(
            url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class PathLog: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []
    var paths: [String] { lock.lock(); defer { lock.unlock() }; return storage }
    func append(_ path: String) { lock.lock(); storage.append(path); lock.unlock() }
}

private func json(_ value: String) -> Data { Data(value.utf8) }

final class APIClientTests: XCTestCase {

    private var client: APIClient!

    override func setUp() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        client = APIClient(testSession: URLSession(configuration: config))
    }

    private func respond(_ handler: @escaping @Sendable (URL) -> (Int, Data)) {
        MockURLProtocol.handler = handler
    }

    func testManifestLoadsAndFeedsVersionedURLs() async throws {
        respond { url in
            XCTAssertEqual(url.path, "/data/tv/manifest.json")
            return (200, json("""
                {"version":"v123","generatedAt":"x","recipeCount":1,"pageSize":100,
                 "languages":[],"endpoints":
                 {"index":"","feed":"","chapters":"","kids":"","recipe":"","i18n":"",
                  "search":"","videos":"","kidsRecipe":"","images":""}}
                """))
        }
        let m = try await client.loadManifest()
        XCTAssertEqual(m.version, "v123")
        let p = await client.versionedPath("/data/tv/index/en.json")
        XCTAssertEqual(p, "/data/tv/index/en.json?v=v123")
    }

    func testUnversionedPathBeforeManifest() async throws {
        let p = await client.versionedPath("/data/x.json")
        XCTAssertEqual(p, "/data/x.json")
    }

    func testIndexDecodes() async throws {
        respond { url in
            XCTAssertEqual(url.path, "/data/tv/index/en.json")
            return (200, json("""
                [{"id":"r1","title":"Koshari","chapter":3,"hasVideo":true,
                  "image":"/recipe-images/thumbs/koshari.jpg"}]
                """))
        }
        let cards = try await client.index(lang: "en")
        XCTAssertEqual(cards.first?.id, "r1")
        XCTAssertEqual(cards.first?.hasVideo, true)
    }

    func testKidsFallsBackToEnglishOn404() async throws {
        let hits = PathLog()
        respond { url in
            hits.append(url.path)
            if url.path == "/data/tv/kids/xx.json" { return (404, Data()) }
            return (200, json("""
                [{"id":"k1","title":"Pancakes","group":"breakfast","ages":"4-6",
                  "minutes":20,"noCook":false,"cover":"pancake"}]
                """))
        }
        let cards = try await client.kids(lang: "xx")
        XCTAssertEqual(cards.first?.id, "k1")
        XCTAssertEqual(hits.paths, ["/data/tv/kids/xx.json", "/data/tv/kids/en.json"])
    }

    func testHTTPErrorSurfacesStatus() async throws {
        respond { _ in (500, Data()) }
        do {
            _ = try await client.index(lang: "en")
            XCTFail("expected failure")
        } catch APIError.http(let status, _) {
            XCTAssertEqual(status, 500)
        }
    }

    // MARK: asset URL + video picking

    func testAssetURLResolvesAndVersions() {
        XCTAssertEqual(
            AssetURL.resolve("/recipe-images/x.jpg", version: "v1",
                             origin: "https://fifi.cooking")?.absoluteString,
            "https://fifi.cooking/recipe-images/x.jpg?v=v1")
        XCTAssertEqual(
            AssetURL.resolve("https://cdn.example.com/y.jpg", version: "v1")?.absoluteString,
            "https://cdn.example.com/y.jpg")
        XCTAssertNil(AssetURL.resolve(nil, version: "v1"))
        XCTAssertNil(AssetURL.resolve("", version: "v1"))
    }

    func testVideoPickingOrder() {
        let v = VideoItem(id: "abc", title: "T", channel: nil, duration: nil, views: nil, short: nil)
        XCTAssertEqual(APIClient.pickVideos(["fr": [v]], lang: "fr").count, 1)
        XCTAssertEqual(APIClient.pickVideos(["ar": [v]], lang: "de").count, 1) // ar fallback
        XCTAssertEqual(APIClient.pickVideos(["en": [v]], lang: "ar").count, 1) // en last
        XCTAssertTrue(APIClient.pickVideos([:], lang: "ar").isEmpty)
    }
}
