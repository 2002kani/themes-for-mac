import Foundation

/// Erscheinungsbild-Modus eines Themes.
/// `.unchanged` bedeutet: beim Anwenden nicht anfassen.
enum Appearance: String, Codable, CaseIterable, Identifiable {
    case unchanged
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .unchanged: return "Unverändert"
        case .light: return "Hell"
        case .dark: return "Dunkel"
        }
    }
}

/// Symbol- & Widget-Stil (macOS 26 „AppleIconAppearanceTheme").
/// Der Light/Dark-Suffix wird beim Anwenden aus dem Erscheinungsbild abgeleitet.
enum IconStyle: String, Codable, CaseIterable, Identifiable {
    case unchanged
    case standard      // Schlüssel entfernt (folgt automatisch dem Erscheinungsbild)
    case dark          // RegularDark
    case transparent   // Clear{Light|Dark}
    case tinted        // Tinted{Light|Dark}

    var id: String { rawValue }

    var label: String {
        switch self {
        case .unchanged: return "Unverändert"
        case .standard: return "Standard"
        case .dark: return "Dunkel"
        case .transparent: return "Transparent"
        case .tinted: return "Eingefärbt"
        }
    }
}

/// Verhalten der Menüleiste.
enum MenuBarMode: String, Codable, CaseIterable, Identifiable {
    case unchanged
    case visible
    case autohide

    var id: String { rawValue }

    var label: String {
        switch self {
        case .unchanged: return "Unverändert"
        case .visible: return "Immer sichtbar"
        case .autohide: return "Automatisch ausblenden"
        }
    }
}

/// Zuordnung eines Hintergrundbilds zu einem konkreten Bildschirm.
struct ScreenWallpaper: Codable, Equatable, Identifiable {
    var screenID: String     // stabile Display-UUID
    var screenName: String   // Anzeigename (nur für die UI)
    var path: String         // absoluter Pfad zum Bild
    var id: String { screenID }
}

/// Ein Theme bündelt mehrere Systemeinstellungen, die gemeinsam gesetzt werden.
struct Theme: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var appearance: Appearance = .unchanged
    /// Hintergrundbilder pro Bildschirm (leer = Hintergrund nicht anfassen).
    var wallpapers: [ScreenWallpaper] = []
    var menuBar: MenuBarMode = .unchanged
    var iconStyle: IconStyle = .unchanged

    static func newEmpty(name: String = "Neues Theme") -> Theme {
        Theme(name: name)
    }
}
