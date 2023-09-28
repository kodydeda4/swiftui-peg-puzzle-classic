import SwiftUI
import ComposableArchitecture

// 1. how do you calculate available moves?
// 2. how do you undo moves?
// 3. how do you know when it's done?
// 6. timer?

struct AppReducer: Reducer {
  struct State: Equatable {
    var game = Game.State()
    var previousGameStates = IdentifiedArrayOf<Game.State>()
    
    var isUndoButtonDisabled: Bool {
      previousGameStates.isEmpty
    }
    var isRedoButtonDisabled: Bool {
      false
    }
  }
  enum Action: Equatable {
    case game(Game.Action)
    case undoButtonTapped
    case redoButtonTapped
    case restartButtonTapped
  }
  var body: some ReducerOf<Self> {
    Scope(state: \.game, action: /Action.game) {
      Game()
    }
    Reduce { state, action in
      switch action {
        
      case .game(.delegate(.didMove)):
        var copy = state.game
        copy.id = .init()
        state.previousGameStates.append(copy)
        return .none
        
      case .undoButtonTapped:
        state.previousGameStates = .init(uniqueElements: state.previousGameStates.dropLast())
        
        if let prev = state.previousGameStates.last {
          state.game = prev
        } else {
          state.game = .init()
        }
        return .none
        
      case .redoButtonTapped:
        return .none
        
      case .restartButtonTapped:
        state = State()
        return .none
        
      case .game:
        return .none
      }
    }
  }
}

struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        VStack {
          Text("Moves: \(viewStore.previousGameStates.count.description)")
          
          GameView(store: store.scope(
            state: \.game,
            action: AppReducer.Action.game
          ))
          
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
        }
        .navigationTitle("Peg Game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Restart") {
              viewStore.send(.restartButtonTapped)
            }
          }
        }
      }
    }
  }
}

// MARK: - Game

struct Game: Reducer {
  struct State: Identifiable, Equatable {
    var id = UUID()
    var pegs = Peg.grid()
    var selection: Peg?
  }
  enum Action: Equatable {
    case pegButtonTapped(Peg)
    case delegate(Delegate)
    
    enum Delegate: Equatable {
      case didMove
    }
  }
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
      
    case let .pegButtonTapped(value):
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      
      if state.isFirstMove {
        state.pegs[id: value.id]?.completed = true
        state.selection = nil
        return .send(.delegate(.didMove))
      }
      guard state.availableMoves.contains(value) else {
        state.selection = value
        return .none
      }
      guard let selection = state.selection else {
        state.selection = state.selection == value ? nil : value
        return .none
      }
      guard !Peg.between(selection, value, in: state.pegs).completed else {
        return .none
      }
      state.pegs[id: Peg.between(selection, value, in: state.pegs).id]?.completed = true
      state.pegs[id: selection.id]?.completed = true
      state.pegs[id: value.id]?.completed = false
      state.selection = nil
      return .send(.delegate(.didMove))
      
    case .delegate:
      return .none
    }
  }
}

extension Game.State {
  var isFirstMove: Bool {
    pegs.filter(\.completed).isEmpty
  }
  var availableMoves: IdentifiedArrayOf<Peg> {
    guard let selection = selection else { return [] }
    
    return .init(uniqueElements: [
      pegs[id: [selection.row+0, selection.col-2]], // left
      pegs[id: [selection.row+0, selection.col+2]], // right
      pegs[id: [selection.row-2, selection.col-2]], // up+left
      pegs[id: [selection.row-2, selection.col+0]], // up+right
      pegs[id: [selection.row+2, selection.col]],   // down+left
      pegs[id: [selection.row+2, selection.col+2]], // down+right
    ]
      .compactMap { $0 }
      .filter { $0.completed }
    )
  }
  var availableForCompletion: IdentifiedArrayOf<Peg> {
    guard let selection = selection else { return [] }
    
    return .init(uniqueElements: [
      pegs[id: [selection.row+0, selection.col-1]], // left
      pegs[id: [selection.row+0, selection.col+1]], // right
      pegs[id: [selection.row-1, selection.col-1]], // up+left
      pegs[id: [selection.row-1, selection.col+0]], // up+right
      pegs[id: [selection.row+1, selection.col]],   // down+left
      pegs[id: [selection.row+1, selection.col+1]], // down+right
    ].compactMap { $0 })
  }
}

struct GameView: View {
  let store: StoreOf<Game>
  
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
      Button(action: { viewStore.send(.pegButtonTapped(peg)) }) {
        Circle()
          .foregroundColor(Color(.systemGray))
          .frame(width: 50, height: 50)
          .overlay {
            if viewStore.selection == peg {
              Circle().foregroundColor(.accentColor)
            }
          }
          .opacity(!peg.completed ? 1 : 0.25)
      }
      .buttonStyle(.plain)
      .animation(.default, value: viewStore.selection)
    }
  }
}

// MARK: - Models

struct Peg: Identifiable, Equatable {
  var id: [Int] { [row, col] }
  let row: Int
  let col: Int
  var completed = false
}

extension Peg {
  static func grid() -> IdentifiedArrayOf<Peg> {
    IdentifiedArrayOf<Peg>(
      uniqueElements: (0..<5).map { row in
        (0..<row+1).map {
          Peg(row: row, col: $0)
        }
      }.flatMap {
        $0
      }
    )
  }
  
  static func between(_ a: Peg, _ b: Peg, in pegs: IdentifiedArrayOf<Peg>) -> Peg {
    pegs[id: [
      (a.row - b.row) == 0 ? a.row : {
        switch (a.row - b.row) {
        case +2: return -1 + a.row
        case -2: return +1 + a.row
        default: fatalError()
        }
      }(),
      (a.col - b.col) == 0 ? a.col : {
        switch (a.col - b.col) {
        case +2: return -1 + a.col
        case -2: return +1 + a.col
        default: fatalError()
        }
      }()
    ]]!
  }
}

extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  subscript (safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

#Preview {
  AppView(store: Store(
    initialState: AppReducer.State(),
    reducer: AppReducer.init
  ))
}
