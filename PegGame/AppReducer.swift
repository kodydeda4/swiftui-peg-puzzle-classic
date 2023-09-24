 import SwiftUI
import ComposableArchitecture


// 0. First move removes center pig
// 1. how do you calculate available moves?
// 2. how do you undo moves?
// 3. how do you know when it's done?
// 4. moves are wrong ;/
// 5. you should only be able to go when there's one inbetween.
// 6. timer?

struct AppReducer: Reducer {
  struct State: Equatable {
    @BindingState var pegs = Self.makePegs()
    @BindingState var moves = [String]()
    @BindingState var lastMove: String?
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

        // first move.
        guard !state.pegs.filter(\.completed).isEmpty else {
          state.pegs[id: value.id]?.completed = true
          state.selection = nil
          return .none
        }
        guard state.selection != value else {
          state.selection = nil
          return .none
        }        
        if let selection = state.selection {
          if state.availableMoves.contains(value) {
            let row = selection.row
            let col = selection.col

            let direction: String = {
                   if row == value.row,     col == value.col + 2  { return "Left" }
              else if row == value.row + 2, col == value.col + 2  { return "Left+Up" }
              else if row == value.row - 2, col == value.col      { return "Left+Down" }
              else if row == value.row    , col == value.col - 2  { return "Right" }
              else if row == value.row + 2, col == value.col      { return "Right+Up" }
              else if row == value.row - 2, col == value.col - 2  { return "Right+Down" }
              else { return "" }
            }()
            
            let pegToBeModified: Peg? = {
              switch direction {
              case "Left"       : return state.pegs[id: [row   ,col-1]]
              case "Left+Up"    : return state.pegs[id: [row-1 ,col-1]]
              case "Left+Down"  : return state.pegs[id: [row+1 ,col  ]]
              case "Right"      : return state.pegs[id: [row   ,col+1]]
              case "Right+Up"   : return state.pegs[id: [row-1 ,col  ]]
              case "Right+Down" : return state.pegs[id: [row+1 ,col+1]]
              default:
                return nil
              }
            }()
            
            guard let pegToBeModified = pegToBeModified else { return .none }
            
            guard !pegToBeModified.completed else { return .none }
            
            state.pegs[id: pegToBeModified.id]?.completed = true
            state.pegs[id: selection.id]?.completed = true
            state.pegs[id: value.id]?.completed = false
            state.moves.append(direction)
            state.selection = nil
          } else {
            state.selection = value
          }
        } else {
          state.selection = state.selection != value ? value : nil
        }
        return .none
        
      case .restartButtonTapped:
        state.pegs = State.makePegs()
        return .none
        
      case .binding:
        return .none
        
      }
    }
  }
}

extension AppReducer.State {
  static func makePegs() -> IdentifiedArrayOf<Peg> {
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
          VStack(alignment: .leading) {
            HStack {
              Text("Total:").bold().frame(width: 50, alignment: .leading)
              Text(viewStore.moves.count.description)
            }
            HStack {
              Text("Last:").bold().frame(width: 50, alignment: .leading)
              Text(viewStore.moves.last ?? "n.a.")
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
          
          VStack {
            ForEach(0..<5) { row in
              HStack {
                ForEach(0..<row+1) { col in
                  pegView(peg: viewStore.pegs[id: [row, col]]!)
                }
              }
            }
          }
          Spacer()
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
          ToolbarItem(placement: .navigationBarLeading) {
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
              Circle()
                .foregroundColor(.accentColor)
                //.overlay { Circle().padding() }
            }
          }
          .overlay {
            if viewStore.availableMoves.contains(peg) {
              Circle()
                .foregroundColor(.accentColor)
                .opacity(0.5)
            }
          }
//          .overlay {
//            if viewStore.availableMoves.contains(peg) {
//              Circle().foregroundColor(.accentColor).opacity(0.5)
//            } 891838
//          }
          .opacity(!peg.completed ? 1 : 0.25)
      }
      .buttonStyle(.plain)
      .animation(.default, value: viewStore.selection)
      //.disabled(peg.completed)
    }
  }
}

#Preview {
  AppView()
}
