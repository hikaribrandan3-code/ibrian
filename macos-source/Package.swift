// swift-tools-version: 6.1
// iBrain — free, private, 100% local AI chat for the iSuite bundle.
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
