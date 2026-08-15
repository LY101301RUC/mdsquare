import SwiftUI

struct MarkdownToolbar: ToolbarContent {
  let send: (MarkdownEditorCommand) -> Void
  let viewMode: DocumentViewMode
  let setViewMode: (DocumentViewMode) -> Void
  let isEditorVisible: Bool

  var body: some ToolbarContent {
    ToolbarItemGroup {
      Menu {
        ForEach(DocumentViewMode.allCases) { mode in
          Button {
            setViewMode(mode)
          } label: {
            Label(mode.menuTitle, systemImage: mode == viewMode ? "checkmark" : mode.systemImage)
          }
        }
      } label: {
        Label(viewMode.title, systemImage: viewMode.systemImage)
      }
      .help("视图模式")
      .accessibilityLabel("视图模式")

      Menu {
        Button("一级标题") { send(.heading(.h1)) }
        Button("二级标题") { send(.heading(.h2)) }
        Button("三级标题") { send(.heading(.h3)) }
        Button("四级标题") { send(.heading(.h4)) }
        Button("五级标题") { send(.heading(.h5)) }
        Button("六级标题") { send(.heading(.h6)) }
      } label: {
        Image(systemName: "textformat.size")
      }
      .help("标题")
      .accessibilityLabel("标题")
      .disabled(!isEditorVisible)

      Button { send(.bold) } label: { Image(systemName: "bold") }
        .help("加粗")
        .accessibilityLabel("加粗")
        .disabled(!isEditorVisible)
      Button { send(.italic) } label: { Image(systemName: "italic") }
        .help("斜体")
        .accessibilityLabel("斜体")
        .disabled(!isEditorVisible)
      Menu {
        Button("红色") { send(.textColor(.red)) }
        Button("蓝色") { send(.textColor(.blue)) }
      } label: {
        Image(systemName: "paintpalette")
      }
      .help("文字颜色")
      .accessibilityLabel("文字颜色")
      .disabled(!isEditorVisible)
      Button { send(.link) } label: { Image(systemName: "link") }
        .help("链接")
        .accessibilityLabel("链接")
        .disabled(!isEditorVisible)
      Button { send(.unorderedList) } label: { Image(systemName: "list.bullet") }
        .help("无序列表")
        .accessibilityLabel("无序列表")
        .disabled(!isEditorVisible)
      Button { send(.orderedList) } label: { Image(systemName: "list.number") }
        .help("有序列表")
        .accessibilityLabel("有序列表")
        .disabled(!isEditorVisible)
      Button { send(.quote) } label: { Image(systemName: "quote.opening") }
        .help("引用")
        .accessibilityLabel("引用")
        .disabled(!isEditorVisible)
      Button { send(.codeBlock) } label: { Image(systemName: "chevron.left.forwardslash.chevron.right") }
        .help("代码块")
        .accessibilityLabel("代码块")
        .disabled(!isEditorVisible)
    }
  }
}
