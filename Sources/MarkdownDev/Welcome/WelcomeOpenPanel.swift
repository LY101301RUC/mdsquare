import AppKit

enum WelcomeOpenPanel {
  @MainActor
  static func chooseMarkdownFile() -> URL? {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedContentTypes = [.markdownDevMarkdown]
    panel.message = "选择一个 Markdown 文件"
    panel.prompt = "打开"
    return panel.runModal() == .OK ? panel.url : nil
  }
}
