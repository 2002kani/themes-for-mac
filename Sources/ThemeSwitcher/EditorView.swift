import SwiftUI
import AppKit

/// ViewModel: Brücke zwischen SwiftUI-Editor und ThemeStore.
final class EditorViewModel: ObservableObject {
    @Published var themes: [Theme] = []
    @Published var selectedID: UUID?

    private let store = ThemeStore.shared

    init() {
        reload()
    }

    func reload() {
        themes = store.themes
        if selectedID == nil || !themes.contains(where: { $0.id == selectedID }) {
            selectedID = themes.first?.id
        }
    }

    var selectedIndex: Int? {
        guard let selectedID else { return nil }
        return themes.firstIndex { $0.id == selectedID }
    }

    func addTheme() {
        let theme = Theme.newEmpty()
        store.add(theme)
        reload()
        selectedID = theme.id
    }

    func deleteSelected() {
        guard let id = selectedID else { return }
        store.delete(id: id)
        reload()
    }

    /// Speichert das aktuell bearbeitete Theme in den Store.
    func save(_ theme: Theme) {
        store.update(theme)
        reload()
    }

    func applyNow(_ theme: Theme) {
        store.update(theme)
        let errors = SystemController.apply(theme)
        store.setActive(id: theme.id)
        reload()
        if !errors.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Theme teilweise nicht angewendet"
            alert.informativeText = errors.joined(separator: "\n")
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}

struct EditorView: View {
    @StateObject private var vm = EditorViewModel()

    var body: some View {
        NavigationSplitViewCompat(
            sidebar: { sidebar },
            detail: { detail }
        )
        .frame(minWidth: 620, minHeight: 400)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $vm.selectedID) {
                ForEach(vm.themes) { theme in
                    Text(theme.name.isEmpty ? "(ohne Namen)" : theme.name)
                        .tag(theme.id)
                }
            }
            Divider()
            HStack {
                Button(action: vm.addTheme) {
                    Image(systemName: "plus")
                }
                Button(action: vm.deleteSelected) {
                    Image(systemName: "minus")
                }
                .disabled(vm.selectedID == nil)
                Spacer()
            }
            .buttonStyle(.borderless)
            .padding(8)
        }
        .frame(minWidth: 180)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let index = vm.selectedIndex {
            ThemeDetailView(
                theme: Binding(
                    get: { vm.themes[index] },
                    set: { vm.themes[index] = $0 }
                ),
                onSave: { vm.save($0) },
                onApply: { vm.applyNow($0) }
            )
            // Neu aufbauen, wenn ein anderes Theme gewählt wird.
            .id(vm.selectedID)
        } else {
            Text("Kein Theme ausgewählt")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Detailformular für ein einzelnes Theme.
struct ThemeDetailView: View {
    @Binding var theme: Theme
    var onSave: (Theme) -> Void
    var onApply: (Theme) -> Void

    var body: some View {
        Form {
            Section("Allgemein") {
                TextField("Name", text: $theme.name)
            }

            Section("Erscheinungsbild") {
                Picker("Modus", selection: $theme.appearance) {
                    ForEach(Appearance.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Hintergrund (pro Bildschirm)") {
                let screens = Screens.current()
                ForEach(screens) { info in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(info.name)
                            Text(wallpaperFilename(for: info.id) ?? "Kein Bild")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        if wallpaperPath(for: info.id) != nil {
                            Button("Entfernen") { removeWallpaper(info.id) }
                        }
                        Button("Wählen…") { chooseWallpaper(for: info) }
                    }
                }
                if screens.count > 1 {
                    Button("Ein Bild für alle Bildschirme…") { chooseForAll(screens) }
                }
                // Gespeicherte Bilder für gerade nicht angeschlossene Bildschirme.
                ForEach(theme.wallpapers.filter { wp in !screens.contains { $0.id == wp.screenID } }) { wp in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(wp.screenName) (nicht angeschlossen)")
                                .foregroundStyle(.secondary)
                            Text((wp.path as NSString).lastPathComponent)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button("Entfernen") { removeWallpaper(wp.screenID) }
                    }
                }
            }

            Section("Menüleiste") {
                Picker("Verhalten", selection: $theme.menuBar) {
                    ForEach(MenuBarMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Symbol- & Widget-Stil") {
                Picker("Stil", selection: $theme.iconStyle) {
                    ForEach(IconStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.menu)
                Text("Hell/Dunkel-Variante folgt dem Erscheinungsbild. Ändern startet das Dock kurz neu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Button("Sichern") { onSave(theme) }
                    Spacer()
                    Button("Jetzt anwenden") { onApply(theme) }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Wallpaper-Helfer (pro Bildschirm)

    private func wallpaperPath(for screenID: String) -> String? {
        theme.wallpapers.first { $0.screenID == screenID }?.path
    }

    private func wallpaperFilename(for screenID: String) -> String? {
        wallpaperPath(for: screenID).map { ($0 as NSString).lastPathComponent }
    }

    private func setWallpaper(_ path: String, for info: ScreenInfo) {
        if let idx = theme.wallpapers.firstIndex(where: { $0.screenID == info.id }) {
            theme.wallpapers[idx].path = path
            theme.wallpapers[idx].screenName = info.name
        } else {
            theme.wallpapers.append(
                ScreenWallpaper(screenID: info.id, screenName: info.name, path: path))
        }
    }

    private func removeWallpaper(_ screenID: String) {
        theme.wallpapers.removeAll { $0.screenID == screenID }
    }

    private func chooseWallpaper(for info: ScreenInfo) {
        if let url = openImagePanel() { setWallpaper(url.path, for: info) }
    }

    private func chooseForAll(_ screens: [ScreenInfo]) {
        if let url = openImagePanel() {
            for info in screens { setWallpaper(url.path, for: info) }
        }
    }

    private func openImagePanel() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.url : nil
    }
}

/// Kleiner Kompatibilitäts-Wrapper: NavigationSplitView gibt es ab macOS 13.
struct NavigationSplitViewCompat<Sidebar: View, Detail: View>: View {
    @ViewBuilder var sidebar: () -> Sidebar
    @ViewBuilder var detail: () -> Detail

    var body: some View {
        NavigationSplitView(sidebar: sidebar, detail: detail)
    }
}
