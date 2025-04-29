import SwiftUI
import ComposableArchitecture

@Reducer
struct WhatsTheGoal {
  
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

@ViewAction(for: WhatsTheGoal.self)
struct WhatsTheGoalView: View {
  @Bindable var store: StoreOf<WhatsTheGoal>
  
  var body: some View {
    VStack(spacing: 0) {
      VStack {
        Image(systemName: "grid")
          .resizable()
          .scaledToFit()
          .foregroundColor(Color(.darkGray))
          .frame(width: 200, height: 200)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background { Color(.systemGray6) }

      HowToPlayWrapperView(
        title: "What's the Goal?",
        subtitle: "Jump pegs over each other and remove them — try to leave only one peg on the board."
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
    WhatsTheGoalView(store: Store(initialState: WhatsTheGoal.State()) {
      WhatsTheGoal()
    })
  }
}

