import ComposableArchitecture

extension Game.State {
  var isFirstMove: Bool {
    moveHistory.isEmpty
  }
  var isPaused: Bool {
    !isFirstMove && !isTimerEnabled
  }
  var isGameOver: Bool {
    moveCurrent.potentialMoves == 0
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
    (moveCurrent.pegs.count - 1) * 150
  }
}
