import Foundation
import Testing
@testable import MarkdownDev

@Suite("HeadingExtractor")
struct HeadingExtractorTests {
  @Test("extracts levels titles and slugs from fixture")
  func extractsLevelsTitlesAndSlugsFromFixture() throws {
    let headings = try HeadingExtractor.extract(from: fixture("headings"))

    #expect(headings.map(\.level) == [.h1, .h2, .h3, .h4, .h6])
    #expect(headings.map(\.title) == ["Product", "Goals", "Speed", "Native Feel", "Small Detail"])
    #expect(headings.map(\.slug) == ["product", "goals", "speed", "native-feel", "small-detail"])
    #expect(headings.map(\.lineNumber) == [1, 5, 7, 9, 11])
  }

  @Test("deduplicates slugs")
  func deduplicatesSlugs() throws {
    let headings = try HeadingExtractor.extract(from: fixture("duplicate-headings"))

    #expect(headings.map(\.slug) == ["intro", "intro-1", "intro-2"])
  }

  @Test("ignores headings inside fenced code blocks")
  func ignoresHeadingsInsideFencedCodeBlocks() throws {
    let headings = try HeadingExtractor.extract(from: fixture("fenced-heading"))

    #expect(headings.map(\.level) == [.h1, .h2])
    #expect(headings.map(\.title) == ["Real", "Next"])
    #expect(headings.map(\.slug) == ["real", "next"])
    #expect(headings.map(\.lineNumber) == [1, 8])
  }

  @Test("extracts setext h1 and h2 headings")
  func extractsSetextHeadings() throws {
    let text = try fixture("setext-headings")
    let headings = HeadingExtractor.extract(from: text)

    #expect(headings.map(\.level) == [.h1, .h2])
    #expect(headings.map(\.title) == ["Title One", "Title Two"])
    #expect(headings.map(\.slug) == ["title-one", "title-two"])
    #expect(headings.map(\.lineNumber) == [1, 6])
    guard headings.count == 2 else { return }
    #expect(String(text[headings[0].sourceRange]) == "Title One")
    #expect(String(text[headings[1].sourceRange]) == "Title Two")
  }

  @Test("requires closing fence length to match opening fence")
  func requiresClosingFenceLengthToMatchOpeningFence() {
    let text = """
    ````
    # Hidden
    ```
    ## Still Hidden
    ````
    # Visible
    """
    let headings = HeadingExtractor.extract(from: text)

    #expect(headings.map(\.title) == ["Visible"])
  }

  @Test("does not treat four-space indented fence as fenced code block")
  func doesNotTreatFourSpaceIndentedFenceAsFencedCodeBlock() {
    let text = """
        ```
    # Visible
    """

    let headings = HeadingExtractor.extract(from: text)

    #expect(headings.map(\.title) == ["Visible"])
  }

  @Test("ignores empty atx heading markers")
  func ignoresEmptyATXHeadingMarkers() {
    let headings = HeadingExtractor.extract(from: "#\n\n## Title")

    #expect(headings.map(\.title) == ["Title"])
  }

  @Test("records source ranges excluding newlines")
  func recordsSourceRangesExcludingNewlines() {
    let text = "# One\n\n## Two\nBody"
    let headings = HeadingExtractor.extract(from: text)

    #expect(headings.count == 2)
    #expect(String(text[headings[0].sourceRange]) == "# One")
    #expect(String(text[headings[1].sourceRange]) == "## Two")
    #expect(headings[0].lineNumber == 1)
    #expect(headings[1].lineNumber == 3)
  }

  @Test("extracts headings indented up to three spaces")
  func extractsHeadingsIndentedUpToThreeSpaces() throws {
    let text = " # One\n  ## Two\n   ### Indented\n    #### Code\n"
    let headings = HeadingExtractor.extract(from: text)

    #expect(headings.map(\.level) == [.h1, .h2, .h3])
    #expect(headings.map(\.title) == ["One", "Two", "Indented"])
    #expect(headings.map(\.lineNumber) == [1, 2, 3])
    let indentedHeading = try #require(headings.last)
    #expect(String(text[indentedHeading.sourceRange]) == "   ### Indented")
  }

  @Test("creates markdown snapshot with extracted headings")
  func createsMarkdownSnapshotWithExtractedHeadings() {
    let snapshot = MarkdownSnapshot(text: "# One\n")

    #expect(snapshot.text == "# One\n")
    #expect(snapshot.headings.map(\.title) == ["One"])
  }

  private func fixture(_ name: String) throws -> String {
    let url = Bundle.module.url(forResource: name, withExtension: "md", subdirectory: "Fixtures")
    let unwrappedURL = try #require(url)
    return try String(contentsOf: unwrappedURL, encoding: .utf8)
  }
}
