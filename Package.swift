// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GadgetBuddyStudioAI",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "GadgetBuddyCore", targets: ["GadgetBuddyCore"])
    ],
    targets: [
        .target(name: "GadgetBuddyCore"),
        .testTarget(name: "GadgetBuddyCoreTests", dependencies: ["GadgetBuddyCore"])
    ]
)
