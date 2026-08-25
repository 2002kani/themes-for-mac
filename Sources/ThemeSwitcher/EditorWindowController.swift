import AppKit
import SwiftUI

/// Hostet die SwiftUI-Editoransicht in einem normalen Fenster.
final class EditorWindowController: NSWindowController {
    convenience init() {
        let hosting = NSHostingController(rootView: EditorView())
        let window = NSWindow(contentViewController: hosting)
        window.title = "Themes bearbeiten"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 720, height: 460))
        window.center()
        self.init(window: window)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
    }
}
