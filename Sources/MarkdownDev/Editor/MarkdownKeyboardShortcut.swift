import AppKit

enum MarkdownKeyboardShortcut {
  static func command(
    for key: String?,
    modifiers: NSEvent.ModifierFlags
  ) -> MarkdownEditorCommand? {
    let normalizedModifiers = modifiers.intersection([.command, .option, .control, .shift])
    guard normalizedModifiers == .command else {
      return nil
    }

    switch key?.lowercased() {
    case "b":
      return .bold
    case "i":
      return .italic
    case "k":
      return .link
    default:
      return nil
    }
  }
}
