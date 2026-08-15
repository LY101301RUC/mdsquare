import SwiftUI

struct EditorPane: View {
  @Binding var text: String
  @Binding var selection: NSRange

  let pendingCommand: PendingMarkdownCommand?
  let pendingFindAction: PendingFindAction?
  let scrollTarget: Heading?
  let onCommandApplied: () -> Void
  let onFindActionApplied: () -> Void
  let onScrollTargetConsumed: () -> Void

  var body: some View {
    MarkdownTextViewRepresentable(
      text: $text,
      selection: $selection,
      pendingCommand: pendingCommand,
      pendingFindAction: pendingFindAction,
      scrollTarget: scrollTarget,
      onCommandApplied: onCommandApplied,
      onFindActionApplied: onFindActionApplied,
      onScrollTargetConsumed: onScrollTargetConsumed
    )
  }
}
