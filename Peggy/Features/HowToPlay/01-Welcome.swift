import SwiftUI
import ComposableArchitecture

@Reducer
struct Welcome {
  
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

@ViewAction(for: Welcome.self)
struct WelcomeView: View {
  @Bindable var store: StoreOf<Welcome>
  
  var body: some View {
    VStack(spacing: 0) {
      VStack {
        Image(.logo)
          .resizable()
          .scaledToFit()
          .frame(width: 150, height: 150)
          .background {
            Circle()
              .foregroundColor(Color(.systemGray5))
          }
          .padding()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background { Color(.systemGray6) }

      HowToPlayWrapperView(
        title: "Welcome to Peg Puzzle Classic!",
        subtitle: "Learn the classic brain teaser — and become a Peg Puzzle Master!"
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
    WelcomeView(store: Store(initialState: Welcome.State()) {
      Welcome()
    })
  }
}

