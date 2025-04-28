import SwiftUI
import ComposableArchitecture

@Reducer
struct EndingTheGame {
  @ObservableState
  struct State: Equatable {}

  public enum Action: ViewAction {
    case view(View)
    
    enum View {
      case continueButtonTapped
    }
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
        
      case let .view(action):
        switch action {
          
        case .continueButtonTapped:
          return .none
        }
      }
    }
  }
}

// MARK: - SwiftUI

@ViewAction(for: EndingTheGame.self)
struct EndingTheGameView: View {
  @Bindable var store: StoreOf<EndingTheGame>
  
  var body: some View {
    VStack {
      Text("When the Game Ends")
        .bold()
      Text("The game ends when no more valid moves are left. Fewer pegs = better score!")
      
      NavigationLink(
        "Continue",
        state: HowToPlay.Path.State.page6(QuickTips.State())
      )
      .buttonStyle(RoundedRectangleButtonStyle())
    }
    .navigationTitle("How to Play")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  NavigationStack {
    EndingTheGameView(store: Store(initialState: EndingTheGame.State()) {
      EndingTheGame()
    })
  }
}

