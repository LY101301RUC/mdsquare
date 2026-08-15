import Testing
@testable import MarkdownDev

@Suite("DocumentPaneSplitMetrics")
struct DocumentPaneSplitViewTests {
  @Test("calculates three column widths")
  func calculatesThreeColumnWidths() {
    let metrics = DocumentPaneSplitMetrics.calculate(
      totalWidth: 1_000,
      totalHeight: 640,
      mode: .threeColumn,
      outlineWidth: 200,
      storedEditorFraction: 0.5
    )

    #expect(metrics.outlineWidth == 200)
    #expect(metrics.editorWidth == 393)
    #expect(metrics.previewWidth == 393)
    #expect(!metrics.outlineSplitterVisible)
    #expect(metrics.editorPreviewSplitterVisible)
    #expect(metrics.contentPanesWidth == 786)
    #expect(metrics.paneHeight == 640)
  }

  @Test("splitter hit target is easy to discover")
  func splitterHitTargetIsEasyToDiscover() {
    #expect(DocumentPaneLayout.splitterHitWidth >= 14)
  }

  @Test("clamps configured outline width")
  func clampsConfiguredOutlineWidth() {
    let narrow = DocumentPaneSplitMetrics.calculate(
      totalWidth: 1_000,
      mode: .writing,
      outlineWidth: 20,
      storedEditorFraction: 0.5
    )
    let wide = DocumentPaneSplitMetrics.calculate(
      totalWidth: 1_000,
      mode: .writing,
      outlineWidth: 900,
      storedEditorFraction: 0.5
    )

    #expect(narrow.outlineWidth == DocumentPaneLayout.outlineMinWidth)
    #expect(wide.outlineWidth == DocumentPaneLayout.outlineMaxWidth)
  }

  @Test("clamps editor preview split to keep both panes usable")
  func clampsEditorPreviewSplitToKeepBothPanesUsable() {
    let metrics = DocumentPaneSplitMetrics.calculate(
      totalWidth: 1_000,
      mode: .threeColumn,
      outlineWidth: 200,
      storedEditorFraction: 0.9
    )

    #expect(metrics.editorWidth == 466)
    #expect(metrics.previewWidth == DocumentPaneLayout.contentPaneMinWidth)
  }

  @Test("calculates writing reading and focus widths")
  func calculatesWritingReadingAndFocusWidths() {
    let writing = DocumentPaneSplitMetrics.calculate(
      totalWidth: 1_000,
      mode: .writing,
      outlineWidth: 200,
      storedEditorFraction: 0.5
    )
    let reading = DocumentPaneSplitMetrics.calculate(
      totalWidth: 1_000,
      mode: .reading,
      outlineWidth: 200,
      storedEditorFraction: 0.5
    )
    let focus = DocumentPaneSplitMetrics.calculate(
      totalWidth: 1_000,
      mode: .focus,
      outlineWidth: 200,
      storedEditorFraction: 0.5
    )

    #expect(writing.outlineWidth == 200)
    #expect(writing.editorWidth == 800)
    #expect(writing.previewWidth == nil)

    #expect(reading.outlineWidth == 200)
    #expect(reading.editorWidth == nil)
    #expect(reading.previewWidth == 800)

    #expect(focus.outlineWidth == nil)
    #expect(focus.editorWidth == 1_000)
    #expect(focus.previewWidth == nil)
  }

  @Test("converts dragged editor width back to stored fraction")
  func convertsDraggedEditorWidthBackToStoredFraction() {
    let fraction = DocumentPaneSplitMetrics.fraction(forEditorWidth: 500, contentPanesWidth: 1_000)
    let clampedLow = DocumentPaneSplitMetrics.fraction(forEditorWidth: 50, contentPanesWidth: 1_000)

    #expect(fraction == 0.5)
    #expect(abs(clampedLow - (DocumentPaneLayout.contentPaneMinWidth / 1_000)) < 0.0001)
  }
}
