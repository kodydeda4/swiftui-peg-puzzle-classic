import SwiftUI
import ComposableArchitecture

@Reducer
struct HowToPlay {
  
  @Reducer(state: .equatable)
  enum Path {
//    # 📄 Page 1: Welcome (self)
    case whatsTheGoal(WhatsTheGoal)
//    # 📄 Page 3: How to Jump
//    # 📄 Page 4: Valid Moves
//    # 📄 Page 5: Ending the Game
//    # 📄 Page 6: Quick Tips
    case readyToPlay(ReadyToPlay)
  }
  
  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
  }
  
  public enum Action: ViewAction {
    case view(View)
    case path(StackActionOf<Path>)
    
    enum View {
      case continueButtonTapped
      case cancelButtonTapped
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .path(.element(id: _, action: .readyToPlay(.view(.finishButtonTapped)))):
        return .run { _ in await self.dismiss() }
        
      case .path:
        return .none

      case let .view(action):
        switch action {
          
        case .continueButtonTapped:
          state.path.append(.readyToPlay(ReadyToPlay.State()))
//          state.path.append(.readyToPlay(ReadyToPlay.State()))
          return .none
          
        case .cancelButtonTapped:
          return .run { _ in await self.dismiss() }
        }
      }
    }
    .forEach(\.path, action: \.path)
  }
}

// MARK: - SwiftUI

@ViewAction(for: HowToPlay.self)
struct HowToPlayView: View {
  @Bindable var store: StoreOf<HowToPlay>
  
  var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path)
    ) {
      VStack {
        Text("Welcome to the Peg Game!")
          .bold()
        Text("Learn the classic brain teaser — and become a Peg Game master!")
        
        Button("Continue") {
          send(.continueButtonTapped)
        }
      }
      .navigationTitle("How to Play")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        Button(action: { send(.cancelButtonTapped) }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(Color(.systemGray2))
        }
      }
    } destination: { store in
      switch store.case {
        
      case let .whatsTheGoal(store: store):
        WhatsTheGoalView(store: store)
        
      case let .readyToPlay(store):
        ReadyToPlayView(store: store)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  NavigationStack {
    HowToPlayView(store: Store(initialState: HowToPlay.State()) {
      HowToPlay()
    })
  }
}

