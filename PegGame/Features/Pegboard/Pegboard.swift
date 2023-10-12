import ComposableArchitecture
import SwiftUI

struct Pegboard: Reducer {
  struct State: Equatable {
    var pegs = makePegs()
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
      
    case let .move(selection):
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

extension Pegboard.State {
  private enum Direction: CaseIterable {
    case left
    case leftUp
    case leftDown
    case right
    case rightUp
    case rightDown
  }  
  
  private static func makePegs() -> IdentifiedArrayOf<Peg> {
    (0..<5).map { row in
      (0..<row+1).map { col in
        Peg(row: row, col: col)
      }
    }
    .flatMap { $0 }
    .identified
  }
  
  var isFirstMove: Bool {
    pegs.filter(\.isRemoved).isEmpty
  }
  
  func peg(between a: Peg, and b: Peg) -> Peg? {
    pegs[id: [a.row+((a.row-b.row) * -1/2), a.col+((a.col-b.col) * -1/2)]]
  }
  
  func pegs(acrossFrom peg: Peg) -> [Peg] {
    Direction.allCases.compactMap {
      self.peg(direction: $0, of: peg, offset: 2)
    }
  }
  
  private func peg(direction: Direction, of peg: Peg, offset: Int) -> Peg? {
    switch direction {
    case .left: pegs[id: [peg.row, peg.col-offset]]
    case .leftUp: pegs[id: [peg.row-offset, peg.col-offset]]
    case .leftDown: pegs[id: [peg.row+offset, peg.col]]
    case .right: pegs[id: [peg.row, peg.col+offset]]
    case .rightUp: pegs[id: [peg.row-offset, peg.col]]
    case .rightDown: pegs[id: [peg.row+offset, peg.col+offset]]
    }
  }
  
  var potentialMoves: Int {
    isFirstMove ? pegs.count : pegs.map(potentialMoves).reduce(0, +)
  }
  
  private func potentialMoves(for peg: Peg) -> Int {
    guard !peg.isRemoved else { return 0 }
    
    return Direction.allCases.map {
      guard
        let adjacent = self.peg(direction: $0, of: peg, offset: 1),
        let across = self.peg(direction: $0, of: peg, offset: 2)
      else { return false }
      return !adjacent.isRemoved && across.isRemoved
    }
    .filter({ $0 == true })
    .count
  }
}

// MARK: - SwiftUI

struct PegboardView: View {
  let store: StoreOf<Pegboard>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        ForEach(0..<viewStore.pegs.last!.row+1) { row in
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
          .foregroundColor(viewStore.selection == peg ? .accentColor : Color(.systemGray))
          .frame(width: 50, height: 50)
          .opacity(!peg.isRemoved ? 1 : 0.25)
          .transition(.scale)
      }
      .buttonStyle(.plain)
      .animation(.default, value: viewStore.selection)
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  PegboardView(store: Store(
    initialState: Pegboard.State(),
    reducer: Pegboard.init
  ))
}
