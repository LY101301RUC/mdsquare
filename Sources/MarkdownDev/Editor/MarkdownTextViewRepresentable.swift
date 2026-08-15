import AppKit
import SwiftUI

struct MarkdownTextViewRepresentable: NSViewRepresentable {
  @Binding var text: String
  @Binding var selection: NSRange

  let pendingCommand: PendingMarkdownCommand?
  let pendingFindAction: PendingFindAction?
  let scrollTarget: Heading?
  let onCommandApplied: () -> Void
  let onFindActionApplied: () -> Void
  let onScrollTargetConsumed: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.drawsBackground = true
    scrollView.backgroundColor = .textBackgroundColor
    scrollView.borderType = .noBorder

    let textStorage = NSTextStorage()
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude))
    textContainer.widthTracksTextView = true
    textContainer.heightTracksTextView = false

    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)

    let textView = MarkdownTextView(frame: scrollView.contentView.bounds, textContainer: textContainer)
    textView.onTextChange = { [weak coordinator = context.coordinator] updatedText in
      coordinator?.textDidChange(updatedText)
    }
    textView.onSelectionChange = { [weak coordinator = context.coordinator] updatedSelection in
      coordinator?.selectionDidChange(updatedSelection)
    }
    textView.replaceText(with: text)

    scrollView.documentView = textView
    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    context.coordinator.parent = self
    guard let textView = scrollView.documentView as? MarkdownTextView else {
      return
    }

    if textView.string != text {
      textView.replaceText(with: text)
    }

    if textView.selectedRange() != selection {
      textView.setSelectedRange(selection)
    }

    if let commandToApply = context.coordinator.commandToApply(pendingCommand) {
      textView.applyCommand(commandToApply)
      DispatchQueue.main.async {
        onCommandApplied()
      }
    }

    if let findAction = context.coordinator.findActionToApply(pendingFindAction) {
      textView.performFindAction(findAction)
      DispatchQueue.main.async {
        onFindActionApplied()
      }
    }

    if let scrollTarget {
      textView.scrollToHeading(scrollTarget)
      DispatchQueue.main.async {
        onScrollTargetConsumed()
      }
    }
  }

  @MainActor
  final class Coordinator {
    var parent: MarkdownTextViewRepresentable
    private var consumedPendingCommandID: Int?
    private var consumedPendingFindActionID: Int?

    init(parent: MarkdownTextViewRepresentable) {
      self.parent = parent
    }

    func commandToApply(_ pendingCommand: PendingMarkdownCommand?) -> MarkdownEditorCommand? {
      guard let pendingCommand else {
        consumedPendingCommandID = nil
        return nil
      }

      guard consumedPendingCommandID != pendingCommand.id else {
        return nil
      }

      consumedPendingCommandID = pendingCommand.id
      return pendingCommand.command
    }

    func findActionToApply(_ pendingFindAction: PendingFindAction?) -> MarkdownFindAction? {
      guard let pendingFindAction else {
        consumedPendingFindActionID = nil
        return nil
      }

      guard consumedPendingFindActionID != pendingFindAction.id else {
        return nil
      }

      consumedPendingFindActionID = pendingFindAction.id
      return pendingFindAction.action
    }

    func textDidChange(_ updatedText: String) {
      guard parent.text != updatedText else {
        return
      }

      parent.text = updatedText
    }

    func selectionDidChange(_ updatedSelection: NSRange) {
      guard parent.selection != updatedSelection else {
        return
      }

      parent.selection = updatedSelection
    }
  }
}
