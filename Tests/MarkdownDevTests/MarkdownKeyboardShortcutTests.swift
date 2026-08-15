import AppKit
import Testing
@testable import MarkdownDev

@Suite("MarkdownKeyboardShortcut")
struct MarkdownKeyboardShortcutTests {
  @Test("maps common command shortcuts to markdown commands")
  func mapsCommonCommandShortcutsToMarkdownCommands() {
    #expect(MarkdownKeyboardShortcut.command(for: "b", modifiers: [.command]) == .bold)
    #expect(MarkdownKeyboardShortcut.command(for: "i", modifiers: [.command]) == .italic)
    #expect(MarkdownKeyboardShortcut.command(for: "k", modifiers: [.command]) == .link)
  }

  @Test("ignores shortcuts with extra option modifier")
  func ignoresShortcutsWithExtraOptionModifier() {
    #expect(MarkdownKeyboardShortcut.command(for: "b", modifiers: [.command, .option]) == nil)
  }
}
