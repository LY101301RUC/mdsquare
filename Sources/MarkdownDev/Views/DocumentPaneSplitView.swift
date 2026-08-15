import AppKit
import SwiftUI

struct DocumentPaneSplitMetrics: Equatable {
  let outlineWidth: CGFloat?
  let editorWidth: CGFloat?
  let previewWidth: CGFloat?
  let outlineSplitterVisible: Bool
  let editorPreviewSplitterVisible: Bool
  let contentPanesWidth: CGFloat
  let paneHeight: CGFloat

  static func calculate(
    totalWidth: CGFloat,
    totalHeight: CGFloat = 0,
    mode: DocumentViewMode,
    outlineWidth: CGFloat = DocumentPaneLayout.outlineIdealWidth,
    storedEditorFraction: CGFloat
  ) -> DocumentPaneSplitMetrics {
    let totalWidth = max(totalWidth, 0)
    let totalHeight = max(totalHeight, 0)
    let visibleOutlineWidth = mode.showsOutline ? clampedOutlineWidth(outlineWidth) : nil
    let contentAreaWidth = max(totalWidth - (visibleOutlineWidth ?? 0), 0)

    if mode.showsEditor && mode.showsPreview {
      let contentPanesWidth = max(contentAreaWidth - DocumentPaneLayout.splitterHitWidth, 0)
      let editorWidth = clampedEditorWidth(
        contentPanesWidth * clampedFraction(storedEditorFraction),
        contentPanesWidth: contentPanesWidth
      )

      return DocumentPaneSplitMetrics(
        outlineWidth: visibleOutlineWidth,
        editorWidth: editorWidth,
        previewWidth: max(contentPanesWidth - editorWidth, 0),
        outlineSplitterVisible: false,
        editorPreviewSplitterVisible: true,
        contentPanesWidth: contentPanesWidth,
        paneHeight: totalHeight
      )
    }

    return DocumentPaneSplitMetrics(
      outlineWidth: visibleOutlineWidth,
      editorWidth: mode.showsEditor ? contentAreaWidth : nil,
      previewWidth: mode.showsPreview ? contentAreaWidth : nil,
      outlineSplitterVisible: false,
      editorPreviewSplitterVisible: false,
      contentPanesWidth: contentAreaWidth,
      paneHeight: totalHeight
    )
  }

  static func clampedOutlineWidth(_ width: CGFloat) -> CGFloat {
    min(max(width, DocumentPaneLayout.outlineMinWidth), DocumentPaneLayout.outlineMaxWidth)
  }

  static func fraction(forEditorWidth editorWidth: CGFloat, contentPanesWidth: CGFloat) -> CGFloat {
    guard contentPanesWidth > 0 else {
      return DocumentPaneLayout.editorPreviewDefaultFraction
    }

    let width = clampedEditorWidth(editorWidth, contentPanesWidth: contentPanesWidth)
    return clampedFraction(width / contentPanesWidth)
  }

  private static func clampedFraction(_ fraction: CGFloat) -> CGFloat {
    guard fraction.isFinite else {
      return DocumentPaneLayout.editorPreviewDefaultFraction
    }

    return min(max(fraction, 0.1), 0.9)
  }

  private static func clampedEditorWidth(_ width: CGFloat, contentPanesWidth: CGFloat) -> CGFloat {
    guard contentPanesWidth > 0 else {
      return 0
    }

    let minimumWidth = min(DocumentPaneLayout.contentPaneMinWidth, contentPanesWidth / 2)
    let maximumWidth = max(minimumWidth, contentPanesWidth - minimumWidth)
    return min(max(width, minimumWidth), maximumWidth)
  }
}

struct DocumentPaneSplitView<OutlineContent: View, EditorContent: View, PreviewContent: View>: View {
  let mode: DocumentViewMode
  @Binding var editorFraction: Double

  private let outline: OutlineContent
  private let editor: EditorContent
  private let preview: PreviewContent

  @State private var editorDragStartWidth: CGFloat?
  @State private var editorDragStartContentWidth: CGFloat?
  @State private var liveEditorFraction: CGFloat?

  init(
    mode: DocumentViewMode,
    editorFraction: Binding<Double>,
    @ViewBuilder outline: () -> OutlineContent,
    @ViewBuilder editor: () -> EditorContent,
    @ViewBuilder preview: () -> PreviewContent
  ) {
    self.mode = mode
    _editorFraction = editorFraction
    self.outline = outline()
    self.editor = editor()
    self.preview = preview()
  }

  var body: some View {
    GeometryReader { proxy in
      let metrics = DocumentPaneSplitMetrics.calculate(
        totalWidth: proxy.size.width,
        totalHeight: proxy.size.height,
        mode: mode,
        storedEditorFraction: liveEditorFraction ?? CGFloat(editorFraction)
      )

      HStack(spacing: DocumentPaneLayout.paneSpacing) {
        if mode.showsOutline, let width = metrics.outlineWidth {
          outline
            .frame(width: width, height: metrics.paneHeight)
        }

        if mode.showsEditor, let width = metrics.editorWidth {
          editor
            .frame(width: width, height: metrics.paneHeight)
        }

        if metrics.editorPreviewSplitterVisible {
          DocumentPaneSplitter(
            onDragChanged: { translationX in
              updateEditorPreviewDrag(translationX: translationX, metrics: metrics)
            },
            onDragEnded: finishEditorPreviewDrag
          )
        }

        if mode.showsPreview, let width = metrics.previewWidth {
          preview
            .frame(width: width, height: metrics.paneHeight)
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
    }
  }

  private func updateEditorPreviewDrag(translationX: CGFloat, metrics: DocumentPaneSplitMetrics) {
    if editorDragStartWidth == nil {
      editorDragStartWidth = metrics.editorWidth
      editorDragStartContentWidth = metrics.contentPanesWidth
    }

    let contentWidth = editorDragStartContentWidth ?? metrics.contentPanesWidth
    let proposedWidth = (editorDragStartWidth ?? metrics.editorWidth ?? 0) + translationX
    liveEditorFraction = DocumentPaneSplitMetrics.fraction(
      forEditorWidth: proposedWidth,
      contentPanesWidth: contentWidth
    )
  }

  private func finishEditorPreviewDrag() {
    if let liveEditorFraction {
      editorFraction = Double(liveEditorFraction)
    }
    liveEditorFraction = nil
    editorDragStartWidth = nil
    editorDragStartContentWidth = nil
  }
}

private struct DocumentPaneSplitter: View {
  let onDragChanged: (CGFloat) -> Void
  let onDragEnded: () -> Void

  var body: some View {
    DocumentPaneSplitterRepresentable(
      onDragChanged: onDragChanged,
      onDragEnded: onDragEnded
    )
      .frame(width: DocumentPaneLayout.splitterHitWidth)
      .accessibilityHidden(true)
  }
}

private struct DocumentPaneSplitterRepresentable: NSViewRepresentable {
  let onDragChanged: (CGFloat) -> Void
  let onDragEnded: () -> Void

  func makeNSView(context: Context) -> DocumentPaneSplitterView {
    let view = DocumentPaneSplitterView()
    view.onDragChanged = onDragChanged
    view.onDragEnded = onDragEnded
    return view
  }

  func updateNSView(_ view: DocumentPaneSplitterView, context: Context) {
    view.onDragChanged = onDragChanged
    view.onDragEnded = onDragEnded
    view.needsDisplay = true
    view.window?.invalidateCursorRects(for: view)
  }
}

private final class DocumentPaneSplitterView: NSView {
  var onDragChanged: ((CGFloat) -> Void)?
  var onDragEnded: (() -> Void)?

  private var trackingArea: NSTrackingArea?
  private var isPointerInside = false
  private var isDragging = false
  private var dragStartX: CGFloat?

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  override var acceptsFirstResponder: Bool {
    true
  }

  private func setup() {
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()

    if let trackingArea {
      removeTrackingArea(trackingArea)
    }

    let area = NSTrackingArea(
      rect: .zero,
      options: [.activeInKeyWindow, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved],
      owner: self
    )
    addTrackingArea(area)
    trackingArea = area
  }

  override func resetCursorRects() {
    super.resetCursorRects()
    addCursorRect(bounds, cursor: .resizeLeftRight)
  }

  override func mouseEntered(with event: NSEvent) {
    isPointerInside = true
    needsDisplay = true
    NSCursor.resizeLeftRight.set()
  }

  override func mouseMoved(with event: NSEvent) {
    NSCursor.resizeLeftRight.set()
  }

  override func mouseExited(with event: NSEvent) {
    isPointerInside = false
    needsDisplay = true
  }

  override func mouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
    isDragging = true
    dragStartX = event.locationInWindow.x
    needsDisplay = true
    NSCursor.resizeLeftRight.set()
  }

  override func mouseDragged(with event: NSEvent) {
    guard let dragStartX else {
      return
    }

    onDragChanged?(event.locationInWindow.x - dragStartX)
    NSCursor.resizeLeftRight.set()
  }

  override func mouseUp(with event: NSEvent) {
    isDragging = false
    dragStartX = nil
    needsDisplay = true
    onDragEnded?()
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let lineWidth: CGFloat = isPointerInside || isDragging ? 2 : 1
    let x = bounds.midX - lineWidth / 2
    let lineRect = NSRect(x: x, y: 0, width: lineWidth, height: bounds.height)
    let color = isPointerInside || isDragging
      ? NSColor.controlAccentColor.withAlphaComponent(0.58)
      : NSColor.separatorColor.withAlphaComponent(0.62)

    color.setFill()
    lineRect.fill()
  }
}
