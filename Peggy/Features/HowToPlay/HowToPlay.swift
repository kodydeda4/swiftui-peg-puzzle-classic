import SwiftUI
import ComposableArchitecture

@Reducer
struct HowToPlay {
  
  @Reducer(state: .equatable)
  enum Path {
    case screenA(ScreenA)
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
        
      case .path(.element(id: _, action: .screenA(.view(.finishButtonTapped)))):
        return .run { _ in await self.dismiss() }
        
      case .path:
        return .none

      case let .view(action):
        switch action {
          
        case .continueButtonTapped:
          state.path.append(.screenA(ScreenA.State()))
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
        Button("Continue") {
          send(.continueButtonTapped)
        }
        Button("Cancel") {
          send(.cancelButtonTapped)
        }
      }
      .navigationTitle("How to Play")
      .navigationBarTitleDisplayMode(.inline)
    } destination: { store in
      switch store.case {
        
      case let .screenA(store):
        ScreenAView(store: store)
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

