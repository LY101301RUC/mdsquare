import AppKit
import Testing
@testable import MarkdownDev

@Suite("MarkdownFindAction")
struct MarkdownFindActionTests {
  @Test("maps actions to NSTextFinder actions")
  func mapsActionsToNSTextFinderActions() {
    #expect(MarkdownFindAction.showFindInterface.textFinderAction == .showFindInterface)
    #expect(MarkdownFindAction.nextMatch.textFinderAction == .nextMatch)
    #expect(MarkdownFindAction.previousMatch.textFinderAction == .previousMatch)
    #expect(MarkdownFindAction.replace.textFinderAction == .replace)
  }
}
