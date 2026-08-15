// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "MdSquare",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "MdSquare", targets: ["MarkdownDev"])
  ],
  targets: [
    .executableTarget(
      name: "MarkdownDev",
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "MarkdownDevTests",
      dependencies: ["MarkdownDev"],
      resources: [.copy("Fixtures")]
    )
  ]
)
