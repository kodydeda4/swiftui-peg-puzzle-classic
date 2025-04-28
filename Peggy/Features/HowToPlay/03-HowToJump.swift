import SwiftUI
import ComposableArchitecture

@Reducer
struct HowToJump {
  @ObservableState
  struct State: Equatable {
    var pegboard = Pegboard.State()
  }
  
  public enum Action: ViewAction {
    case view(View)
    case pegboard(Pegboard.Action)
    
    enum View {
      case continueButtonTapped
    }
  }
  
  var body: some Reducer<State, Action> {
    Scope(state: \.pegboard, action: \.pegboard) {
      Pegboard()
    }
    Reduce { state, action in
      switch action {
        
      case .pegboard:
        return .none
        
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

struct HowToPlayWrapperView: View {
  let title: String
  let subtitle: String
  
  var body: some View {
    VStack {
      Text(title)
        .font(.title2)
        .bold()
        .padding(.bottom, 4)
      
      Text(subtitle)
        .foregroundStyle(.secondary)
    }
    .frame(height: 250, alignment: .top)
    .padding(32)
  }
}

extension View {
  func howToPlayDefaultViewModifiers() -> some View {
    self
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .multilineTextAlignment(.center)
      .navigationTitle("How to Play")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden()
  }
}

@ViewAction(for: HowToJump.self)
struct HowToJumpView: View {
  @Bindable var store: StoreOf<HowToJump>
  
  var body: some View {
    VStack(spacing: 0) {
      VStack {
        PegboardView(store: store.scope(state: \.pegboard, action: \.pegboard))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      .padding(.bottom, 32)
      .background {
        LinearGradient(
          colors: [Color(.systemGray5), .clear],
          startPoint: .bottom,
          endPoint: .top
        )
      }
      
      HowToPlayWrapperView(
        title: "How to Jump",
        subtitle: "Select a peg, then jump it over a neighboring peg into an empty hole. The peg you jump over is removed."
      )
    }
    .howToPlayDefaultViewModifiers()
    .navigationOverlay {
      NavigationLink(
        "Continue",
        state: HowToPlay.Path.State.page4(ValidMoves.State())
      )
      .buttonStyle(RoundedRectangleButtonStyle())
    }
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

