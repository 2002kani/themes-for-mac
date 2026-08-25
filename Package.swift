// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ThemeSwitcher",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "ThemeSwitcher",
            path: "Sources/ThemeSwitcher"
        )
    ],
    swiftLanguageModes: [.v5]
)
