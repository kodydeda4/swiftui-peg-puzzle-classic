import SwiftUI
import ComposableArchitecture

@Reducer
struct GameOver {
  @ObservableState
  struct State: Equatable {
    let score: Int
    let maxScore: Int
    let secondsElapsed: Int
  }
  
  enum Action: ViewAction {
    case view(View)
    
    enum View {
      case doneButtonTapped
      case newGameButtonTapped
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .view(action):
        switch action {
          
        case .doneButtonTapped:
          return .run { _ in await self.dismiss() }
          
        case .newGameButtonTapped:
          return .run { _ in await self.dismiss() }
        }
      }
    }
  }
}

// MARK: - SwiftUI

@ViewAction(for: GameOver.self)
struct GameOverSheet: View {
  @Bindable var store: StoreOf<GameOver>
  
  var body: some View {
    NavigationStack {
      Form {
        Section("Results") {
          HStack {
            Text("🎉 Score").bold()
            Text("\(store.score) / \(store.maxScore)")
          }
          HStack {
            Text("⏰ Time").bold()
            Text("\(store.secondsElapsed)s")
          }
        }
      }
      .navigationTitle("Game Over")
      .navigationBarTitleDisplayMode(.inline)
      .navigationOverlay {
        Button("New Game") {
          send(.newGameButtonTapped)
        }
        .buttonStyle(RoundedRectangleButtonStyle())
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Done") {
            send(.doneButtonTapped)
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
      )
    ) {
      GameOver()
    })
  }
}

