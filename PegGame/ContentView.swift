import SwiftUI
import ComposableArchitecture

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
        if let s = state.selection {
          //pegs[id: [s.row - 1, s.col - 1]]?.done.toggle()
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
  var options: IdentifiedArrayOf<Peg> {
    guard let selection = selection else { return [] }
    
    return .init(uniqueElements: [
      pegs[id: [selection.row+2, selection.col]],
      pegs[id: [selection.row-2, selection.col]],
      pegs[id: [selection.row, selection.col+2]],
      pegs[id: [selection.row, selection.col-2]],
    ].compactMap { $0 })
  }
}

// MARK: - SwiftUI

struct Peg: Identifiable, Equatable {
  var id: [Int] { [row, col] }
  let row: Int
  let col: Int
  var completed = false
}

// MARK: - SwiftUI Previews

struct AppView: View {
  let store: StoreOf<AppReducer> = Store(
    initialState: AppReducer.State(),
    reducer: AppReducer.init
  )
  
  private func pegView(peg: Peg) -> some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Button(action: { viewStore.send(.pegTapped(peg)) }) {
        Circle()
          .frame(width: 50, height: 50)
          .foregroundColor(viewStore.selection == peg ? .accentColor : peg.completed ? Color.red.opacity(0.5) : .primary)
          .opacity(viewStore.selection == nil || viewStore.selection == peg ? 1 : 0.5)
          .opacity(viewStore.options.isEmpty || viewStore.options.contains(peg) ? 1 : 0.5)
      }
      .buttonStyle(.plain)
      .animation(.default, value: viewStore.selection)
    }
  }
  
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

#Preview {
  AppView()
}
