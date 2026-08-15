import AppKit
import Testing
@testable import MarkdownDev

@Suite("ApplicationMenuLocalizer")
struct ApplicationMenuLocalizerTests {
  @Test("localizes top-level menu titles")
  @MainActor
  func localizesTopLevelMenuTitles() {
    let menu = NSMenu()
    for title in ["MdSquare", "File", "Edit", "View", "Markdown", "查找", "Window", "Help"] {
      let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
      item.submenu = NSMenu(title: title)
      menu.addItem(item)
    }

    ApplicationMenuLocalizer.localize(menu)

    #expect(menu.items.map(\.title) == ["MdSquare", "文件", "编辑", "显示", "格式", "查找", "窗口", "帮助"])
    #expect(menu.items[1].submenu?.title == "文件")
    #expect(menu.items[4].submenu?.title == "格式")
  }
}
