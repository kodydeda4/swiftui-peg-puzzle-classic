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
              .foregroundColor(Color(.systemGray6))
          }
          .padding()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      
      HowToPlayWrapperView(
        title: "Welcome to Peg Puzzle Classic!",
        subtitle: "Learn the classic brain teaser — and become a Peg Puzzle Master!"
      )
    }
    .howToPlayDefaultViewModifiers()
    .navigationOverlay {
      NavigationLink(
        "Continue",
        state: HowToPlay.Path.State.page2(WhatsTheGoal.State())
      )
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

