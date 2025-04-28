import SwiftUI
import ComposableArchitecture

@Reducer
struct QuickTips {
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

@ViewAction(for: QuickTips.self)
struct QuickTipsView: View {
  @Bindable var store: StoreOf<QuickTips>
  
  var body: some View {
    VStack {
      Text("Quick Tips for Success")
        .bold()
      Text("Plan ahead! Think two or three moves forward to avoid getting stuck.")
      
      NavigationLink(
        "Continue",
        state: HowToPlay.Path.State.page7(ReadyToPlay.State())
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
    QuickTipsView(store: Store(initialState: QuickTips.State()) {
      QuickTips()
    })
  }
}

