import SwiftUI
import ComposableArchitecture

@Reducer
struct ScreenA {
  @ObservableState
  struct State: Equatable {}

  public enum Action: ViewAction {
    case view(View)
    
    enum View {
      case finishButtonTapped
    }
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
        
      case let .view(action):
        switch action {
          
        case .finishButtonTapped:
          return .none
        }
      }
    }
  }
}

// MARK: - SwiftUI

@ViewAction(for: ScreenA.self)
struct ScreenAView: View {
  @Bindable var store: StoreOf<ScreenA>
  
  var body: some View {
    VStack {
      Text("This is a game")
      
      Button("Finish") {
        send(.finishButtonTapped)
      }
    }
    .navigationTitle("How to Play")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  NavigationStack {
    ScreenAView(store: Store(initialState: ScreenA.State()) {
      ScreenA()
    })
  }
}

