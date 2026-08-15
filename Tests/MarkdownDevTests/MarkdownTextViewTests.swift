import AppKit
import Testing
@testable import MarkdownDev

@MainActor
@Suite("MarkdownTextView")
struct MarkdownTextViewTests {
  @Test("applies markdown commands as local text replacements")
  func appliesMarkdownCommandsAsLocalTextReplacements() {
    let textView = makeTextView()
    let spy = TextViewDelegateSpy()
    textView.delegate = spy
    textView.string = "hello world"
    textView.setSelectedRange(NSRange(location: 6, length: 5))

    textView.applyCommand(MarkdownEditorCommand.bold)

    #expect(textView.string == "hello **world**")
    #expect(spy.changeRanges == [NSRange(location: 6, length: 5)])
    #expect(spy.replacementStrings == ["**world**"])
  }

  @Test("toolbar command publishes latest text through onTextChange")
  func toolbarCommandPublishesLatestTextThroughOnTextChange() {
    let textView = makeTextView()
    textView.string = "hello world"
    textView.setSelectedRange(NSRange(location: 6, length: 5))
    var latestText = ""
    textView.onTextChange = { updatedText in
      latestText = updatedText
    }

    textView.applyCommand(.bold)

    #expect(latestText == "hello **world**")
  }

  @Test("toolbar command can be undone as one edit")
  func toolbarCommandCanBeUndoneAsOneEdit() throws {
    let textView = makeTextView()
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 240), styleMask: [.titled], backing: .buffered, defer: false)
    window.contentView?.addSubview(textView)
    window.makeFirstResponder(textView)
    textView.string = "hello world"
    textView.setSelectedRange(NSRange(location: 6, length: 5))

    textView.applyCommand(.bold)
    let undoManager = try #require(textView.undoManager)
    #expect(undoManager.canUndo)

    undoManager.undo()

    #expect(textView.string == "hello world")
  }

  @Test("calculates current line range from UTF-16 offsets")
  func calculatesCurrentLineRangeFromUTF16Offsets() {
    #expect(MarkdownTextView.lineRange(in: "one\ntwo\nthree", containingUTF16Offset: 1) == NSRange(location: 0, length: 3))
    #expect(MarkdownTextView.lineRange(in: "one\ntwo\nthree", containingUTF16Offset: 5) == NSRange(location: 4, length: 3))
    #expect(MarkdownTextView.lineRange(in: "one\n", containingUTF16Offset: 4) == NSRange(location: 4, length: 0))
    #expect(MarkdownTextView.lineRange(in: "🙂one\ntwo", containingUTF16Offset: 2) == NSRange(location: 0, length: 5))
  }

  @Test("moves current line highlight when selection changes")
  func movesCurrentLineHighlightWhenSelectionChanges() {
    let textView = makeTextView()
    textView.string = "one\ntwo\nthree"

    textView.setSelectedRange(NSRange(location: 5, length: 0))

    #expect(backgroundColor(in: textView, at: 4) != nil)
    #expect(backgroundColor(in: textView, at: 0) == nil)

    textView.setSelectedRange(NSRange(location: 1, length: 0))

    #expect(backgroundColor(in: textView, at: 0) != nil)
    #expect(backgroundColor(in: textView, at: 4) == nil)
  }

  @Test("small document heading highlight remains synchronous")
  func smallDocumentHeadingHighlightRemainsSynchronous() {
    let textView = makeTextView()
    textView.string = "# Title"

    textView.applyHeadingHighlighting()

    let color = textView.textStorage?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
    #expect(color != nil)
  }

  private func makeTextView() -> MarkdownTextView {
    let textStorage = NSTextStorage()
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: NSSize(width: 400, height: CGFloat.greatestFiniteMagnitude))
    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)
    return MarkdownTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 400), textContainer: textContainer)
  }

  private func backgroundColor(in textView: MarkdownTextView, at characterIndex: Int) -> NSColor? {
    textView.layoutManager?.temporaryAttribute(
      .backgroundColor,
      atCharacterIndex: characterIndex,
      effectiveRange: nil
    ) as? NSColor
  }
}

@MainActor
private final class TextViewDelegateSpy: NSObject, NSTextViewDelegate {
  var changeRanges: [NSRange] = []
  var replacementStrings: [String] = []

  func textView(
    _ textView: NSTextView,
    shouldChangeTextIn affectedCharRange: NSRange,
    replacementString: String?
  ) -> Bool {
    changeRanges.append(affectedCharRange)
    replacementStrings.append(replacementString ?? "")
    return true
  }
}
