// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "Patron",
  platforms: [
    .iOS(.v13), .macOS(.v10_15)
  ],
  products: [
    .library(
      name: "Patron",
      targets: ["Patron"]),
    ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "Patron",
      dependencies: []),
    .testTarget(
      name: "PatronTests",
      dependencies: ["Patron"]),
  ]
)
