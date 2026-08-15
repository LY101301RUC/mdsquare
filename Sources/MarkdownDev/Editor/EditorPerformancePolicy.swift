enum EditorHighlightMode: Equatable {
  case immediate
  case debounced(milliseconds: Int)
}

enum EditorPerformancePolicy {
  static let immediateHighlightLimitUTF16 = 120_000
  static let largeDocumentHighlightDebounceMS = 120

  static func highlightMode(forUTF16Length length: Int) -> EditorHighlightMode {
    length <= immediateHighlightLimitUTF16
      ? .immediate
      : .debounced(milliseconds: largeDocumentHighlightDebounceMS)
  }
}
