import SwiftUI
import ComposableArchitecture

struct GameOver: Reducer {
  struct State: Equatable {
    let score: Int
    let maxScore: Int
    let secondsElapsed: Int
  }
  enum Action: Equatable {
    case doneButtonTapped
    case newGameButtonTapped
  }
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .doneButtonTapped:
        return .run { _ in await self.dismiss() }
        
      case .newGameButtonTapped:
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
        Form {
          Section("Results") {
            HStack {
              Text("🎉 Score").bold()
              Text("\(viewStore.score) / \(viewStore.maxScore)")
            }
            HStack {
              Text("⏰ Time").bold()
              Text("\(viewStore.secondsElapsed)s")
            }
          }
        }
        .navigationTitle("Game Over")
        .navigationBarTitleDisplayMode(.inline)
        .navigationOverlay {
          Button("New Game") {
            viewStore.send(.newGameButtonTapped)
          }
          .buttonStyle(RoundedRectangleButtonStyle())
        }
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Done") {
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
      initialState: GameOver.State(
        score: 150,
        maxScore: 1300,
        secondsElapsed: 10
      ),
      reducer: GameOver.init
    ))
  }
}

