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
    VStack(spacing: 0) {
      VStack {
        Color.red
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      
      HowToPlayWrapperView(
        title: "When the Game Ends",
        subtitle: "The game ends when no more valid moves are left. Fewer pegs = better score!"
      )
    }
    .howToPlayDefaultViewModifiers()
    .navigationOverlay {
      NavigationLink(
        "Continue",
        state: HowToPlay.Path.State.page6(QuickTips.State())
      )
      .buttonStyle(RoundedRectangleButtonStyle())
    }
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

