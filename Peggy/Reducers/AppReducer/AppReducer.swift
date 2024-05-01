import SwiftUI
import ComposableArchitecture

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
  }
  enum Action: ViewAction {
    case view(View)
    case game(Game.Action)
    case destination(PresentationAction<Destination.Action>)
    
    enum View {
      case playGameButtonTapped
      case howToPlayButtonTapped
    }
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .view(action):
        switch action {
          
        case .playGameButtonTapped:
          state.destination = .game(Game.State())
          return .none
          
        case .howToPlayButtonTapped:
          state.destination = .instructions(Instructions.State())
          return .none
        }
        
      default:
        return .none
        
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
  
  @Reducer(state: .equatable)
  enum Destination {
    case game(Game)
    case instructions(Instructions)
  }
}

// MARK: - SwiftUI

@ViewAction(for: AppReducer.self)
struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>
  
  var body: some View {
    NavigationStack {
      List {
        Button(action: { send(.playGameButtonTapped) }) {
          Text("Play Game")
        }
          Button(action: { send(.howToPlayButtonTapped) }) {
          Text("How to Play")
        }
      }
      .navigationTitle("Home")
      .fullScreenCover(item: $store.scope(
        state: \.destination?.game,
        action: \.destination.game
      )) { store in
        GameFullscreenCover(store: store)
      }
      .sheet(item: $store.scope(
        state: \.destination?.instructions,
        action: \.destination.instructions
      )) { store in
        InstructionsSheet(store: store)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(store: Store(initialState: AppReducer.State()) {
    AppReducer()
  })
}
