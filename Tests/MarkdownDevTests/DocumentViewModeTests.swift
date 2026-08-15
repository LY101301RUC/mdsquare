import Testing
@testable import MarkdownDev

@Suite("DocumentViewMode")
struct DocumentViewModeTests {
  @Test("describes visible panes")
  func describesVisiblePanes() {
    #expect(DocumentViewMode.threeColumn.showsOutline)
    #expect(DocumentViewMode.threeColumn.showsEditor)
    #expect(DocumentViewMode.threeColumn.showsPreview)

    #expect(DocumentViewMode.writing.showsOutline)
    #expect(DocumentViewMode.writing.showsEditor)
    #expect(!DocumentViewMode.writing.showsPreview)

    #expect(DocumentViewMode.reading.showsOutline)
    #expect(!DocumentViewMode.reading.showsEditor)
    #expect(DocumentViewMode.reading.showsPreview)

    #expect(!DocumentViewMode.focus.showsOutline)
    #expect(DocumentViewMode.focus.showsEditor)
    #expect(!DocumentViewMode.focus.showsPreview)
  }

  @Test("resolves invalid stored value to three column")
  func resolvesInvalidStoredValueToThreeColumn() {
    #expect(DocumentViewMode.resolved(from: "old-layout") == .threeColumn)
    #expect(DocumentViewMode.resolved(from: DocumentViewMode.reading.rawValue) == .reading)
  }
}
