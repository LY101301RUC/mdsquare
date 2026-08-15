import Foundation
import Testing
@testable import MarkdownDev

@Suite("PreviewImageResolver")
struct PreviewImageResolverTests {
  @Test("resolves small local png image as data url")
  func resolvesSmallLocalPNGImageAsDataURL() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let imageURL = directory.appendingPathComponent("image.png")
    try Data([0x89, 0x50, 0x4E, 0x47]).write(to: imageURL)

    let resolver = PreviewImageResolver(baseDirectory: directory)
    let images = resolver.resolve(in: "![Alt](image.png)")

    #expect(images["image.png"]?.hasPrefix("data:image/png;base64,") == true)
  }

  @Test("does not resolve remote images")
  func doesNotResolveRemoteImages() {
    let resolver = PreviewImageResolver(baseDirectory: URL(fileURLWithPath: "/tmp"))

    #expect(resolver.resolve(in: "![Alt](https://example.com/image.png)").isEmpty)
  }

  @Test("does not resolve files outside base directory")
  func doesNotResolveFilesOutsideBaseDirectory() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let resolver = PreviewImageResolver(baseDirectory: directory)

    #expect(resolver.resolve(in: "![Alt](../secret.png)").isEmpty)
  }
}
