import SwiftUI
import ComposableArchitecture

@Reducer
struct HowToJump {
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

@ViewAction(for: HowToJump.self)
struct HowToJumpView: View {
  @Bindable var store: StoreOf<HowToJump>
  
  var body: some View {
    VStack {
      Text("How to Jump")
        .bold()
      Text("Select a peg, then jump it over a neighboring peg into an empty hole. The peg you jump over is removed.")
      
      NavigationLink(
        "Continue",
        state: HowToPlay.Path.State.page4(ValidMoves.State())
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
    HowToJumpView(store: Store(initialState: HowToJump.State()) {
      HowToJump()
    })
  }
}

