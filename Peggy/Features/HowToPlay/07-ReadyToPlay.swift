import SwiftUI
import ComposableArchitecture

@Reducer
struct ReadyToPlay {
  @ObservableState
  struct State: Equatable {
    @Shared(.appEvent) var appEvent
  }
  
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
          state.$appEvent.withLock {
            $0 = .startPlayingButtonTapped
          }
          return .none
        }
      }
    }
  }
}

extension SharedReaderKey where Self == InMemoryKey<AppEvent?>.Default {
  static var appEvent: Self {
    Self[.inMemory("appEvent"), default: .none]
  }
}

enum AppEvent {
  case startPlayingButtonTapped
}


// MARK: - SwiftUI

@ViewAction(for: ReadyToPlay.self)
struct ReadyToPlayView: View {
  @Bindable var store: StoreOf<ReadyToPlay>
  
  var body: some View {
    VStack(spacing: 0) {
      VStack {
        Image(systemName: "calendar.badge.checkmark")
          .resizable()
          .scaledToFit()
          .foregroundColor(Color(.darkGray))
          .frame(width: 200, height: 200)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background { Color(.systemGray6) }

      HowToPlayWrapperView(
        title: "Ready to Jump In",
        subtitle: "Let's start your first game!"
      )
    }
    .howToPlayDefaultViewModifiers()
    .navigationOverlay {
      Button("Finish") {
        send(.finishButtonTapped)
      }
      .buttonStyle(RoundedRectangleButtonStyle())
    }
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

