import SwiftUI
import ComposableArchitecture

@Reducer
struct ValidMoves {
  
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

@ViewAction(for: ValidMoves.self)
struct ValidMovesView: View {
  @Bindable var store: StoreOf<ValidMoves>
  
  var body: some View {
    VStack(spacing: 0) {
      VStack {
        Image(systemName: "circle.bottomrighthalf.pattern.checkered")
          .resizable()
          .scaledToFit()
          .foregroundColor(Color(.darkGray))
          .frame(width: 200, height: 200)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background { Color(.systemGray6) }

      HowToPlayWrapperView(
        title: "Valid Moves Only",
        subtitle: "You can only jump horizontally or vertically — never diagonally."
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
    ValidMovesView(store: Store(initialState: ValidMoves.State()) {
      ValidMoves()
    })
  }
}

