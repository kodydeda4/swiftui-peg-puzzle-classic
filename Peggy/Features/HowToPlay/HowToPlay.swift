import SwiftUI
import ComposableArchitecture

@Reducer
struct HowToPlay {
  @ObservableState
  struct State: Equatable {
    //...
  }
  
  public enum Action: ViewAction {
    case view(View)
    
    enum View {
      case cancelButtonTapped
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .view(action):
        switch action {
          
        case .cancelButtonTapped:
          return .run { _ in await self.dismiss() }
        }
      }
    }
  }
}

// MARK: - SwiftUI

@ViewAction(for: HowToPlay.self)
struct HowToPlayView: View {
  @Bindable var store: StoreOf<HowToPlay>
  
  var body: some View {
    Button("Cancel") {
      send(.cancelButtonTapped)
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

