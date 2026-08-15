import Foundation

enum DocumentViewMode: String, CaseIterable, Identifiable {
  case threeColumn
  case writing
  case reading
  case focus

  var id: String { rawValue }

  var title: String {
    switch self {
    case .threeColumn: "三栏"
    case .writing: "写作"
    case .reading: "阅读"
    case .focus: "专注"
    }
  }

  var menuTitle: String {
    "\(title)模式"
  }

  var systemImage: String {
    switch self {
    case .threeColumn: "rectangle.split.3x1"
    case .writing: "sidebar.left"
    case .reading: "doc.richtext"
    case .focus: "rectangle"
    }
  }

  var showsOutline: Bool {
    self == .threeColumn || self == .writing || self == .reading
  }

  var showsEditor: Bool {
    self == .threeColumn || self == .writing || self == .focus
  }

  var showsPreview: Bool {
    self == .threeColumn || self == .reading
  }

  static func resolved(from rawValue: String) -> DocumentViewMode {
    DocumentViewMode(rawValue: rawValue) ?? .threeColumn
  }
}

enum DocumentViewPreferences {
  static let viewModeKey = "MdSquare.document.viewMode"
  static let editorFractionKey = "MdSquare.document.editorFraction"
}
