import SwiftUI
import ComposableArchitecture

struct Game: Reducer {
  struct State: Equatable {
    var currentMove = Pegboard.State()
    var previousMoves = [Pegboard.State]()
    var score = 0
    var secondsElapsed = 0
    var isTimerEnabled = false
    @PresentationState var destination: Destination.State?
  }
  enum Action: Equatable {
    case view(View)
    case currentMove(Pegboard.Action)
    case destination(PresentationAction<Destination.Action>)
    case toggleIsPaused
    case timerTicked
    case gameOver
    
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
      Pegboard()
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
          if state.currentMove.potentialMoves == 0 {
            return .send(.gameOver)
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
          }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
        
      case .timerTicked:
        state.secondsElapsed += 1
        return .none
        
      case .gameOver:
        state.destination = .gameOver(.init())
        return .send(.toggleIsPaused)
        
      case .destination(.presented(.gameOver(.doneButtonTapped))):
        state = State()
        return .none
        
      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: /Action.destination) {
      Destination()
    }
  }
  
  struct Destination: Reducer {
    enum State: Equatable {
      case gameOver(GameOver.State)
    }
    enum Action: Equatable {
      case gameOver(GameOver.Action)
    }
    var body: some ReducerOf<Self> {
      Scope(state: /State.gameOver, action: /Action.gameOver) {
        GameOver()
      }
    }
  }
}

private extension Game.State {
  var isPaused: Bool {
    !isTimerEnabled && !previousMoves.isEmpty
  }
  var isGameOver: Bool {
    currentMove.potentialMoves == 0
  }
  var isUndoButtonDisabled: Bool {
    isPaused || previousMoves.isEmpty
  }
  var isPauseButtonDisabled: Bool {
    isGameOver || previousMoves.isEmpty
  }
  var isRedoButtonDisabled: Bool {
    isPaused
  }
  var maxScore: Int {
    (currentMove.pegs.count - 1) * 150
  }
}

struct Pegboard: Reducer {
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
      
      // hopping from: start -> middle -> end
      guard
        let start = state.selection,
        let middle = state.getPeg(between: start, and: selection),
        let end = Optional(selection),
        !start.isRemoved,
        !middle.isRemoved,
        end.isRemoved,
        state.getPegs(acrossFrom: start).contains(end)
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
  var isFirstMove: Bool {
    pegs.filter(\.isRemoved).isEmpty
  }
  
  var potentialMoves: Int {
    isFirstMove ? pegs.count : pegs.map(potentialMoves).reduce(0, +)
  }

  enum Direction: CaseIterable {
    case left
    case leftUp
    case leftDown
    case right
    case rightUp
    case rightDown
  }
  
  func getPeg(between a: Peg, and b: Peg) -> Peg? {
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
  
  func getPegs(acrossFrom peg: Peg) -> [Peg] {
    Direction.allCases.compactMap {
      getPeg($0, of: peg, offset: 2)
    }
  }
  
  private func getPeg(_ direction: Direction, of peg: Peg, offset: Int) -> Peg? {
    switch direction {
    case .left: pegs[id: [peg.row, peg.col-offset]]
    case .leftUp: pegs[id: [peg.row-offset, peg.col-offset]]
    case .leftDown: pegs[id: [peg.row+offset, peg.col]]
    case .right: pegs[id: [peg.row, peg.col+offset]]
    case .rightUp: pegs[id: [peg.row-offset, peg.col]]
    case .rightDown: pegs[id: [peg.row+offset, peg.col+offset]]
    }
  }
  
  private func potentialMoves(for peg: Peg) -> Int {
    guard !peg.isRemoved else { return 0 }
    
    return Direction.allCases.map { direction in
      guard
        let adjacent = getPeg(direction, of: peg, offset: 1),
        let across = getPeg(direction, of: peg, offset: 2)
      else { return false }
      return !adjacent.isRemoved && across.isRemoved
    }
    .filter({ $0 == true })
    .count
  }
}

// MARK: - SwiftUI

struct NewGameView: View {
  let store: StoreOf<Game>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
      NavigationStack {
        VStack {
          header
          
          Text("Potential Moves: \(viewStore.currentMove.potentialMoves.description)")
          
          Spacer()
          
          PegboardView(store: store.scope(
            state: \.currentMove,
            action: { .currentMove($0) }
          ))
          .disabled(viewStore.isPaused)
          .padding()
          
          Spacer()
          
          footer
        }
        .disabled(viewStore.isGameOver)
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
        .sheet(
          store: store.scope(
            state: \.$destination,
            action: Game.Action.destination
          ),
          state: /Game.Destination.State.gameOver,
          action: Game.Destination.Action.gameOver,
          content: GameOverSheet.init(store:)
        )
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
                total: CGFloat(viewStore.maxScore)
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
            .disabled(viewStore.isPauseButtonDisabled)
            
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

struct PegboardView: View {
  let store: StoreOf<Pegboard>
  
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
          .opacity(!peg.isRemoved ? 1 : 0.25)
      }
      .buttonStyle(.plain)
      .animation(.default, value: viewStore.selection)
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  NewGameView(store: Store(
    initialState: Game.State(),
    reducer: Game.init
  ))
}
