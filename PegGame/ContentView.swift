import SwiftUI
import ComposableArchitecture

// 1. how do you calculate available moves?
// 2. how do you undo moves?
// 3. how do you know when it's done?

struct AppReducer: Reducer {
  struct State: Equatable {
    @BindingState var pegs = IdentifiedArrayOf<Peg>(
      uniqueElements: (0..<5).map { row in
        (0..<row+1).map {
          Peg(row: row, col: $0)
        }
      }.flatMap {
        $0
      }
    )
    @BindingState var selection: Peg? = nil
  }
  
  enum Action: BindableAction, Equatable {
    case pegTapped(Peg)
    case binding(BindingAction<State>)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      
      case let .pegTapped(value):
        if let selection = state.selection {
//          //pegs[id: [s.row - 1, s.col - 1]]?.done.toggle()
//          state.selection = nil
          state.pegs[id: [
            value.row - 1,
            value.col - selection.col
          ]]?.completed.toggle()
          state.selection = nil
        } else {
          state.selection = state.selection != value ? value : nil
        }
        return .none
        
      case .binding:
        return .none
        
      }
    }
  }
}

extension AppReducer.State {
  var availableForCurrentMove: IdentifiedArrayOf<Peg> {
    guard let selection = selection else { return [] }
    
    return .init(uniqueElements: [
      pegs[id: [selection.row+2, selection.col]],
      pegs[id: [selection.row-2, selection.col]],
      pegs[id: [selection.row, selection.col+2]],
      pegs[id: [selection.row, selection.col-2]],
    ].compactMap { $0 })
  }
  
  var availableForCompletion: IdentifiedArrayOf<Peg> {
    guard let selection = selection else { return [] }
    
    return .init(uniqueElements: [
      pegs[id: [selection.row+1, selection.col]],
      pegs[id: [selection.row-1, selection.col]],
      pegs[id: [selection.row, selection.col+1]],
      pegs[id: [selection.row, selection.col-1]],
    ].compactMap { $0 })
  }
}

struct Peg: Identifiable, Equatable {
  var id: [Int] { [row, col] }
  let row: Int
  let col: Int
  var completed = false
}

// MARK: - SwiftUI

struct AppView: View {
  let store: StoreOf<AppReducer> = Store(
    initialState: AppReducer.State(),
    reducer: AppReducer.init
  )
  
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
          .overlay {
            if viewStore.availableForCurrentMove.contains(peg) {
              Circle().foregroundColor(.accentColor).opacity(0.25)
            }
          }
          .overlay {
            if viewStore.availableForCompletion.contains(peg) {
              Circle().foregroundColor(.pink).opacity(0.25)
            }
          }
          .overlay {
            Text("\(peg.row),\(peg.col)")
          }
          .opacity(!peg.completed ? 1 : 0.25)
      }
      .buttonStyle(.plain)
      .animation(.default, value: viewStore.selection)
    }
  }
}

#Preview {
  AppView()
}
