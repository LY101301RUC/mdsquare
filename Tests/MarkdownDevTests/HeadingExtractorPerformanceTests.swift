import Foundation
import Testing
@testable import MarkdownDev

@Suite("HeadingExtractorPerformance")
struct HeadingExtractorPerformanceTests {
  @Test("extracts headings from generated performance fixtures")
  func extractsHeadingsFromGeneratedPerformanceFixtures() throws {
    for fixture in ["100kb.md", "1mb.md"] {
      let text = try String(contentsOf: fixtureURL(named: fixture), encoding: .utf8)
      let start = DispatchTime.now().uptimeNanoseconds
      let headings = HeadingExtractor.extract(from: text)
      let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000

      print("HeadingExtractor \(fixture): \(String(format: "%.2f", elapsed))ms, headings=\(headings.count)")
      #expect(!headings.isEmpty)
    }
  }

  private func fixtureURL(named name: String) throws -> URL {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let url = root.appendingPathComponent("tmp/perf-fixtures").appendingPathComponent(name)
    let exists = FileManager.default.fileExists(atPath: url.path)
    #expect(exists)
    return url
  }
}
