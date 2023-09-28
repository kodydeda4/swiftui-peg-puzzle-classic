import SwiftUI
import ComposableArchitecture


// 1. how do you calculate available moves?
// 2. how do you undo moves?
// 3. how do you know when it's done?
// 6. timer?

struct AppReducer: Reducer {
  struct State: Equatable {
    @BindingState var pegs = Peg.grid()
    @BindingState var selection: Peg? = nil
  }
  enum Action: BindableAction, Equatable {
    case pegTapped(Peg)
    case restartButtonTapped
    case binding(BindingAction<State>)
  }
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        
      case let .pegTapped(value):
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        
        guard !state.isFirstMove else {
          state.pegs[id: value.id]?.completed = true
          state.selection = nil
          return .none
        }
        guard state.selection != value else {
          state.selection = nil
          return .none
        }
        guard let selection = state.selection else {
          state.selection = state.selection != value ? value : nil
          return .none
        }
        guard state.availableMoves.contains(value) else {
          state.selection = value
          return .none
        }
        //        let middlePeg = state.pegs[id: [
        //          -1/2 * (selection.row - value.row),
        //          -1/2 * (selection.col - value.col)
        //        ]]!
        
        
        let middlePeg = state.pegs[id: [
          (selection.row - value.row) == 0 ? selection.row : {
            switch (selection.row - value.row) {
            case +2: return -1 + selection.row
            case -2: return +1 + selection.row
            default: fatalError()
            }
          }(),
          (selection.col - value.col) == 0 ? selection.col : {
            switch (selection.col - value.col) {
            case +2: return -1 + selection.col
            case -2: return +1 + selection.col
            default: fatalError()
            }
          }()
        ]]!
        
        guard !middlePeg.completed else {
          return .none
        }
        
        state.pegs[id: middlePeg.id]?.completed = true
        state.pegs[id: selection.id]?.completed = true
        state.pegs[id: value.id]?.completed = false
        
        //state.moves.append(direction)
        state.selection = nil
        return .none
        
      case .restartButtonTapped:
        state.selection = nil
        state.pegs = Peg.grid()
        return .none
        
      case .binding:
        return .none
        
      }
    }
  }
}

struct Peg: Identifiable, Equatable {
  var id: [Int] { [row, col] }
  let row: Int
  let col: Int
  var completed = false

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
}

extension AppReducer.State {
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

// MARK: - SwiftUI

struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        VStack {
          ForEach(0..<5) { row in
            HStack {
              ForEach(0..<row+1) { col in
                pegView(peg: viewStore.pegs[id: [row, col]]!)
              }
            }
          }
        }
        .navigationTitle("Peg Game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {}) {
              VStack {
                HStack {
                  Text("Undo")
                  Image(systemName: "arrow.uturn.backward")
                }
              }
            }
            .disabled(true)
            .buttonStyle(.bordered)
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
}

private extension AppView {
  private func pegView(peg: Peg) -> some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Button(action: { viewStore.send(.pegTapped(peg)) }) {
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

#Preview {
  AppView(store: Store(
    initialState: AppReducer.State(),
    reducer: AppReducer.init
  ))
}
