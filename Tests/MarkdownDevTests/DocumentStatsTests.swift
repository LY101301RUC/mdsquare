import Testing
@testable import MarkdownDev

@Suite("DocumentStats")
struct DocumentStatsTests {
  @Test("counts lines words characters and headings")
  func countsLinesWordsCharactersAndHeadings() {
    let snapshot = MarkdownSnapshot(text: "# Title\nHello world")
    let stats = DocumentStats(text: snapshot.text, headings: snapshot.headings)

    #expect(stats.lineCount == 2)
    #expect(stats.wordCount == 3)
    #expect(stats.characterCount == 19)
    #expect(stats.headingCount == 1)
  }

  @Test("counts empty text as zero lines")
  func countsEmptyTextAsZeroLines() {
    let stats = DocumentStats(text: "", headings: [])

    #expect(stats.lineCount == 0)
    #expect(stats.wordCount == 0)
    #expect(stats.characterCount == 0)
    #expect(stats.headingCount == 0)
  }
}
