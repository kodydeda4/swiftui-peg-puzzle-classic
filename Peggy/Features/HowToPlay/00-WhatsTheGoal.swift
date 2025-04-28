import SwiftUI
import ComposableArchitecture

@Reducer
struct WhatsTheGoal {
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

@ViewAction(for: WhatsTheGoal.self)
struct WhatsTheGoalView: View {
  @Bindable var store: StoreOf<WhatsTheGoal>
  
  var body: some View {
    VStack {
      Text("What's the Goal?")
        .bold()
      Text("Jump pegs over each other and remove them — try to leave only one peg on the board.")
      
      Button("Continue") {
        send(.continueButtonTapped)
      }
    }
    .navigationTitle("How to Play")
    .navigationBarTitleDisplayMode(.inline)
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

