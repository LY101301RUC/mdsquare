import Testing
@testable import MarkdownDev

@Suite("EditorCommandHandler")
struct EditorCommandHandlerTests {
  @Test("applies heading level to current line")
  func appliesHeadingLevel() {
    let result = EditorCommandHandler.apply(.heading(.h2), to: "Title", selection: 0..<0)
    #expect(result.text == "## Title")
    #expect(result.selection == 3..<8)
  }

  @Test("replaces existing heading marker")
  func replacesHeadingMarker() {
    let result = EditorCommandHandler.apply(.heading(.h3), to: "# Title", selection: 0..<0)
    #expect(result.text == "### Title")
    #expect(result.selection == 4..<9)
  }

  @Test("applies heading to line containing selection")
  func appliesHeadingToLineContainingSelection() {
    let result = EditorCommandHandler.apply(.heading(.h3), to: "Intro\nTitle\nBody", selection: 8..<8)
    #expect(result.text == "Intro\n### Title\nBody")
    #expect(result.selection == 10..<15)
  }

  @Test("heading command reports current line replacement range")
  func headingReportsCurrentLineReplacementRange() {
    let result = EditorCommandHandler.apply(.heading(.h3), to: "Intro\nTitle\nBody", selection: 8..<8)
    #expect(result.text == "Intro\n### Title\nBody")
    #expect(result.replacementRange == 6..<11)
    #expect(result.replacementText == "### Title")
    #expect(result.selection == 10..<15)
  }

  @Test("preserves valid heading indentation")
  func preservesValidHeadingIndentation() {
    let result = EditorCommandHandler.apply(.heading(.h2), to: "   # Title", selection: 0..<0)
    #expect(result.text == "   ## Title")
    #expect(result.selection == 6..<11)
  }

  @Test("does not replace marker inside indented code block")
  func doesNotReplaceMarkerInsideIndentedCodeBlock() {
    let result = EditorCommandHandler.apply(.heading(.h2), to: "    # Code", selection: 0..<0)
    #expect(result.text == "##     # Code")
    #expect(result.selection == 3..<13)
  }

  @Test("wraps selection in bold")
  func wrapsBold() {
    let result = EditorCommandHandler.apply(.bold, to: "hello world", selection: 6..<11)
    #expect(result.text == "hello **world**")
    #expect(result.selection == 8..<13)
  }

  @Test("bold command reports minimal replacement range")
  func boldReportsMinimalReplacementRange() {
    let result = EditorCommandHandler.apply(.bold, to: "hello world", selection: 6..<11)
    #expect(result.text == "hello **world**")
    #expect(result.replacementRange == 6..<11)
    #expect(result.replacementText == "**world**")
    #expect(result.selection == 8..<13)
  }

  @Test("bold command unwraps already bold selected text")
  func boldUnwrapsAlreadyBoldSelection() {
    let result = EditorCommandHandler.apply(.bold, to: "**word**", selection: 2..<6)
    #expect(result.text == "word")
    #expect(result.replacementRange == 0..<8)
    #expect(result.replacementText == "word")
    #expect(result.selection == 0..<4)
  }

  @Test("inserts bold empty selection text")
  func insertsBoldEmptySelectionText() {
    let result = EditorCommandHandler.apply(.bold, to: "hello ", selection: 6..<6)
    #expect(result.text == "hello **bold**")
    #expect(result.selection == 8..<12)
  }

  @Test("clamps selection beyond document end")
  func clampsSelectionBeyondDocumentEnd() {
    let result = EditorCommandHandler.apply(.bold, to: "hello", selection: 99..<100)
    #expect(result.text == "hello**bold**")
    #expect(result.selection == 7..<11)
  }

  @Test("uses UTF-16 offsets when wrapping selection")
  func usesUTF16OffsetsWhenWrappingSelection() {
    let result = EditorCommandHandler.apply(.bold, to: "🙂Title", selection: 2..<7)
    #expect(result.text == "🙂**Title**")
    #expect(result.selection == 4..<9)
  }

  @Test("expands bold selection from middle of surrogate pair")
  func expandsBoldSelectionFromMiddleOfSurrogatePair() {
    let result = EditorCommandHandler.apply(.bold, to: "🙂Title", selection: 1..<2)
    #expect(result.text == "**🙂**Title")
    #expect(result.selection == 2..<4)
    #expect(isCharacterBoundary(result.selection.lowerBound, in: result.text))
    #expect(isCharacterBoundary(result.selection.upperBound, in: result.text))
  }

  @Test("inserts italic empty selection text")
  func insertsItalicEmptySelectionText() {
    let result = EditorCommandHandler.apply(.italic, to: "", selection: 0..<0)
    #expect(result.text == "*italic*")
    #expect(result.selection == 1..<7)
  }

  @Test("wraps selection in red color span")
  func wrapsSelectionInRedColorSpan() {
    let result = EditorCommandHandler.apply(.textColor(.red), to: "hello world", selection: 6..<11)
    let prefix = #"<span style="color: red">"#

    #expect(result.text == #"hello <span style="color: red">world</span>"#)
    #expect(result.replacementRange == 6..<11)
    #expect(result.replacementText == #"<span style="color: red">world</span>"#)
    #expect(result.selection == (6 + prefix.utf16.count)..<(6 + prefix.utf16.count + 5))
  }

  @Test("changes an existing color span to blue")
  func changesExistingColorSpanToBlue() {
    let text = #"<span style="color: red">word</span>"#
    let result = EditorCommandHandler.apply(.textColor(.blue), to: text, selection: 25..<29)
    let prefix = #"<span style="color: blue">"#

    #expect(result.text == #"<span style="color: blue">word</span>"#)
    #expect(result.replacementRange == 0..<text.utf16.count)
    #expect(result.selection == prefix.utf16.count..<(prefix.utf16.count + 4))
  }

  @Test("wraps selection in italic")
  func wrapsItalic() {
    let result = EditorCommandHandler.apply(.italic, to: "hello world", selection: 6..<11)
    #expect(result.text == "hello *world*")
    #expect(result.selection == 7..<12)
  }

  @Test("italic command unwraps already italic selected text")
  func italicUnwrapsAlreadyItalicSelection() {
    let result = EditorCommandHandler.apply(.italic, to: "*word*", selection: 1..<5)
    #expect(result.text == "word")
    #expect(result.replacementRange == 0..<6)
    #expect(result.replacementText == "word")
    #expect(result.selection == 0..<4)
  }

  @Test("wraps selection in link and selects URL")
  func wrapsLinkAndSelectsURL() {
    let result = EditorCommandHandler.apply(.link, to: "Read docs", selection: 5..<9)
    #expect(result.text == "Read [docs](url)")
    #expect(result.selection == 12..<15)
  }

  @Test("inserts empty link and selects URL")
  func insertsEmptyLinkAndSelectsURL() {
    let result = EditorCommandHandler.apply(.link, to: "", selection: 0..<0)
    #expect(result.text == "[text](url)")
    #expect(result.selection == 7..<10)
  }

  @Test("expands link selection from middle of surrogate pair")
  func expandsLinkSelectionFromMiddleOfSurrogatePair() {
    let result = EditorCommandHandler.apply(.link, to: "🙂Title", selection: 1..<2)
    #expect(result.text == "[🙂](url)Title")
    #expect(result.selection == 5..<8)
    #expect(isCharacterBoundary(result.selection.lowerBound, in: result.text))
    #expect(isCharacterBoundary(result.selection.upperBound, in: result.text))
  }

  @Test("prefixes selected lines as unordered list")
  func prefixesUnorderedList() {
    let result = EditorCommandHandler.apply(.unorderedList, to: "one\ntwo", selection: 0..<7)
    #expect(result.text == "- one\n- two")
  }

  @Test("prefixes complete selected line range")
  func prefixesCompleteSelectedLineRange() {
    let result = EditorCommandHandler.apply(.quote, to: "zero\none\ntwo\nthree", selection: 7..<11)
    #expect(result.text == "zero\n> one\n> two\nthree")
    #expect(result.selection == 5..<16)
  }

  @Test("prefixes current line as quote from empty selection")
  func prefixesCurrentLineAsQuoteFromEmptySelection() {
    let result = EditorCommandHandler.apply(.quote, to: "alpha\nbeta", selection: 2..<2)
    #expect(result.text == "> alpha\nbeta")
    #expect(result.selection == 0..<7)
  }

  @Test("quote command reports selected line replacement range")
  func quoteReportsSelectedLineReplacementRange() {
    let result = EditorCommandHandler.apply(.quote, to: "alpha\nbeta", selection: 2..<2)
    #expect(result.text == "> alpha\nbeta")
    #expect(result.replacementRange == 0..<5)
    #expect(result.replacementText == "> alpha")
    #expect(result.selection == 0..<7)
  }

  @Test("quote command removes quote prefix from quoted current line")
  func quoteRemovesExistingQuotePrefix() {
    let result = EditorCommandHandler.apply(.quote, to: "> alpha\nbeta", selection: 3..<3)
    #expect(result.text == "alpha\nbeta")
    #expect(result.replacementRange == 0..<7)
    #expect(result.replacementText == "alpha")
    #expect(result.selection == 0..<5)
  }

  @Test("numbers selected lines from one")
  func numbersSelectedLinesFromOne() {
    let result = EditorCommandHandler.apply(.orderedList, to: "one\ntwo\nthree", selection: 0..<13)
    #expect(result.text == "1. one\n2. two\n3. three")
  }

  @Test("prefixes current empty line at document end")
  func prefixesCurrentEmptyLineAtDocumentEnd() {
    let result = EditorCommandHandler.apply(.unorderedList, to: "one\n", selection: 4..<4)
    #expect(result.text == "one\n- ")
    #expect(result.selection == 6..<6)
  }

  @Test("wraps code block")
  func wrapsCodeBlock() {
    let result = EditorCommandHandler.apply(.codeBlock, to: "let x = 1", selection: 0..<9)
    #expect(result.text == "```\nlet x = 1\n```")
  }

  @Test("wraps multiline code block")
  func wrapsMultilineCodeBlock() {
    let result = EditorCommandHandler.apply(.codeBlock, to: "one\ntwo", selection: 0..<7)
    #expect(result.text == "```\none\ntwo\n```")
    #expect(result.selection == 4..<11)
  }

  @Test("code block command reports selected text replacement range")
  func codeBlockReportsSelectedTextReplacementRange() {
    let result = EditorCommandHandler.apply(.codeBlock, to: "one\ntwo", selection: 0..<7)
    #expect(result.text == "```\none\ntwo\n```")
    #expect(result.replacementRange == 0..<7)
    #expect(result.replacementText == "```\none\ntwo\n```")
    #expect(result.selection == 4..<11)
  }

  @Test("inserts editable empty code block")
  func insertsEditableEmptyCodeBlock() {
    let result = EditorCommandHandler.apply(.codeBlock, to: "", selection: 0..<0)
    #expect(result.text == "```\n\n```")
    #expect(result.selection == 4..<4)
  }

  @Test("replaces heading marker followed by tab")
  func replacesHeadingMarkerFollowedByTab() {
    let result = EditorCommandHandler.apply(.heading(.h2), to: "#\tTitle", selection: 0..<0)
    #expect(result.text == "## Title")
    #expect(result.selection == 3..<8)
  }

  private func isCharacterBoundary(_ offset: Int, in text: String) -> Bool {
    text.indices.contains { $0.utf16Offset(in: text) == offset }
      || offset == text.endIndex.utf16Offset(in: text)
  }
}
