// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AlarmCore",
    platforms: [.macOS(.v14), .iOS("26.0")],
    products: [.library(name: "AlarmCore", targets: ["AlarmCore"])],
    targets: [
        .target(name: "AlarmCore"),
        .testTarget(name: "AlarmCoreTests", dependencies: ["AlarmCore"]),
    ],
    swiftLanguageModes: [.v5]
)
