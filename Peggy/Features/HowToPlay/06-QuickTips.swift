import SwiftUI
import ComposableArchitecture

@Reducer
struct QuickTips {
  
  @ObservableState
  struct State: Equatable {
    //...
  }

  public enum Action: ViewAction {
    case view(View)
    case delegate(Delegate)
    
    enum Delegate {
      case `continue`
    }
    enum View {
      case continueButtonTapped
    }
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
        
      case .delegate:
        return .none
        
      case let .view(action):
        switch action {
          
        case .continueButtonTapped:
          return .send(.delegate(.continue))
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
    VStack(spacing: 0) {
      VStack {
        Image(systemName: "checkmark.seal.text.page")
          .resizable()
          .scaledToFit()
          .foregroundColor(Color(.darkGray))
          .frame(width: 200, height: 200)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background { Color(.systemGray6) }

      HowToPlayWrapperView(
        title: "Quick Tips for Success",
        subtitle: "Plan ahead! Think two or three moves forward to avoid getting stuck."
      )
    }
    .howToPlayDefaultViewModifiers()
    .navigationOverlay {
      Button("Continue") {
        send(.continueButtonTapped)
      }
      .buttonStyle(RoundedRectangleButtonStyle())
    }
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

