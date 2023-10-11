import SwiftUI
import ComposableArchitecture

struct GameOver: Reducer {
  struct State: Equatable {
    
  }
  
  enum Action: Equatable {
    case doneButtonTapped
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .doneButtonTapped:
        return .run { _ in await self.dismiss() }
      }
    }
  }
}

// MARK: - SwiftUI

struct GameOverSheet: View {
  let store: StoreOf<GameOver>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        VStack {
          
        }
        .navigationTitle("Game Over")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("New Game") {
              viewStore.send(.doneButtonTapped)
            }
          }
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  Text("Hello World").sheet(isPresented: .constant(true)) {
    GameOverSheet(store: Store(
      initialState: GameOver.State(),
      reducer: GameOver.init
    ))
  }
}

