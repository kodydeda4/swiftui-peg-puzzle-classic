import SwiftUI
import ComposableArchitecture

struct Game: Reducer {
  struct State: Equatable {
    var pegboardCurrent = Pegboard.State()
    var pegboardHistory = [Pegboard.State]()
    var score = 0
    var secondsElapsed = 0
    var isTimerEnabled = false
    @PresentationState var destination: Destination.State?
  }
  
  enum Action: Equatable {
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
    Scope(state: \.pegboardCurrent, action: /Action.pegboard) {
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
          state.destination = .restartAlert()
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
        
        case .gameOver(.newGameButtonTapped), 
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
    .ifLet(\.$destination, action: /Action.destination) {
      Destination()
    }
  }
  
  struct Destination: Reducer {
    enum State: Equatable {
      case gameOver(GameOver.State)
      case restartAlert(AlertState<Action.RestartAlert> = .init())
    }
    enum Action: Equatable {
      case gameOver(GameOver.Action)
      case restartAlert(RestartAlert)
      
      enum RestartAlert: Equatable {
        case yesButtonTapped
      }
    }
    var body: some ReducerOf<Self> {
      Scope(state: /State.gameOver, action: /Action.gameOver) {
        GameOver()
      }
    }
  }
}

extension AlertState where Action == Game.Destination.Action.RestartAlert {
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

struct GameView: View {
  let store: StoreOf<Game>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
      NavigationStack {
        VStack {
          Header(store: store)
          
          PegboardView(store: store.scope(
            state: \.pegboardCurrent,
            action: { .pegboard($0) }
          ))
          .frame(maxHeight: .infinity)
          .disabled(viewStore.isGameOver || viewStore.isPaused)
          
          Footer(store: store)
        }
        .navigationTitle("Peggy")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
          store: store.scope(state: \.$destination, action: Game.Action.destination),
          state: /Game.Destination.State.restartAlert,
          action: Game.Destination.Action.restartAlert
        )
        .sheet(
          store: store.scope(state: \.$destination, action: Game.Action.destination),
          state: /Game.Destination.State.gameOver,
          action: Game.Destination.Action.gameOver,
          content: GameOverSheet.init(store:)
        )
      }
    }
  }
}

private struct Header: View {
  let store: StoreOf<Game>

  var body: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
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
          
          Text(viewStore.score.description)
            .padding(.trailing)
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .background {
              ProgressView(
                value: CGFloat(viewStore.score),
                total: CGFloat(viewStore.maxScore)
              )
              .progressViewStyle(GradientProgressStyle())
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
}

private struct Footer: View {
  let store: StoreOf<Game>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
      VStack(spacing: 0) {
        Divider()
        VStack {
          HStack {
            Text("Seconds")
              .bold()
              .frame(width: 70, alignment: .leading)
              .padding()
              .background { Color(.systemGray5) }
            Text(viewStore.secondsElapsed.description)
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
            Button(action: { viewStore.send(.undoButtonTapped) }) {
              ThiccButtonLabel(
                title: "Undo",
                systemImage: "arrow.uturn.backward"
              )
            }
            .disabled(viewStore.isUndoButtonDisabled)
            
            Button(action: { viewStore.send(.pauseButtonTapped) }) {
              ThiccButtonLabel(
                title: viewStore.isPaused ? "Play" : "Pause",
                systemImage: viewStore.isPaused ? "play" : "pause"
              )
            }
            .disabled(viewStore.isPauseButtonDisabled)
            
            Button(action: { viewStore.send(.restartButtonTapped) }) {
              ThiccButtonLabel(
                title: "Restart",
                systemImage: ""
              )
            }
            .disabled(viewStore.isRestartButtonDisabled)
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
}

struct GradientProgressStyle: ProgressViewStyle {
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

private struct ThiccButtonLabel: View {
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
