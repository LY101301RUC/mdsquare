import AppKit

@MainActor
enum ApplicationMenuLocalizer {
  private static let topLevelTitleMap = [
    "File": "文件",
    "Edit": "编辑",
    "View": "显示",
    "Markdown": "格式",
    "Format": "格式",
    "Find": "查找",
    "Window": "窗口",
    "Help": "帮助"
  ]

  static func install() {
    localize(NSApp.mainMenu)

    DispatchQueue.main.async {
      localize(NSApp.mainMenu)
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      localize(NSApp.mainMenu)
    }
  }

  static func localize(_ menu: NSMenu?) {
    guard let menu else {
      return
    }

    for item in menu.items {
      guard let title = topLevelTitleMap[item.title] else {
        continue
      }

      item.title = title
      item.submenu?.title = title
    }
  }
}
