import Testing
@testable import MarkdownDev

@Suite("EditorPerformancePolicy")
struct EditorPerformancePolicyTests {
  @Test("highlights small documents immediately")
  func highlightsSmallDocumentsImmediately() {
    #expect(EditorPerformancePolicy.highlightMode(forUTF16Length: 50_000) == .immediate)
  }

  @Test("debounces large documents")
  func debouncesLargeDocuments() {
    #expect(EditorPerformancePolicy.highlightMode(forUTF16Length: 200_000) == .debounced(milliseconds: 120))
  }
}
