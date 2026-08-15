import AppKit

final class MarkdownTextView: NSTextView {
  var onTextChange: (@MainActor (String) -> Void)?
  var onSelectionChange: (@MainActor (NSRange) -> Void)?
  var palette: HeadingColorPalette = .default {
    didSet {
      applyHeadingHighlighting()
    }
  }

  private var isApplyingHighlighting = false
  private var lastNotifiedSelection: NSRange?
  private var highlightedLineRange: NSRange?
  private var pendingHighlightWorkItem: DispatchWorkItem?

  override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
    super.init(frame: frameRect, textContainer: container)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  override func didChangeText() {
    super.didChangeText()
    guard !isApplyingHighlighting else {
      return
    }

    onTextChange?(string)
    scheduleHeadingHighlighting()
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if let command = MarkdownKeyboardShortcut.command(
      for: event.charactersIgnoringModifiers,
      modifiers: event.modifierFlags
    ) {
      applyCommand(command)
      return true
    }

    return super.performKeyEquivalent(with: event)
  }

  override func setSelectedRange(_ charRange: NSRange) {
    super.setSelectedRange(clampedRange(charRange))
    notifySelectionChanged()
    updateCurrentLineHighlight()
  }

  override func setSelectedRanges(
    _ selectedRanges: [NSValue],
    affinity: NSSelectionAffinity,
    stillSelecting stillSelectingFlag: Bool
  ) {
    super.setSelectedRanges(selectedRanges, affinity: affinity, stillSelecting: stillSelectingFlag)
    notifySelectionChanged()
    updateCurrentLineHighlight()
  }

  func replaceText(with newText: String) {
    guard string != newText else {
      applyHeadingHighlighting()
      return
    }

    let replacementRange = fullTextRange()
    let preservedSelection = clampedRange(selectedRange(), inTextLength: (newText as NSString).length)
    let undoManager = undoManager
    let wasUndoRegistrationEnabled = undoManager?.isUndoRegistrationEnabled ?? false
    if wasUndoRegistrationEnabled {
      undoManager?.disableUndoRegistration()
    }

    textStorage?.replaceCharacters(in: replacementRange, with: newText)
    if wasUndoRegistrationEnabled {
      undoManager?.enableUndoRegistration()
    }

    pendingHighlightWorkItem?.cancel()
    setSelectedRange(preservedSelection)
    applyHeadingHighlighting()
  }

  func applyCommand(_ command: MarkdownEditorCommand) {
    let currentSelection = selectedRange()
    let selection = currentSelection.location..<(currentSelection.location + currentSelection.length)
    let originalText = string
    let result = EditorCommandHandler.apply(command, to: originalText, selection: selection)
    let replacementRange = NSRange(result.replacementRange, inText: originalText)

    guard result.text != originalText else {
      setSelectedRange(NSRange(result.selection, inText: result.text))
      return
    }

    guard shouldChangeText(in: replacementRange, replacementString: result.replacementText) else {
      return
    }

    textStorage?.replaceCharacters(in: replacementRange, with: result.replacementText)
    didChangeText()
    setSelectedRange(NSRange(result.selection, inText: result.text))
  }

  func performFindAction(_ action: MarkdownFindAction) {
    performTextFinderAction(action.textFinderAction.rawValue)
  }

  func scrollToHeading(_ heading: Heading) {
    guard let currentHeading = HeadingExtractor.extract(from: string).first(where: { $0.id == heading.id }) else {
      return
    }

    let headingRange = NSRange(currentHeading.sourceRange, in: string)
    setSelectedRange(NSRange(location: headingRange.location, length: 0))
    scrollRangeToVisible(headingRange)
  }

  func applyHeadingHighlighting() {
    guard !isApplyingHighlighting, let textStorage else {
      return
    }

    isApplyingHighlighting = true
    HeadingSyntaxHighlighter.apply(to: textStorage, palette: palette)
    typingAttributes = [
      .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
      .foregroundColor: NSColor.labelColor
    ]
    isApplyingHighlighting = false
    updateCurrentLineHighlight()
  }

  func scheduleHeadingHighlighting() {
    pendingHighlightWorkItem?.cancel()

    switch EditorPerformancePolicy.highlightMode(forUTF16Length: (string as NSString).length) {
    case .immediate:
      applyHeadingHighlighting()
    case let .debounced(milliseconds):
      let workItem = DispatchWorkItem { [weak self] in
        self?.applyHeadingHighlighting()
      }
      pendingHighlightWorkItem = workItem
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds), execute: workItem)
    }
  }

  static func lineRange(in text: String, containingUTF16Offset offset: Int) -> NSRange {
    let nsText = text as NSString
    let textLength = nsText.length
    guard textLength > 0 else {
      return NSRange(location: 0, length: 0)
    }

    let clampedOffset = min(max(offset, 0), textLength)
    if clampedOffset == textLength, text.hasSuffix("\n") {
      return NSRange(location: textLength, length: 0)
    }

    let lookupOffset = min(clampedOffset, textLength - 1)
    return nsText.lineRange(for: NSRange(location: lookupOffset, length: 0))
      .removingTrailingNewline(in: nsText)
  }

  private func commonInit() {
    isRichText = false
    importsGraphics = false
    allowsUndo = true
    isAutomaticQuoteSubstitutionEnabled = false
    isAutomaticDashSubstitutionEnabled = false
    isAutomaticTextReplacementEnabled = false
    isAutomaticSpellingCorrectionEnabled = false
    isContinuousSpellCheckingEnabled = false
    font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    textColor = .labelColor
    backgroundColor = .textBackgroundColor
    drawsBackground = true
    isVerticallyResizable = true
    isHorizontallyResizable = false
    minSize = NSSize(width: 0, height: 0)
    maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    autoresizingMask = [.width]
    textContainerInset = NSSize(width: 16, height: 16)
    textContainer?.widthTracksTextView = true
    textContainer?.heightTracksTextView = false
    textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
  }

  private func fullTextRange() -> NSRange {
    NSRange(location: 0, length: (string as NSString).length)
  }

  private func notifySelectionChanged() {
    let currentSelection = selectedRange()
    guard lastNotifiedSelection != currentSelection else {
      return
    }

    lastNotifiedSelection = currentSelection
    onSelectionChange?(currentSelection)
  }

  private func clampedRange(_ range: NSRange) -> NSRange {
    clampedRange(range, inTextLength: (string as NSString).length)
  }

  private func clampedRange(_ range: NSRange, inTextLength textLength: Int) -> NSRange {
    guard range.location != NSNotFound else {
      return NSRange(location: 0, length: 0)
    }

    let location = min(max(range.location, 0), textLength)
    let upperBound = min(max(range.location + range.length, location), textLength)
    return NSRange(location: location, length: upperBound - location)
  }

  private func updateCurrentLineHighlight() {
    guard let layoutManager else {
      return
    }

    let textLength = (string as NSString).length
    if let highlightedLineRange, highlightedLineRange.location < textLength {
      let removableRange = NSRange(
        location: highlightedLineRange.location,
        length: min(highlightedLineRange.length, textLength - highlightedLineRange.location)
      )
      layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: removableRange)
    }

    let lineRange = Self.lineRange(in: string, containingUTF16Offset: selectedRange().location)
    highlightedLineRange = lineRange
    guard lineRange.length > 0 else {
      return
    }

    layoutManager.addTemporaryAttribute(
      .backgroundColor,
      value: NSColor.controlAccentColor.withAlphaComponent(0.08),
      forCharacterRange: lineRange
    )
  }
}

private extension NSRange {
  init(_ range: Range<Int>, inText text: String) {
    let textLength = (text as NSString).length
    let location = min(max(range.lowerBound, 0), textLength)
    let upperBound = min(max(range.upperBound, location), textLength)
    self.init(location: location, length: upperBound - location)
  }

  func removingTrailingNewline(in text: NSString) -> NSRange {
    var trimmedLength = length
    while trimmedLength > 0 {
      let character = text.character(at: location + trimmedLength - 1)
      if character == 10 || character == 13 {
        trimmedLength -= 1
      } else {
        break
      }
    }

    return NSRange(location: location, length: trimmedLength)
  }
}
