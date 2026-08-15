enum DocumentFileState: Equatable {
  case healthy
  case missing
  case readOnly
  case externallyModified

  var message: String? {
    switch self {
    case .healthy:
      nil
    case .missing:
      "原文件已不存在。请使用另存为保存当前内容。"
    case .readOnly:
      "当前文件不可写。保存前请检查文件权限。"
    case .externallyModified:
      "原文件已被其他应用修改。继续保存可能覆盖外部更改。"
    }
  }
}
