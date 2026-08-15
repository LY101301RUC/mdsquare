import AppKit

enum MarkdownFindAction: Equatable {
  case showFindInterface
  case nextMatch
  case previousMatch
  case replace

  var textFinderAction: NSTextFinder.Action {
    switch self {
    case .showFindInterface:
      .showFindInterface
    case .nextMatch:
      .nextMatch
    case .previousMatch:
      .previousMatch
    case .replace:
      .replace
    }
  }
}
