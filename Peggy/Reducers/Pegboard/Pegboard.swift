import ComposableArchitecture
import SwiftUI

@Reducer
struct Pegboard {
  @ObservableState
  struct State: Equatable {
    var pegs = makePegs()
    var selection: Peg?
  }
  enum Action: ViewAction {
    case view(View)
    case delegate(Delegate)
    
    enum View {
      case move(Peg)
    }
    enum Delegate {
      case didComplete
    }
  }
  
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
      
    case let .view(.move(selection)):
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      
      if state.isFirstMove {
        state.pegs[id: selection.id]?.isRemoved = true
        state.selection = nil
        return .send(.delegate(.didComplete))
      }
      if state.selection == nil {
        state.selection = selection
        return .none
      }
      if state.selection == selection  {
        state.selection = nil
        return .none
      }
      
      // hopping from: start -> middle -> end
      guard
        let start = state.selection,
        let middle = state.peg(between: start, and: selection),
        let end = Optional(selection),
        !start.isRemoved,
        !middle.isRemoved,
        end.isRemoved,
        state.pegs(acrossFrom: start).contains(end)
      else {
        state.selection = nil
        return .none
      }
      
      state.pegs[id: start.id]?.isRemoved = true
      state.pegs[id: middle.id]?.isRemoved = true
      state.pegs[id: end.id]?.isRemoved = false
      state.selection = nil
      return .send(.delegate(.didComplete))
      
    case .delegate:
      return .none
    }
  }
}


// MARK: - SwiftUI

@ViewAction(for: Pegboard.self)
struct PegboardView: View {
  @Bindable var store: StoreOf<Pegboard>
  
  var body: some View {
    VStack {
      ForEach(0..<store.pegs.last!.row+1, id: \.self) { row in
        HStack {
          ForEach(0..<row+1, id: \.self) { col in
            pegView(peg: store.pegs[id: [row, col]]!)
          }
        }
      }
    }
  }
  
  private func pegView(peg: Peg) -> some View {
    Button(action: { send(.move(peg)) }) {
      Circle()
        .foregroundColor(
          store.selection == peg ? .accentColor : Color(.systemGray)
        )
        .frame(width: 50, height: 50)
        .opacity(!peg.isRemoved ? 1 : 0.25)
        .transition(.scale)
    }
    .buttonStyle(.plain)
    .animation(.default, value: store.selection)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  PegboardView(store: Store(initialState: Pegboard.State()) {
    Pegboard()
  })
}
