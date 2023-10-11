import SwiftUI
import ComposableArchitecture

struct NewGame: Reducer {
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
      case pauseButtonTapped
      case quitButtonTapped
      case undoButtonTapped
      case redoButtonTapped
      case newGameButtonTapped
    }
  }
  
  private enum CancelID { case timer }
  
  @Dependency(\.continuousClock) var clock
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Scope(state: \.pegboardCurrent, action: /Action.pegboard) {
      Pegboard()
    }
    Reduce { state, action in
      switch action {
      
      case let .view(action):
        switch action {
          
        case .pauseButtonTapped:
          return .send(.toggleIsPaused)
          
        case .quitButtonTapped:
          return .run { _ in await self.dismiss() }
          
        case .undoButtonTapped:
          state.score -= 150
          state.pegboardHistory.removeLast()
          state.pegboardCurrent = state.pegboardHistory.last ?? .init()
          if state.pegboardHistory.isEmpty {
            state = State()
            return .cancel(id: CancelID.timer)
          }
          return .none
          
        case .redoButtonTapped:
          return .none
          
        case .newGameButtonTapped:
          state = State()
          return .cancel(id: CancelID.timer)
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
          
      case .destination(.presented(.gameOver(.newGameButtonTapped))):
        state = State()
        return .none
        
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
    }
    enum Action: Equatable {
      case gameOver(GameOver.Action)
    }
    var body: some ReducerOf<Self> {
      Scope(state: /State.gameOver, action: /Action.gameOver) {
        GameOver()
      }
    }
  }
}

private extension NewGame.State {
  var isPaused: Bool {
    !isTimerEnabled && !pegboardHistory.isEmpty
  }
  var isGameOver: Bool {
    pegboardCurrent.potentialMoves == 0
  }
  var isUndoButtonDisabled: Bool {
    isPaused || pegboardHistory.isEmpty
  }
  var isPauseButtonDisabled: Bool {
    isGameOver || pegboardHistory.isEmpty
  }
  var isRedoButtonDisabled: Bool {
    isPaused
  }
  var maxScore: Int {
    (pegboardCurrent.pegs.count - 1) * 150
  }
}

// MARK: - SwiftUI

struct NewGameView: View {
  let store: StoreOf<NewGame>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
      NavigationStack {
        VStack {
          header

          Spacer()
          
          PegboardView(store: store.scope(
            state: \.pegboardCurrent,
            action: { .pegboard($0) }
          ))
          .disabled(viewStore.isPaused)
          .padding()
          
          Spacer()
          
          footer
        }
        .disabled(viewStore.isGameOver)
        .navigationTitle("New Game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
              Button(action: { viewStore.send(.newGameButtonTapped) }) {
                Text("New Game")
              }
              Button(action: { viewStore.send(.quitButtonTapped) }) {
                Text("Quit")
              }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
          }
        }
        .sheet(
          store: store.scope(
            state: \.$destination,
            action: NewGame.Action.destination
          ),
          state: /NewGame.Destination.State.gameOver,
          action: NewGame.Destination.Action.gameOver,
          content: GameOverSheet.init(store:)
        )
      }
    }
  }
  
  private var score: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
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
            VStack {
              Spacer()
              ProgressView(
                value: CGFloat(viewStore.score),
                total: CGFloat(viewStore.maxScore)
              )
              .animation(.default, value: viewStore.score)
            }
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
    }
  }
  
  private var seconds: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
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
    }
  }
  
  private var header: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
      VStack(spacing: 0) {
        VStack {
          score
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
  
  private var footer: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
      VStack(spacing: 0) {
        Divider()
        VStack {
          seconds
          
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
            
            Button(action: { viewStore.send(.redoButtonTapped) }) {
              ThiccButtonLabel(
                title: "Redo",
                systemImage: "arrow.uturn.forward"
              )
            }
            .disabled(viewStore.isRedoButtonDisabled)
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
    .background { Color(.systemGray6) }
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
  NewGameView(store: Store(
    initialState: NewGame.State(),
    reducer: NewGame.init
  ))
}
