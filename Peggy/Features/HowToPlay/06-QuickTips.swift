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
    VStack(spacing: 0) {
      VStack {
        Color.orange
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      HowToPlayWrapperView(
        title: "Quick Tips for Success",
        subtitle: "Plan ahead! Think two or three moves forward to avoid getting stuck."
      )
    }
    .howToPlayDefaultViewModifiers()
    .navigationOverlay {
      NavigationLink(
        "Continue",
        state: HowToPlay.Path.State.page7(ReadyToPlay.State())
      )
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

