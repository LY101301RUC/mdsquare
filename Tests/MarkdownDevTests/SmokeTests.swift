import Testing
@testable import MarkdownDev

@Test("package builds and creates empty document")
func packageBuildsAndCreatesEmptyDocument() {
  #expect(MarkdownDocument().text == "")
}
