import SwiftUI
import ComposableArchitecture

extension Game.State {
  var score: Int {
    pegboardHistory.count * 150
  }
  var isFirstMove: Bool {
    pegboardHistory.isEmpty
  }
  var isPaused: Bool {
    !isFirstMove && !isTimerEnabled
  }
  var isGameOver: Bool {
    pegboardCurrent.potentialMoves == 0
  }
  var isUndoButtonDisabled: Bool {
    isFirstMove || isPaused
  }
  var isPauseButtonDisabled: Bool {
    isFirstMove || isGameOver
  }
  var isRestartButtonDisabled: Bool {
    isFirstMove
  }
  var maxScore: Int {
    (pegboardCurrent.pegs.count - 1) * 150
  }
}
