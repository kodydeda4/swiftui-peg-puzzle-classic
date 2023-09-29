import SwiftUI
import ComposableArchitecture

// 1. how do you calculate available moves?
// 3. how do you know when it's done?
// 6. timer?

struct NewGame: Reducer {
  struct State: Equatable {
    var move = Move.State()
    var previousMoves = [Move.State]()
    
    // Comuted
    var isUndoButtonDisabled: Bool { previousMoves.isEmpty }
    var isRedoButtonDisabled: Bool { false }
  }
  enum Action: Equatable {
    case move(Move.Action)
    case cancelButtonTapped
    case undoButtonTapped
    case redoButtonTapped
    case restartButtonTapped
  }
  @Dependency(\.dismiss) var dismiss
  var body: some ReducerOf<Self> {
    Scope(state: \.move, action: /Action.move) {
      Move()
    }
    Reduce { state, action in
      switch action {
        
      case .move(.delegate(.didComplete)):
        state.previousMoves.append(state.move)
        return .none
        
      case .cancelButtonTapped:
        return .run { _ in await self.dismiss() }
        
      case .undoButtonTapped:
        state.previousMoves.removeLast()
        
        if let prev = state.previousMoves.last {
          state.move = prev
        } else {
          state.move = .init()
        }
        return .none
        
      case .redoButtonTapped:
        return .none
        
      case .restartButtonTapped:
        state.move = .init()
        state.previousMoves = .init()
        return .none
        
      case .move:
        return .none
      }
    }
  }
}

struct Move: Reducer {
  struct State: Equatable {
    var pegs = Peg.grid()
    var selection: Peg?
    
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
  enum Action: Equatable {
    case pegButtonTapped(Peg)
    case delegate(Delegate)
    
    enum Delegate: Equatable {
      case didComplete
    }
  }
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
      
    case let .pegButtonTapped(value):
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      
      if state.isFirstMove {
        state.pegs[id: value.id]?.completed = true
        state.selection = nil
        return .send(.delegate(.didComplete))
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
      return .send(.delegate(.didComplete))
      
    case .delegate:
      return .none
    }
  }
}

// MARK: - SwiftUI

struct NewGameView: View {
  let store: StoreOf<NewGame>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        Text("Moves: \(viewStore.previousMoves.count.description)")
        
        MoveView(store: store.scope(
          state: \.move,
          action: { .move($0) }
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
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            viewStore.send(.cancelButtonTapped)
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Restart") {
            viewStore.send(.restartButtonTapped)
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

// MARK: - SwiftUI Previews

#Preview {
  NavigationStack {
    NewGameView(store: Store(
      initialState: NewGame.State(),
      reducer: NewGame.init
    ))
  }
}
