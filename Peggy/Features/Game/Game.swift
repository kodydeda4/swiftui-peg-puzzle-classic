import SwiftUIG
import ComposableArchitecture

@Reducer
struct Game {
  @ObservableState
  struct State: Equatable {
    var pegboardCurrent = Pegboard.State()
    var pegboardHistory = [Pegboard.State]()
    var score = 0
    var secondsElapsed = 0
    var isTimerEnabled = false
    @Presents var destination: Destination.State?
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
    }
  }
  
  private enum CancelID { case timer }
  
  @Dependency(\.continuousClock) var clock
  
  var body: some ReducerOf<Self> {
    Scope(state: \.pegboardCurrent, action: \.pegboard) {
      Pegboard()
    }
    Reduce { state, action in
      switch action {
        
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
          state.destination = .restartAlert(.init())
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
        state.destination = .gameOver(.init(
          score: state.score,
          maxScore: state.maxScore,
          secondsElapsed: state.secondsElapsed
        ))
        return .send(.toggleIsPaused)
        
      case let .destination(.presented(action)):
        switch action {
          
          //@DEDA
        case .gameOver(.view(.newGameButtonTapped)),
            .restartAlert(.yesButtonTapped):
          state = State()
          return .cancel(id: CancelID.timer)
          
        default:
          return .none
        }
        
      case .pegboard, .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
  
  @Reducer(state: .equatable)
  enum Destination {
    case gameOver(GameOver)
    case restartAlert(AlertState<RestartAlert>)
    
    @CasePathable
    enum RestartAlert {
      case yesButtonTapped
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
      ButtonState(role: .destructive, action: .yesButtonTapped) {
        TextState("Yes")
      }
    } message: {
      TextState("Restart the game?")
    }
  }
}

private extension Game.State {
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
        Header(store: store)
        
        PegboardView(store: store.scope(
          state: \.pegboardCurrent,
          action: \.pegboard
        ))
        .frame(maxHeight: .infinity)
        .disabled(store.isGameOver || store.isPaused)
        
        Footer(store: store)
      }
      .navigationTitle("Peggy")
      .navigationBarTitleDisplayMode(.inline)
      .alert(store: store.scope(
        state: \.$destination.restartAlert,
        action: \.destination.restartAlert
      ))
      .sheet(item: $store.scope(
        state: \.destination?.gameOver,
        action: \.destination.gameOver
      )) { store in
        GameOverSheet(store: store)
      }
    }
  }
}

@ViewAction(for: Game.self)
private struct Header: View {
  let store: StoreOf<Game>
  
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Text("Score")
          .bold()
          .frame(width: 50, alignment: .leading)
          .frame(maxHeight: .infinity)
          .padding()
          .background { Color.accentColor.opacity(0.15) }
        
        Rectangle()
          .frame(width: 0.25)
          .foregroundColor(.accentColor)
        
        Text(store.score.description)
          .padding(.trailing)
          .foregroundColor(.accentColor)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
          .background {
            ProgressView(
              value: CGFloat(store.score),
              total: CGFloat(store.maxScore)
            )
            .progressViewStyle(ScoreProgressStyle())
            .opacity(0.25)
          }
      }
      .frame(height: 50)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background { Color.accentColor.opacity(0.25) }
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .strokeBorder()
          .foregroundColor(.accentColor)
      }
      .padding()
      
      Divider()
    }
    .background {
      Color(.systemGray)
        .opacity(0.1)
        .ignoresSafeArea(edges: .top)
    }
  }
}

@ViewAction(for: Game.self)
private struct Footer: View {
  let store: StoreOf<Game>
  
  var body: some View {
    VStack(spacing: 0) {
      Divider()
      VStack {
        HStack {
          Text("Seconds")
            .bold()
            .frame(width: 70, alignment: .leading)
            .padding()
            .background { Color(.systemGray5) }
          Text(store.secondsElapsed.description)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { Color(.systemGray6) }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder()
            .foregroundColor(Color(.separator))
        }
        HStack {
          Button(action: { send(.undoButtonTapped) }) {
            ButtonLabel(
              title: "Undo",
              systemImage: "arrow.uturn.backward"
            )
          }
          .disabled(store.isUndoButtonDisabled)
          
          Button(action: { send(.pauseButtonTapped) }) {
            ButtonLabel(
              title: store.isPaused ? "Play" : "Pause",
              systemImage: store.isPaused ? "play" : "pause"
            )
          }
          .disabled(store.isPauseButtonDisabled)
          
          Button(action: { send(.restartButtonTapped) }) {
            ButtonLabel(
              title: "Restart",
              systemImage: ""
            )
          }
          .disabled(store.isRestartButtonDisabled)
        }
        .buttonStyle(.plain)
        .padding(.bottom)
      }
      .padding()
    }
    .background {
      Color(.systemGray)
        .opacity(0.1)
        .ignoresSafeArea(edges: .bottom)
    }
  }
}

private struct ScoreProgressStyle: ProgressViewStyle {
  func makeBody(configuration: Configuration) -> some View {
    GeometryReader { geometry in
      Rectangle()
        .fill(Color.accentColor)
        .frame(
          maxWidth: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
          maxHeight: .infinity
        )
        .animation(.easeInOut, value: configuration.fractionCompleted)
    }
    .frame(maxHeight: .infinity)
  }
}

private struct ButtonLabel: View {
  let title: String
  let systemImage: String
  
  var body: some View {
    HStack {
      Text(title)
        .bold()
      Image(systemName: systemImage)
    }
    .padding(.horizontal)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity)
    .background { Color(.systemGray5) }
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder()
        .foregroundColor(Color(.separator))
    }
    .frame(width: 120)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  GameView(store: Store(
    initialState: Game.State(),
    reducer: Game.init
  ))
}

