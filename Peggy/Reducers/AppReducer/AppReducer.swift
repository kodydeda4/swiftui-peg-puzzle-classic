import SwiftUI
import ComposableArchitecture

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    var game = Game.State()
  }
  enum Action {
    case game(Game.Action)
  }
  var body: some ReducerOf<Self> {
    Scope(state: \.game, action: \.game) {
      Game()
    }
  }
}

// MARK: - SwiftUI

struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>

  var body: some View {
    NavigationStack {
      GameView(store: store.scope(
        state: \.game,
        action: \.game
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
