// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "SearchbaseSDK",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "SearchbaseSDK",
      targets: ["SearchbaseSDK"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "SearchbaseSDK",
      dependencies: [],
      path: "SearchbaseSDK/SearchbaseSDK"),  // Updated path
    .testTarget(
      name: "SearchbaseSDKTests",
      dependencies: ["SearchbaseSDK"]),
  ]
)
