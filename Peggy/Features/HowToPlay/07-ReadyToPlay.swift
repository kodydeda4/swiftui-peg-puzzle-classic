import SwiftUI
import ComposableArchitecture

@Reducer
struct ReadyToPlay {
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

@ViewAction(for: ReadyToPlay.self)
struct ReadyToPlayView: View {
  @Bindable var store: StoreOf<ReadyToPlay>
  
  var body: some View {
    VStack {
      Text("Ready to Jump In?")
        .bold()
      Text("Let's start your first game!")
      
      Button("Finish") {
        send(.finishButtonTapped)
      }
      .buttonStyle(RoundedRectangleButtonStyle())
    }
    .navigationTitle("How to Play")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  NavigationStack {
    ReadyToPlayView(store: Store(initialState: ReadyToPlay.State()) {
      ReadyToPlay()
    })
  }
}

