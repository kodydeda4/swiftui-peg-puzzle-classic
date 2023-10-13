import SwiftUI
import ComposableArchitecture

struct AppReducer: Reducer {
  struct State: Equatable {
    var game = NewGame.State()
  }
  enum Action: Equatable {
    case game(NewGame.Action)
  }
  var body: some ReducerOf<Self> {
    Scope(state: \.game, action: /Action.game) {
      NewGame()
    }
  }
}

// MARK: - SwiftUI

struct AppView: View {
  let store: StoreOf<AppReducer>

  var body: some View {
    NavigationStack {
      NewGameView(store: store.scope(
        state: \.game,
        action: { .game($0) }
      ))
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
