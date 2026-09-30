import SwiftUI

/// Fresh-market palette — identical hex values to the Fire TV app.
enum Palette {
    static let paper = Color(hex: 0xFDF4E3)
    static let paperDeep = Color(hex: 0xF6E9D2)
    static let card = Color(hex: 0xFFFDF8)
    static let cardHover = Color(hex: 0xFDEED6)
    static let cardBorder = Color(hex: 0xF0E2C8)
    static let ink = Color(hex: 0x43311F)
    static let inkDim = Color(hex: 0x6F5B42) // TV: #7d6a52, darkened for ≥4.5:1 on paper
    static let leaf = Color(hex: 0x4D9426)
    static let leafDeep = Color(hex: 0x3A7A1E)
    static let leafSoft = Color(hex: 0xE6F3D8)
    static let tomato = Color(hex: 0xE8590C)
    static let tomatoSoft = Color(hex: 0xFDE4D3)
    static let sun = Color(hex: 0xFFC53D)
    static let sunSoft = Color(hex: 0xFFF3C4)
    static let berry = Color(hex: 0xD6336C)
    static let sky = Color(hex: 0x74C0FC)
}

/// Kids mode palette, mirroring the TV kids screens / website Cooking with Kids.
enum KidsPalette {
    static let ink = Color(hex: 0x4A3426)
    static let dim = Color(hex: 0x8A6F52)
    static let body = Color(hex: 0x7A5C3E)
    static let canvas = Color(hex: 0xFFF8E7)
    static let dot = Color(hex: 0xF5D9A8)
    static let cardBorder = Color(hex: 0xF0E2C8)
    static let checkGreen = Color(hex: 0x7CB342)
    static let checkBorder = Color(hex: 0x558B2F)
    static let checkSoft = Color(hex: 0xF1F8E9)
    static let stepOrange = Color(hex: 0xFF8A65)
    static let chipIdle = Color(hex: 0xE8D9BD)
    static let chipText = Color(hex: 0x6B5335)
    static let warnBg = Color(hex: 0xFF8A80).opacity(0.25)
    static let warnText = Color(hex: 0xA13333)
    static let frostBg = Color(hex: 0xB3E5FC)
    static let frostText = Color(hex: 0x14455E)
    static let hotBg = Color(hex: 0xFFCCBC)
    static let hotText = Color(hex: 0x7C2D12)
    static let tipBg = Color(hex: 0xFFF3C4)
    static let tipText = Color(hex: 0x5D4317)
    static let purple = Color(hex: 0x8E6FC0)
    static let meta = Color(hex: 0xFFD93B)

    static let rainbow = LinearGradient(
        colors: [
            Color(hex: 0xFF8A80), Color(hex: 0xFFD54F), Color(hex: 0xAED581),
            Color(hex: 0x4FC3F7), Color(hex: 0xBA68C8), Color(hex: 0xFF8A80),
        ],
        startPoint: .leading, endPoint: .trailing)

    static let goGradient = LinearGradient(
        colors: [Color(hex: 0x7CB342), Color(hex: 0x43A047)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let doneGradient = LinearGradient(
        colors: [Color(hex: 0xEC407A), Color(hex: 0xD6336C)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// Per-group kids styling — same hues as the TV app's KIDS_GROUP_STYLE
/// (Tailwind amber/lime/rose/pink/sky ranges).
struct KidsGroupStyle {
    let card: Color
    let border: Color
    let chip: Color
    let chipBorder: Color
    let emoji: String

    static func forGroup(_ group: String?) -> KidsGroupStyle {
        switch group {
        case "breakfast":
            return KidsGroupStyle(card: Color(hex: 0xFEF3C7), border: Color(hex: 0xFCD34D),
                                  chip: Color(hex: 0xFBBF24), chipBorder: Color(hex: 0xF59E0B), emoji: "🥞")
        case "snack":
            return KidsGroupStyle(card: Color(hex: 0xECFCCB), border: Color(hex: 0xBEF264),
                                  chip: Color(hex: 0xA3E635), chipBorder: Color(hex: 0x84CC16), emoji: "🍎")
        case "savoury":
            return KidsGroupStyle(card: Color(hex: 0xFFE4E6), border: Color(hex: 0xFDA4AF),
                                  chip: Color(hex: 0xFB7185), chipBorder: Color(hex: 0xF43F5E), emoji: "🍕")
        case "sweet":
            return KidsGroupStyle(card: Color(hex: 0xFCE7F3), border: Color(hex: 0xF9A8D4),
                                  chip: Color(hex: 0xF472B6), chipBorder: Color(hex: 0xEC4899), emoji: "🧁")
        case "drink":
            return KidsGroupStyle(card: Color(hex: 0xE0F2FE), border: Color(hex: 0x7DD3FC),
                                  chip: Color(hex: 0x38BDF8), chipBorder: Color(hex: 0x0EA5E9), emoji: "🥤")
        default:
            return KidsGroupStyle(card: Color(hex: 0xFEF3C7), border: Color(hex: 0xFCD34D),
                                  chip: Color(hex: 0xFBBF24), chipBorder: Color(hex: 0xF59E0B), emoji: "🍽️")
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
