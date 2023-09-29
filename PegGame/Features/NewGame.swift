import SwiftUI
import ComposableArchitecture

// 1. how do you calculate available moves?
// 3. how do you know when it's done?

struct NewGame: Reducer {
  struct State: Equatable {
    var move = Move.State()
    var previousMoves = [Move.State]()
    var score = 0
    var isTimerEnabled = false
    var secondsElapsed = 0
  }
  enum Action: Equatable {
    case view(View)
    case move(Move.Action)
    case toggleIsPaused
    case timerTicked
    
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
    Scope(state: \.move, action: /Action.move) {
      Move()
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
          state.previousMoves.removeLast()
          
          if let prev = state.previousMoves.last {
            state.move = prev
          } else {
            state.move = .init()
          }
          
          if state.previousMoves.isEmpty {
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
        
      case let .move(action):
        switch action {
        case .delegate(.didComplete):
          state.previousMoves.append(state.move)
          state.score += 150
          
          if state.previousMoves.count == 1 {
            return .send(.toggleIsPaused)
          }
          return .none
          
          
        default:
          return .none
        }
        
      case .toggleIsPaused:
        state.isTimerEnabled.toggle()
        return .run { [isTimerActive = state.isTimerEnabled] send in
          guard isTimerActive else { return }
          for await _ in self.clock.timer(interval: .seconds(1)) {
            await send(.timerTicked, animation: .interpolatingSpring(stiffness: 3000, damping: 40))
          }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
  
      case .timerTicked:
        state.secondsElapsed += 1
        return .none
      }
    }
  }
}

extension NewGame.State {
  var isPaused: Bool {
    !isTimerEnabled && !previousMoves.isEmpty
  }
  var isUndoButtonDisabled: Bool {
    previousMoves.isEmpty
  }
  var isRedoButtonDisabled: Bool {
    false
  }
}

struct Move: Reducer {
  struct State: Equatable {
    var pegs = Peg.grid()
    var selection: Peg?
  }
  enum Action: Equatable {
    case move(Peg)
    case delegate(Delegate)
    
    enum Delegate: Equatable {
      case didComplete
    }
  }
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
      
    case let .move(value):
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      
      if state.isFirstMove {
        state.pegs[id: value.id]?.isEmpty = true
        state.selection = nil
        return .send(.delegate(.didComplete))
      }
        
      // check that the peg across form the selection is empty
      guard state.pegs(acrossFrom: state.selection).filter(\.isEmpty).contains(value) else {
        state.selection = value
        return .none
      }
      guard let selection = state.selection else {
        state.selection = state.selection == value ? nil : value
        return .none
      }
      // check that the peg between the selection and the new value is non empty
      guard !Peg.between(selection, value, in: state.pegs).isEmpty else {
        return .none
      }
      state.pegs[id: Peg.between(selection, value, in: state.pegs).id]?.isEmpty = true
      state.pegs[id: selection.id]?.isEmpty = true
      state.pegs[id: value.id]?.isEmpty = false
      state.selection = nil
      return .send(.delegate(.didComplete))
      
    case .delegate:
      return .none
    }
  }
}

extension Move.State {
  var isFirstMove: Bool {
    pegs.filter(\.isEmpty).isEmpty
  }
  func pegs(acrossFrom peg: Peg?) -> IdentifiedArrayOf<Peg> {
    guard let peg = peg else { return [] }
    
    return .init(uniqueElements: [
      pegs[id: [peg.row+0, peg.col-2]], // left
      pegs[id: [peg.row+0, peg.col+2]], // right
      pegs[id: [peg.row-2, peg.col-2]], // up+left
      pegs[id: [peg.row-2, peg.col+0]], // up+right
      pegs[id: [peg.row+2, peg.col]],   // down+left
      pegs[id: [peg.row+2, peg.col+2]], // down+right
    ]
      .compactMap { $0 })
  }
  
  func pegs(adjacentTo peg: Peg?) -> IdentifiedArrayOf<Peg> {
    guard let peg = peg else { return [] }
    
    return .init(uniqueElements: [
      pegs[id: [peg.row+0, peg.col-1]], // left
      pegs[id: [peg.row+0, peg.col+1]], // right
      pegs[id: [peg.row-1, peg.col-1]], // up+left
      pegs[id: [peg.row-1, peg.col+0]], // up+right
      pegs[id: [peg.row+1, peg.col]],   // down+left
      pegs[id: [peg.row+1, peg.col+1]], // down+right
    ].compactMap { $0 })
  }
}

// MARK: - SwiftUI

struct NewGameView: View {
  let store: StoreOf<NewGame>
  
  private var gameInfo: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text("Seconds")
            .bold()
            .frame(width: 70, alignment: .leading)
            .padding()
            .background { Color(.systemGray5) }
          Text(viewStore.secondsElapsed.description)
        }
        Divider()
        HStack {
          Text("Score")
            .bold()
            .frame(width: 70, alignment: .leading)
            .padding()
            .background { Color(.systemGray5) }
          Text(viewStore.score.description)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .background { Color(.systemGray6) }
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
  }
  
  var body: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
      NavigationStack {
        VStack {
          gameInfo
          
          Spacer()
          
          MoveView(store: store.scope(
            state: \.move,
            action: { .move($0) }
          ))
          .disabled(viewStore.isPaused)
          .padding()
          
          Spacer()
          
          Button(viewStore.isPaused ? "Play" : "Pause") {
            viewStore.send(.pauseButtonTapped)
          }
          .disabled(viewStore.previousMoves.isEmpty)
          
          HStack {
            Button(action: { viewStore.send(.undoButtonTapped, animation: .default) }) {
              Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(viewStore.isUndoButtonDisabled)
            Spacer()
            Button(action: { viewStore.send(.redoButtonTapped) }) {
              Label("Redo", systemImage: "arrow.uturn.forward")
            }
            .disabled(viewStore.isRedoButtonDisabled)
          }
          .buttonStyle(.bordered)
          .frame(width: 200)
          .padding()
          .disabled(viewStore.isPaused)
        }
        .padding()
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
      }
    }
  }
}

struct MoveView: View {
  let store: StoreOf<Move>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        ForEach(0..<5) { row in
          HStack {
            ForEach(0..<row+1) { col in
              pegView(peg: viewStore.pegs[id: [row, col]]!)
            }
          }
        }
      }
    }
  }
  
  private func pegView(peg: Peg) -> some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Button(action: { viewStore.send(.move(peg)) }) {
        Circle()
          .foregroundColor(Color(.systemGray))
          .frame(width: 50, height: 50)
          .overlay {
            if viewStore.selection == peg {
              Circle().foregroundColor(.accentColor)
            }
          }
          .overlay {
            if viewStore.state.pegs(acrossFrom: viewStore.selection).contains(peg) {
              Circle().foregroundColor(.blue)
            }
            if viewStore.state.pegs(adjacentTo: viewStore.selection).contains(peg) {
              Circle().foregroundColor(.orange)
            }
          }
          .opacity(!peg.isEmpty ? 1 : 0.25)
      }
      .buttonStyle(.plain)
      .animation(.default, value: viewStore.selection)
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  NewGameView(store: Store(
    initialState: NewGame.State(),
    reducer: NewGame.init
  ))
}
