import SwiftUI
import ComposableArchitecture

struct AppReducer: Reducer {
  struct State: Equatable {
    @PresentationState var destination: Destination.State?
  }
  
  enum Action: Equatable {
    case view(View)
    case destination(PresentationAction<Destination.Action>)
    
    enum View: BindableAction, Equatable {
      case newGameButtonTapped
      case binding(BindingAction<State>)
    }
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer(action: /Action.view)
    Reduce { state, action in
      switch action {
        
      case let .view(action):
        switch action {
        
        case .newGameButtonTapped:
          state.destination = .newGame()
          return .none
          
        case .binding:
          return .none
        }
        
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
      case newGame(NewGame.State = .init())
    }
    enum Action: Equatable {
      case newGame(NewGame.Action)
    }
    var body: some ReducerOf<Self> {
      Scope(state: /State.newGame, action: /Action.newGame) {
        NewGame()
      }
    }
  }
}

// MARK: - SwiftUI

struct AppView: View {
  let store: StoreOf<AppReducer>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
      NavigationStack {
        List {
          Button("New Game") {
            viewStore.send(.newGameButtonTapped)
          }
        }
        .fullScreenCover(
          store: store.scope(state: \.$destination, action: AppReducer.Action.destination),
          state: /AppReducer.Destination.State.newGame,
          action: AppReducer.Destination.Action.newGame,
          content: NewGameView.init(store:)
        )
      }
      .navigationTitle("App")
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(store: Store(
    initialState: AppReducer.State(),
    reducer: AppReducer.init
  ))
}
