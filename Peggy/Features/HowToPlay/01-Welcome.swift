import SwiftUI
import ComposableArchitecture

@Reducer
struct Welcome {
  @ObservableState
  struct State: Equatable {}

  public enum Action: ViewAction {
    case view(View)
    
    enum View {
//      case continueButtonTapped
    }
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
        
      case let .view(action):
        switch action {
          
//        case .continueButtonTapped:
//          return .none
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
    VStack {
      Text("Welcome to Peg Puzzle Classic!")
        .bold()
      Text("Learn the classic brain teaser — and become a Peg Puzzle Master!")
      
      NavigationLink(
        "Continue",
        state: HowToPlay.Path.State.page2(WhatsTheGoal.State())
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
    WelcomeView(store: Store(initialState: Welcome.State()) {
      Welcome()
    })
  }
}

