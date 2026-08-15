import Foundation
import Testing
@testable import MarkdownDev

@Suite("HeadingSyntaxHighlighter")
struct HeadingSyntaxHighlighterTests {
  @Test("returns heading line ranges with levels")
  func returnsHeadingLineRangesWithLevels() {
    let text = "# One\nbody\n## Two"

    let ranges = HeadingSyntaxHighlighter.headingLineRanges(in: text)

    #expect(ranges == [
      HighlightRange(level: .h1, range: NSRange(location: 0, length: 5)),
      HighlightRange(level: .h2, range: NSRange(location: 11, length: 6))
    ])
  }

  @Test("uses UTF-16 ranges for non-ASCII text")
  func usesUTF16RangesForNonASCIIText() {
    let text = "🙂 intro\n# 标题\nbody"

    let ranges = HeadingSyntaxHighlighter.headingLineRanges(in: text)

    #expect(ranges == [
      HighlightRange(level: .h1, range: NSRange(location: 9, length: 4))
    ])
  }

  @Test("ignores headings inside fenced code blocks")
  func ignoresHeadingsInsideFencedCodeBlocks() {
    let text = """
    # Real
    ```
    ## Hidden
    ```
    ### Next
    """

    let ranges = HeadingSyntaxHighlighter.headingLineRanges(in: text)

    #expect(ranges.map(\.level) == [.h1, .h3])
    #expect(ranges.map(\.range) == [
      NSRange(location: 0, length: 6),
      NSRange(location: 25, length: 8)
    ])
  }

  @Test("returns safe color span content ranges")
  func returnsSafeColorSpanContentRanges() {
    let prefix = #"<span style="color: red">"#
    let text = "x \(prefix)Red</span>"

    let ranges = MarkdownColorSpanScanner.colorRanges(in: text)

    #expect(ranges == [
      ColorHighlightRange(color: .red, range: NSRange(location: 2 + prefix.utf16.count, length: 3))
    ])
  }
}
