import AppKit
import SwiftUI
import Testing
@testable import MarkdownDev

@MainActor
@Suite("MarkdownTextViewRepresentable")
struct MarkdownTextViewRepresentableTests {
  @Test("consumes a pending command only once until it is cleared")
  func consumesPendingCommandOnlyOnceUntilCleared() {
    var text = "alpha"
    var selection = NSRange(location: 0, length: 0)
    let view = MarkdownTextViewRepresentable(
      text: Binding(get: { text }, set: { text = $0 }),
      selection: Binding(get: { selection }, set: { selection = $0 }),
      pendingCommand: PendingMarkdownCommand(command: .quote, id: 1),
      pendingFindAction: nil,
      scrollTarget: nil,
      onCommandApplied: {},
      onFindActionApplied: {},
      onScrollTargetConsumed: {}
    )
    let coordinator = MarkdownTextViewRepresentable.Coordinator(parent: view)

    #expect(coordinator.commandToApply(PendingMarkdownCommand(command: .quote, id: 1)) == .quote)
    #expect(coordinator.commandToApply(PendingMarkdownCommand(command: .quote, id: 1)) == nil)
    #expect(coordinator.commandToApply(nil) == nil)
    #expect(coordinator.commandToApply(PendingMarkdownCommand(command: .quote, id: 2)) == .quote)
  }

  @Test("consumes repeated equal commands when their event ids differ")
  func consumesRepeatedEqualCommandsWhenEventIDsDiffer() {
    var text = "alpha"
    var selection = NSRange(location: 0, length: 0)
    let view = MarkdownTextViewRepresentable(
      text: Binding(get: { text }, set: { text = $0 }),
      selection: Binding(get: { selection }, set: { selection = $0 }),
      pendingCommand: PendingMarkdownCommand(command: .bold, id: 1),
      pendingFindAction: nil,
      scrollTarget: nil,
      onCommandApplied: {},
      onFindActionApplied: {},
      onScrollTargetConsumed: {}
    )
    let coordinator = MarkdownTextViewRepresentable.Coordinator(parent: view)

    #expect(coordinator.commandToApply(PendingMarkdownCommand(command: .bold, id: 1)) == .bold)
    #expect(coordinator.commandToApply(PendingMarkdownCommand(command: .bold, id: 1)) == nil)
    #expect(coordinator.commandToApply(PendingMarkdownCommand(command: .bold, id: 2)) == .bold)
  }

  @Test("consumes repeated equal find actions when their event ids differ")
  func consumesRepeatedEqualFindActionsWhenEventIDsDiffer() {
    var text = "alpha"
    var selection = NSRange(location: 0, length: 0)
    let view = MarkdownTextViewRepresentable(
      text: Binding(get: { text }, set: { text = $0 }),
      selection: Binding(get: { selection }, set: { selection = $0 }),
      pendingCommand: nil,
      pendingFindAction: PendingFindAction(action: .showFindInterface, id: 1),
      scrollTarget: nil,
      onCommandApplied: {},
      onFindActionApplied: {},
      onScrollTargetConsumed: {}
    )
    let coordinator = MarkdownTextViewRepresentable.Coordinator(parent: view)

    #expect(coordinator.findActionToApply(PendingFindAction(action: .showFindInterface, id: 1)) == .showFindInterface)
    #expect(coordinator.findActionToApply(PendingFindAction(action: .showFindInterface, id: 1)) == nil)
    #expect(coordinator.findActionToApply(PendingFindAction(action: .showFindInterface, id: 2)) == .showFindInterface)
  }
}
