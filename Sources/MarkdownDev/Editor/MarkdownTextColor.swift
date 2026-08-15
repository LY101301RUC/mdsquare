enum MarkdownTextColor: String, CaseIterable, Equatable {
  case red
  case blue

  var displayName: String {
    switch self {
    case .red:
      "红色"
    case .blue:
      "蓝色"
    }
  }

  var openingTag: String {
    #"<span style="color: \#(rawValue)">"#
  }

  var closingTag: String {
    "</span>"
  }
}
