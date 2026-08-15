import AppKit
import SwiftUI

@main
struct MarkdownDevApp: App {
  @NSApplicationDelegateAdaptor(MdSquareAppDelegate.self) private var appDelegate

  init() {
    DocumentWindowTabbingPolicy.enableAppWideAutomaticTabbing()
  }

  var body: some Scene {
    WindowGroup("MdSquare", id: WelcomeWindow.id) {
      WelcomeView(recentStore: .shared)
    }
    .defaultSize(width: WelcomeWindow.width, height: WelcomeWindow.height)
    .windowResizability(.contentSize)

    DocumentGroup(newDocument: MarkdownDocument()) { file in
      DocumentRootView(document: file.$document, fileURL: file.fileURL)
    }
    .commands {
      DocumentViewModeCommands()
      MarkdownCommandMenu()
      MarkdownFindCommandMenu()
    }
  }
}

private struct MarkdownCommandActionKey: FocusedValueKey {
  typealias Value = (MarkdownEditorCommand) -> Void
}

extension FocusedValues {
  var markdownCommandAction: ((MarkdownEditorCommand) -> Void)? {
    get { self[MarkdownCommandActionKey.self] }
    set { self[MarkdownCommandActionKey.self] = newValue }
  }
}

private struct MarkdownFindActionKey: FocusedValueKey {
  typealias Value = (MarkdownFindAction) -> Void
}

extension FocusedValues {
  var markdownFindAction: ((MarkdownFindAction) -> Void)? {
    get { self[MarkdownFindActionKey.self] }
    set { self[MarkdownFindActionKey.self] = newValue }
  }
}

struct DocumentViewModeCommands: Commands {
  @AppStorage(DocumentViewPreferences.viewModeKey) private var viewModeRawValue = DocumentViewMode.threeColumn.rawValue

  var body: some Commands {
    CommandGroup(after: .toolbar) {
      Divider()

      Button("三栏模式") { setViewMode(.threeColumn) }
        .keyboardShortcut("1", modifiers: [.command, .control])
      Button("写作模式") { setViewMode(.writing) }
        .keyboardShortcut("2", modifiers: [.command, .control])
      Button("阅读模式") { setViewMode(.reading) }
        .keyboardShortcut("3", modifiers: [.command, .control])
      Button("专注模式") { setViewMode(.focus) }
        .keyboardShortcut("4", modifiers: [.command, .control])
    }
  }

  private func setViewMode(_ mode: DocumentViewMode) {
    viewModeRawValue = mode.rawValue
  }
}

struct MarkdownCommandMenu: Commands {
  @FocusedValue(\.markdownCommandAction) private var action

  var body: some Commands {
    CommandMenu("格式") {
      Button("一级标题") { action?(.heading(.h1)) }
        .keyboardShortcut("1", modifiers: [.command, .option])
        .disabled(action == nil)
      Button("二级标题") { action?(.heading(.h2)) }
        .keyboardShortcut("2", modifiers: [.command, .option])
        .disabled(action == nil)
      Button("三级标题") { action?(.heading(.h3)) }
        .keyboardShortcut("3", modifiers: [.command, .option])
        .disabled(action == nil)

      Divider()

      Button("加粗") { action?(.bold) }
        .keyboardShortcut("b", modifiers: .command)
        .disabled(action == nil)
      Button("斜体") { action?(.italic) }
        .keyboardShortcut("i", modifiers: .command)
        .disabled(action == nil)
      Button("链接") { action?(.link) }
        .keyboardShortcut("k", modifiers: .command)
        .disabled(action == nil)

      Divider()

      Button("红色文字") { action?(.textColor(.red)) }
        .keyboardShortcut("r", modifiers: [.command, .option])
        .disabled(action == nil)
      Button("蓝色文字") { action?(.textColor(.blue)) }
        .keyboardShortcut("u", modifiers: [.command, .option])
        .disabled(action == nil)

      Divider()

      Button("无序列表") { action?(.unorderedList) }
        .keyboardShortcut("8", modifiers: [.command, .option])
        .disabled(action == nil)
      Button("有序列表") { action?(.orderedList) }
        .keyboardShortcut("7", modifiers: [.command, .option])
        .disabled(action == nil)
      Button("引用") { action?(.quote) }
        .keyboardShortcut("9", modifiers: [.command, .option])
        .disabled(action == nil)
      Button("代码块") { action?(.codeBlock) }
        .keyboardShortcut("`", modifiers: [.command, .option])
        .disabled(action == nil)
    }
  }
}

struct MarkdownFindCommandMenu: Commands {
  @FocusedValue(\.markdownFindAction) private var findAction

  var body: some Commands {
    CommandMenu("查找") {
      Button("查找…") { findAction?(.showFindInterface) }
        .keyboardShortcut("f", modifiers: .command)
        .disabled(findAction == nil)

      Button("查找下一个") { findAction?(.nextMatch) }
        .keyboardShortcut("g", modifiers: .command)
        .disabled(findAction == nil)

      Button("查找上一个") { findAction?(.previousMatch) }
        .keyboardShortcut("g", modifiers: [.command, .shift])
        .disabled(findAction == nil)
    }
  }
}
