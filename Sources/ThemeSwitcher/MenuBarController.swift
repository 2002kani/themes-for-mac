import AppKit

/// Verwaltet das Menu-Bar-Icon und das zugehörige Menü.
final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let store = ThemeStore.shared
    private var editorWindowController: EditorWindowController?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "paintpalette",
                                accessibilityDescription: "Themes")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        // Menü bei Store-Änderungen aktuell halten.
        store.onChange = { [weak self] in
            self?.rebuildMenu()
        }
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }

    // MARK: - Menüaufbau

    private func rebuildMenu() {
        guard let menu = statusItem.menu else { return }
        menu.removeAllItems()

        if store.themes.isEmpty {
            let empty = NSMenuItem(title: "Keine Themes", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for theme in store.themes {
                let item = NSMenuItem(title: theme.name,
                                      action: #selector(selectTheme(_:)),
                                      keyEquivalent: "")
                item.target = self
                item.representedObject = theme.id
                item.state = (theme.id == store.activeThemeID) ? .on : .off
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        let editItem = NSMenuItem(title: "Themes bearbeiten…",
                                  action: #selector(openEditor),
                                  keyEquivalent: ",")
        editItem.target = self
        menu.addItem(editItem)

        let quitItem = NSMenuItem(title: "Beenden",
                                  action: #selector(quit),
                                  keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Aktionen

    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID,
              let theme = store.theme(id: id) else { return }

        let errors = SystemController.apply(theme)
        store.setActive(id: id)

        if !errors.isEmpty {
            showErrors(errors)
        }
    }

    @objc private func openEditor() {
        if editorWindowController == nil {
            editorWindowController = EditorWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        editorWindowController?.showWindow(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Fehleranzeige

    private func showErrors(_ errors: [String]) {
        let alert = NSAlert()
        alert.messageText = "Theme teilweise nicht angewendet"
        alert.informativeText = errors.joined(separator: "\n")
            + "\n\nHinweis: Erscheinungsbild und Menüleiste benötigen die Berechtigung "
            + "„Automation → System Events“ (Systemeinstellungen › Datenschutz & Sicherheit)."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
