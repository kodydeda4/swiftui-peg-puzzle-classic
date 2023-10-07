import SwiftUI
import ComposableArchitecture

// 1. how do you calculate available moves?
// 3. how do you know when it's done?

struct NewGame: Reducer {
  struct State: Equatable {
    var currentMove = Move.State()
    var previousMoves = [Move.State]()
    var score = 0
    var secondsElapsed = 0
    var isTimerEnabled = false
  }
  enum Action: Equatable {
    case view(View)
    case currentMove(Move.Action)
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
    Scope(state: \.currentMove, action: /Action.currentMove) {
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
            state.currentMove = prev
          } else {
            state.currentMove = .init()
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
        
      case let .currentMove(action):
        switch action {
        case .delegate(.didComplete):
          state.previousMoves.append(state.currentMove)
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
            await send(.timerTicked)
            //await send(.timerTicked, animation: .interpolatingSpring(stiffness: 3000, damping: 40))
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
    previousMoves.isEmpty || isPaused
  }
  var isRedoButtonDisabled: Bool {
    isPaused
  }
  var total: Int {
    (currentMove.pegs.count - 1) * 150
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
      
      // handle hopping from: start -> middle -> end
      guard
        let start = state.selection,
        let middle = state.peg(between: start, and: selection),
        let end = Optional(selection),
        !middle.isRemoved,
        end.isRemoved,
        state.pegs(acrossFrom: start).contains(end)
      else { return .none }
      
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

extension Move.State {
  var isFirstMove: Bool {
    pegs.filter(\.isRemoved).isEmpty
  }
  func peg(between a: Peg, and b: Peg) -> Peg? {
    let row: Int? = {
      let diff = a.row - b.row
      switch diff {
      case 0 : return a.row
      case +2: return -1 + a.row
      case -2: return +1 + a.row
      default: return nil
      }
    }()
    let col: Int? = {
      let diff = a.col - b.col
      switch diff {
      case 0 : return a.col
      case +2: return -1 + a.col
      case -2: return +1 + a.col
      default: return nil
      }
    }()
    guard let row = row, let col = col else { return nil }
    return pegs[id: [row,col]]
  }
  func pegs(acrossFrom peg: Peg?) -> IdentifiedArrayOf<Peg> {
    guard let peg = peg else { return [] }
    
    return .init(uniqueElements: [
      pegs[id: [peg.row+0, peg.col-2]], // left
      pegs[id: [peg.row-2, peg.col-2]], // left+up
      pegs[id: [peg.row+2, peg.col]],   // left+down
      //-------------------------------------------------------
      pegs[id: [peg.row+0, peg.col+2]], // right
      pegs[id: [peg.row-2, peg.col+0]], // right+up
      pegs[id: [peg.row+2, peg.col+2]], // right+down
    ]
      .compactMap { $0 })
  }
  func pegs(adjacentTo peg: Peg?) -> IdentifiedArrayOf<Peg> {
    guard let peg = peg else { return [] }
    
    return .init(uniqueElements: [
      pegs[id: [peg.row+0, peg.col-1]], // left
      pegs[id: [peg.row-1, peg.col-1]], // left+up
      pegs[id: [peg.row+1, peg.col]],   // left+down
      //-------------------------------------------------------
      pegs[id: [peg.row+0, peg.col+1]], // right
      pegs[id: [peg.row-1, peg.col+0]], // right+up
      pegs[id: [peg.row+1, peg.col+1]], // right+down
    ].compactMap { $0 })
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
          
          MoveView(store: store.scope(
            state: \.currentMove,
            action: { .currentMove($0) }
          ))
          .disabled(viewStore.isPaused)
          .padding()
          
          Spacer()
          
          footer
        }
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
                total: CGFloat(viewStore.total)
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
            .disabled(viewStore.previousMoves.isEmpty)
            
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
          }
          .opacity(!peg.isRemoved ? 1 : 0.25)
          .overlay {
            Text("\(peg.row), \(peg.col)").foregroundColor(.primary)
          }
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
