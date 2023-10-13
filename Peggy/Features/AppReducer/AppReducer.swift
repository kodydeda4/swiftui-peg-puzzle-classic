import SwiftUI
import ComposableArchitecture

struct AppReducer: Reducer {
  struct State: Equatable {
    var game = Game.State()
  }
  enum Action: Equatable {
    case game(Game.Action)
  }
  var body: some ReducerOf<Self> {
    Scope(state: \.game, action: /Action.game) {
      Game()
    }
  }
}

// MARK: - SwiftUI

struct AppView: View {
  let store: StoreOf<AppReducer>

  var body: some View {
    NavigationStack {
      GameView(store: store.scope(
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
