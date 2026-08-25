import AppKit

/// Wendet die Einstellungen eines Themes auf das System an.
enum SystemController {

    /// Wendet alle nicht-`unchanged` Teile eines Themes an.
    /// Gibt gesammelte Fehlermeldungen zurück (leer = alles ok).
    @discardableResult
    static func apply(_ theme: Theme) -> [String] {
        var errors: [String] = []

        if theme.appearance != .unchanged {
            if let err = setAppearance(dark: theme.appearance == .dark) {
                errors.append("Erscheinungsbild: \(err)")
            }
        }

        if !theme.wallpapers.isEmpty {
            errors.append(contentsOf: setWallpapers(theme.wallpapers))
        }

        if theme.menuBar != .unchanged {
            if let err = setMenuBar(autohide: theme.menuBar == .autohide) {
                errors.append("Menüleiste: \(err)")
            }
        }

        if theme.iconStyle != .unchanged {
            if let err = setIconStyle(theme.iconStyle, appearance: theme.appearance) {
                errors.append("Symbol-Stil: \(err)")
            }
        }

        return errors
    }

    // MARK: - Symbol- & Widget-Stil (AppleIconAppearanceTheme + Dock-Neustart)

    private static let iconThemeKey = "AppleIconAppearanceTheme"

    private static func setIconStyle(_ style: IconStyle, appearance: Appearance) -> String? {
        if style == .standard {
            // Standard = Schlüssel entfernen (Fehler ignorieren, falls nicht vorhanden).
            _ = runProcess("/usr/bin/defaults", ["delete", "NSGlobalDomain", iconThemeKey])
            return refreshDock()
        }

        // Light/Dark-Suffix aus dem Erscheinungsbild bzw. aktuellem Systemzustand ableiten.
        let isDark: Bool
        switch appearance {
        case .light: isDark = false
        case .dark: isDark = true
        case .unchanged:
            isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        }
        let suffix = isDark ? "Dark" : "Light"

        let value: String
        switch style {
        case .dark: value = "RegularDark"
        case .transparent: value = "Clear" + suffix
        case .tinted: value = "Tinted" + suffix
        case .standard, .unchanged: return nil
        }

        if let err = runProcess("/usr/bin/defaults",
                                ["write", "NSGlobalDomain", iconThemeKey, "-string", value]) {
            return err
        }
        return refreshDock()
    }

    /// Startet das Dock neu, damit der Symbol-/Widget-Stil sofort greift.
    private static func refreshDock() -> String? {
        return runProcess("/usr/bin/killall", ["Dock"])
    }

    /// Führt ein Kommandozeilen-Tool aus. Gibt nil bei Erfolg, sonst eine Fehlermeldung.
    @discardableResult
    private static func runProcess(_ path: String, _ args: [String]) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        let errPipe = Pipe()
        proc.standardError = errPipe
        do {
            try proc.run()
            proc.waitUntilExit()
            if proc.terminationStatus != 0 {
                let data = errPipe.fileHandleForReading.readDataToEndOfFile()
                let msg = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return msg.isEmpty ? "Exit-Code \(proc.terminationStatus)" : msg
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    // MARK: - Erscheinungsbild (AppleScript / System Events)

    private static func setAppearance(dark: Bool) -> String? {
        let script = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to \(dark ? "true" : "false")
            end tell
        end tell
        """
        return runAppleScript(script)
    }

    // MARK: - Menüleiste (AppleScript / System Events → Dock preferences)

    private static func setMenuBar(autohide: Bool) -> String? {
        let script = """
        tell application "System Events"
            tell dock preferences
                set autohide menu bar to \(autohide ? "true" : "false")
            end tell
        end tell
        """
        return runAppleScript(script)
    }

    // MARK: - Wallpaper pro Bildschirm (NSWorkspace, public API)

    private static func setWallpapers(_ wallpapers: [ScreenWallpaper]) -> [String] {
        var errors: [String] = []
        let ws = NSWorkspace.shared
        for wp in wallpapers {
            // Bildschirm nicht angeschlossen -> stillschweigend überspringen.
            guard let screen = Screens.screen(forID: wp.screenID) else { continue }

            let url = URL(fileURLWithPath: (wp.path as NSString).expandingTildeInPath)
            guard FileManager.default.fileExists(atPath: url.path) else {
                errors.append("Wallpaper (\(wp.screenName)): Datei nicht gefunden")
                continue
            }
            do {
                try ws.setDesktopImageURL(url, for: screen, options: [:])
            } catch {
                errors.append("Wallpaper (\(wp.screenName)): \(error.localizedDescription)")
            }
        }
        return errors
    }

    // MARK: - AppleScript-Helfer

    /// Führt ein AppleScript aus. Gibt nil bei Erfolg, sonst eine Fehlermeldung.
    private static func runAppleScript(_ source: String) -> String? {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            return "Script konnte nicht erstellt werden."
        }
        script.executeAndReturnError(&errorInfo)
        if let errorInfo, let msg = errorInfo[NSAppleScript.errorMessage] as? String {
            return msg
        }
        return nil
    }
}
