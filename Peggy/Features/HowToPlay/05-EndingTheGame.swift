import SwiftUI
import ComposableArchitecture

@Reducer
struct EndingTheGame {
  
  @ObservableState
  struct State: Equatable {
    //...
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(Delegate)
    
    enum Delegate {
      case `continue`
    }
    enum View {
      case continueButtonTapped
    }
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
        
      case .delegate:
        return .none
        
      case let .view(action):
        switch action {
          
        case .continueButtonTapped:
          return .send(.delegate(.continue))
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
        Image(systemName: "flag.pattern.checkered")
          .resizable()
          .scaledToFit()
          .foregroundColor(Color(.darkGray))
          .frame(width: 200, height: 200)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background { Color(.systemGray6) }

      HowToPlayWrapperView(
        title: "When the Game Ends",
        subtitle: "The game ends when no more valid moves are left. Fewer pegs = better score!"
      )
    }
    .howToPlayDefaultViewModifiers()
    .navigationOverlay {
      Button("Continue") {
        send(.continueButtonTapped)
      }
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

