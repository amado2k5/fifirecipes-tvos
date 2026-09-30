import Foundation

/// Codable models matching docs/tv-api.md in the fifirecipes repo —
/// the same contract the Fire TV client (src/api/types.ts) decodes.

struct LanguageInfo: Codable, Equatable, Hashable {
    let code: String
    let nativeName: String
    let englishName: String
    let dir: String
    let complete: Bool

    var isRTL: Bool { dir == "rtl" }
}

struct EndpointTemplates: Codable, Equatable {
    let index: String
    let feed: String
    let chapters: String
    let kids: String
    let recipe: String
    let i18n: String
    let search: String
    let videos: String
    let kidsRecipe: String
    let images: String

    static let `default` = EndpointTemplates(
        index: "/data/tv/index/{lang}.json",
        feed: "/data/tv/feed/{lang}.json",
        chapters: "/data/tv/chapters/{lang}.json",
        kids: "/data/tv/kids/{lang}.json",
        recipe: "/data/recipes/{id}.json",
        i18n: "/data/i18n/{lang}.json",
        search: "/data/search/{lang}.json",
        videos: "/data/videos/{id}.json",
        kidsRecipe: "/data/kids/{lang}/{id}.json",
        images: "/data/tv/images.json"
    )
}

struct TvManifest: Codable, Equatable {
    let version: String
    let generatedAt: String
    let recipeCount: Int
    let pageSize: Int
    let languages: [LanguageInfo]
    let endpoints: EndpointTemplates
}

/// One entry in tv/index/{lang}.json
struct RecipeCard: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let titleEn: String?
    let category: String?
    let cookingMethod: String?
    let prepTime: String?
    let cookTime: String?
    let servings: String?
    let difficulty: String?
    let image: String?
    let hasVideo: Bool?
    let chapter: Int?
    let chapterName: String?
}

struct FeedRow: Codable, Equatable, Hashable {
    let key: String
    let title: String
    let items: [String]
}

struct Feed: Codable, Equatable {
    let rows: [FeedRow]
}

struct Chapter: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let recipeCount: Int
    let coverImage: String?
}

struct KidsCard: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let group: String
    let ages: String
    let minutes: Int
    let noCook: Bool
    let allergens: [String]?
    let cover: String
}

struct ImageInfo: Codable, Equatable {
    let card: String
    let card2x: String?
    let full: String
    let full2x: String?
    let w: Int
    let h: Int
}

/// /data/recipes/{id}.json
struct RecipeIngredient: Codable, Equatable {
    let id: String
    let name: String
    let standardAmount: String?
    let notes: String?
}

struct RecipeInstruction: Codable, Equatable {
    let stepNumber: Int
    let text: String
    let textEn: String?
    let phase: String?
    let isAlternative: Bool?
    let alternativeLabel: String?
    let importance: String?
}

struct RawDocVersion: Codable, Equatable {
    let title: String
    let pageNumber: Int?
    let ingredients: [String]
    let instructions: [String]
    let notes: [String]?
}

struct RecipeCore: Codable, Equatable {
    let id: String
    let title: String
    let titleEn: String?
    let chapter: String?
    let chapterNumber: Int?
    let category: String?
    let cookingMethod: String?
    let prepTime: String?
    let cookTime: String?
    let servings: String?
    let masterIngredients: [RecipeIngredient]
    let uniqueInstructions: [RecipeInstruction]
    let rawDocVersions: [String: RawDocVersion]?
}

struct IngredientTranslation: Codable, Equatable {
    let name: String?
    let standardAmount: String?
}

struct RecipeTranslation: Codable, Equatable {
    let title: String?
    let chapter: String?
    let category: String?
    let cookingMethod: String?
    let prepTime: String?
    let cookTime: String?
    let servings: String?
    let culturalNotes: String?
    let ingredients: [String: IngredientTranslation]?
    let instructions: [String: String]?
}

struct RecipeEstimate: Codable, Equatable {
    let servings: Int?
    let kcal: Int?
    let protein: Int?
    let fat: Int?
    let carbs: Int?
    let fiber: Int?
    let sugar: Int?
}

struct RecipeFile: Codable, Equatable {
    let recipe: RecipeCore
    let estimate: RecipeEstimate?
    let translations: [String: RecipeTranslation]
}

/// /data/videos/{id}.json — YouTube hits per language.
struct VideoItem: Codable, Equatable, Hashable, Identifiable {
    let id: String
    let title: String
    let channel: String?
    let duration: String?
    let views: String?
    let short: Bool?
}

typealias VideoFile = [String: [VideoItem]]

/// /data/kids/{lang}/{id}.json
struct KidsIngredient: Codable, Equatable {
    let art: String
    let text: String
}

struct KidsStep: Codable, Equatable {
    let act: String?
    let items: [String]?
    let tool: String?
    let adult: String?
    let timer: Int?
    let text: String
}

struct KidsRecipeDetail: Codable, Equatable {
    let id: String
    let group: String
    let ages: String
    let minutes: Int
    let servings: Int?
    let noCook: Bool
    let allergens: [String]?
    let cover: String
    let title: String
    let intro: String?
    let ingredients: [KidsIngredient]
    let tools: [String]?
    let steps: [KidsStep]
    let tip: String?
}

typealias SearchIndex = [String: String]
typealias ImagesMap = [String: ImageInfo]
