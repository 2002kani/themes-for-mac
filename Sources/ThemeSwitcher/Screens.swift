import AppKit
import CoreGraphics

/// Ein aktuell angeschlossener Bildschirm mit stabiler UUID.
struct ScreenInfo: Identifiable {
    let id: String        // Display-UUID
    let name: String      // localizedName
    let screen: NSScreen
}

enum Screens {
    /// Stabile Display-UUID eines Bildschirms (überlebt Reboot/Neuanordnung).
    static func uuid(for screen: NSScreen) -> String? {
        guard let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                as? CGDirectDisplayID,
              let cf = CGDisplayCreateUUIDFromDisplayID(num)?.takeRetainedValue() else {
            return nil
        }
        return CFUUIDCreateString(nil, cf) as String
    }

    /// Alle aktuell angeschlossenen Bildschirme.
    static func current() -> [ScreenInfo] {
        NSScreen.screens.compactMap { screen in
            guard let id = uuid(for: screen) else { return nil }
            return ScreenInfo(id: id, name: screen.localizedName, screen: screen)
        }
    }

    /// Findet den angeschlossenen Bildschirm zu einer gespeicherten UUID.
    static func screen(forID id: String) -> NSScreen? {
        NSScreen.screens.first { uuid(for: $0) == id }
    }
}
