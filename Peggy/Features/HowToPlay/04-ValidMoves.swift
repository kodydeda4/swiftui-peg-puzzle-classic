import SwiftUI
import ComposableArchitecture

@Reducer
struct ValidMoves {
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

@ViewAction(for: ValidMoves.self)
struct ValidMovesView: View {
  @Bindable var store: StoreOf<ValidMoves>
  
  var body: some View {
    VStack(spacing: 0) {
      VStack {
        Color.blue
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      HowToPlayWrapperView(
        title: "Valid Moves Only",
        subtitle: "You can only jump horizontally or vertically — never diagonally."
      )
    }
    .howToPlayDefaultViewModifiers()
    .navigationOverlay {
      NavigationLink(
        "Continue",
        state: HowToPlay.Path.State.page5(EndingTheGame.State())
      )
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

