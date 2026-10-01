// swift-tools-version: 6.1
// iBrain — local Ollama chat with optional cloud providers for iSuite.
import PackageDescription

let package = Package(
    name: "IBrain",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "IBrain",
            path: "Sources/IBrain"
        )
    ],
    swiftLanguageModes: [.v5]
)
