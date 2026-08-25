import Foundation

/// Serialisierbarer Container: alle Themes plus das aktuell aktive.
private struct StoreData: Codable {
    var themes: [Theme]
    var activeThemeID: UUID?
}

/// Lädt/speichert Themes als JSON unter
/// ~/Library/Application Support/ThemeSwitcher/themes.json
final class ThemeStore {
    static let shared = ThemeStore()

    private(set) var themes: [Theme] = []
    private(set) var activeThemeID: UUID?

    /// Wird nach jeder Änderung aufgerufen (z.B. um das Menü neu aufzubauen).
    var onChange: (() -> Void)?

    private let fileURL: URL

    private init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("ThemeSwitcher", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        self.fileURL = dir.appendingPathComponent("themes.json")
        load()
    }

    // MARK: - Persistenz

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(StoreData.self, from: data) else {
            seed()
            return
        }
        themes = decoded.themes
        activeThemeID = decoded.activeThemeID
    }

    private func save() {
        let data = StoreData(themes: themes, activeThemeID: activeThemeID)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let encoded = try? encoder.encode(data) {
            try? encoded.write(to: fileURL, options: .atomic)
        }
        onChange?()
    }

    /// Beispiel-Themes beim allerersten Start.
    private func seed() {
        themes = [
            Theme(name: "Hell", appearance: .light, menuBar: .visible),
            Theme(name: "Dunkel", appearance: .dark, menuBar: .visible)
        ]
        activeThemeID = nil
        save()
    }

    // MARK: - CRUD

    func add(_ theme: Theme) {
        themes.append(theme)
        save()
    }

    func update(_ theme: Theme) {
        guard let idx = themes.firstIndex(where: { $0.id == theme.id }) else { return }
        themes[idx] = theme
        save()
    }

    func delete(id: UUID) {
        themes.removeAll { $0.id == id }
        if activeThemeID == id { activeThemeID = nil }
        save()
    }

    func setActive(id: UUID?) {
        activeThemeID = id
        save()
    }

    func theme(id: UUID) -> Theme? {
        themes.first { $0.id == id }
    }
}
