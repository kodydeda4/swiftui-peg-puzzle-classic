import SwiftUI
import ComposableArchitecture

@Reducer
struct Game {
  
  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
    var pegboardCurrent = Pegboard.State()
    var pegboardHistory = [Pegboard.State]()
    var score = 0
    var secondsElapsed = 0
    var isTimerEnabled = false
  }
  
  public enum Action: ViewAction {
    case view(View)
    case pegboard(Pegboard.Action)
    case destination(PresentationAction<Destination.Action>)
    case toggleIsPaused
    case timerTicked
    case gameOver
    
    enum View {
      case undoButtonTapped
      case pauseButtonTapped
      case restartButtonTapped
      case dismissButtonTapped
    }
  }
  
  private enum CancelID { case timer }
  
  @Dependency(\.continuousClock) var clock
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Scope(state: \.pegboardCurrent, action: \.pegboard) {
      Pegboard()
    }
    Reduce { state, action in
      switch action {
        
      case let .destination(.presented(action)):
        switch action {
          
        case .gameOver(.view(.newGameButtonTapped)),
            .restartAlert(.confirm):
          state = State()
          return .cancel(id: CancelID.timer)
          
        case .exitGameAlert(.confirm):
          return .run { _ in await self.dismiss() }
          
        default:
          return .none
        }
        
      case .pegboard(.delegate(.didComplete)):
        state.score += 150
        state.pegboardHistory.append(state.pegboardCurrent)
        
        if state.isGameOver {
          return .run { send in
            try await self.clock.sleep(for: .seconds(1))
            await send(.gameOver)
          }
        } else if state.pegboardHistory.count == 1 {
          return .send(.toggleIsPaused)
        }
        return .none
        
      case .toggleIsPaused:
        state.isTimerEnabled.toggle()
        return .run { [isTimerActive = state.isTimerEnabled] send in
          guard isTimerActive else { return }
          for await _ in self.clock.timer(interval: .seconds(1)) {
            await send(.timerTicked)
          }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
        
      case .timerTicked:
        state.secondsElapsed += 1
        return .none
        
      case .gameOver:
        state.destination = .gameOver(GameOver.State(
          score: state.score,
          maxScore: state.maxScore,
          secondsElapsed: state.secondsElapsed
        ))
        return .send(.toggleIsPaused)
        
      case .pegboard,
          .destination:
        return .none
        
      case let .view(action):
        switch action {
          
        case .undoButtonTapped:
          state.score -= 150
          state.pegboardHistory.removeLast()
          state.pegboardCurrent = state.pegboardHistory.last ?? .init()
          if state.pegboardHistory.isEmpty {
            state = State()
            return .cancel(id: CancelID.timer)
          }
          return .none
          
        case .pauseButtonTapped:
          return .send(.toggleIsPaused)
          
        case .restartButtonTapped:
          state.destination = .restartAlert(
            AlertState<Destination.RestartAlert>()
          )
          return state.isPaused ? .none : .send(.toggleIsPaused)
          
        case .dismissButtonTapped:
          state.destination = .exitGameAlert(
            AlertState<Destination.ExitGameAlert>()
          )
          return state.isPaused ? .none : .send(.toggleIsPaused)
        }
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension Game {
    
  @Reducer(state: .equatable)
  enum Destination {
    case gameOver(GameOver)
    case restartAlert(AlertState<RestartAlert>)
    case exitGameAlert(AlertState<ExitGameAlert>)
    
    @CasePathable
    enum RestartAlert {
      case confirm
    }
    
    @CasePathable
    enum ExitGameAlert {
      case confirm
    }
  }
}

extension AlertState where Action == Game.Destination.RestartAlert {
  init() {
    self = Self {
      TextState("Restart?")
    } actions: {
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
      ButtonState(role: .destructive, action: .confirm) {
        TextState("Yes")
      }
    } message: {
      TextState("Restart the game?")
    }
  }
}

extension AlertState where Action == Game.Destination.ExitGameAlert {
  init() {
    self = Self {
      TextState("Exit Game?")
    } actions: {
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
      ButtonState(role: .destructive, action: .confirm) {
        TextState("Yes")
      }
    }
  }
}

extension Game.State {
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

// MARK: - SwiftUI

@ViewAction(for: Game.self)
struct GameView: View {
  @Bindable var store: StoreOf<Game>
  
  var body: some View {
    NavigationStack {
      VStack {
        self.header
        
        PegboardView(store: store.scope(
          state: \.pegboardCurrent,
          action: \.pegboard
        ))
        .frame(maxHeight: .infinity)
        .disabled(store.isGameOver || store.isPaused)
        
        self.footer
      }
      .navigationTitle("Peggy")
      .navigationBarTitleDisplayMode(.inline)
      .alert(store: store.scope(
        state: \.$destination.restartAlert,
        action: \.destination.restartAlert
      ))
      .alert(store: store.scope(
        state: \.$destination.exitGameAlert,
        action: \.destination.exitGameAlert
      ))
      .sheet(item: $store.scope(
        state: \.destination?.gameOver,
        action: \.destination.gameOver
      )) { store in
        GameOverSheet(store: store)
      }
      .toolbar {
        Button(action: { send(.dismissButtonTapped) }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(Color(.systemGray2))
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  GameView(store: Store(initialState: Game.State()) {
    Game()
  })
}

