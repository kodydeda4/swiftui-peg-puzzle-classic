import SwiftUI
import NavigationTransitions
import ComposableArchitecture

// Note:
// Yes, I know this uses two destinations instead of path.
// I don't want to use NavigationStack because I don't want the animations or gestures.

@Reducer
struct HowToPlay {

  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
    @Presents var destinationPath: DestinationPath.State? = .page1(Welcome.State())
    @Shared(.hasCompletedHowToPlay) var hasCompletedHowToPlay
  }
  
  public enum Action: ViewAction {
    case view(View)
    case destination(PresentationAction<Destination.Action>)
    case destinationPath(PresentationAction<DestinationPath.Action>)
    
    enum View {
      case skipButtonTapped
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .destination(.presented(.skipTutorialAlert(action))):
        switch action {
          
        case .confirm:
          state.destination = .none
          state.$hasCompletedHowToPlay.withLock { $0 = true }
          return .run { _ in await self.dismiss() }
          
        case .cancel:
          state.destination = .none
          return .none
        }
        
      case .destinationPath(.dismiss), .destination(.dismiss):
        return .none
        
      case let .destinationPath(.presented(action)):
        switch action {
          
        case .page1(.delegate(.continue)):
          state.destinationPath = .page2(.init())
          return .none
          
        case .page2(.delegate(.continue)):
          state.destinationPath = .page3(.init())
          return .none
          
        case .page3(.delegate(.continue)):
          state.destinationPath = .page4(.init())
          return .none
          
        case .page4(.delegate(.continue)):
          state.destinationPath = .page5(.init())
          return .none
          
        case .page5(.delegate(.continue)):
          state.destinationPath = .page6(.init())
          return .none
          
        case .page6(.delegate(.continue)):
          state.destinationPath = .page7(.init())
          return .none
          
        case .page7(.delegate(.continue)):
          return .none
          
        default:
          return .none
        }

      case let .view(action):
        switch action {
          
        case .skipButtonTapped:
          switch state.hasCompletedHowToPlay {
            
          case false:
            state.destination = .skipTutorialAlert(.init())
            return .none

          case true:
            return .run { _ in await self.dismiss() }
          }
        }
      }
    }
    .ifLet(\.$destination, action: \.destination)
    .ifLet(\.$destinationPath, action: \.destinationPath)
  }
}

extension HowToPlay {
  
  @Reducer(state: .equatable)
  enum Destination {
    case skipTutorialAlert(AlertState<SkipTutorialAlert>)
    
    @CasePathable
    enum SkipTutorialAlert {
      case confirm
      case cancel
    }
  }
  
  @Reducer(state: .equatable)
  enum DestinationPath {
    case page1(Welcome)
    case page2(WhatsTheGoal)
    case page3(HowToJump)
    case page4(ValidMoves)
    case page5(EndingTheGame)
    case page6(QuickTips)
    case page7(ReadyToPlay)
  }
}

extension AlertState where Action == HowToPlay.Destination.SkipTutorialAlert {
  init() {
    self = Self {
      TextState("Skip Tutorial?")
    } actions: {
      ButtonState(action: .cancel) {
        TextState("No, resume")
      }
      ButtonState(action: .confirm) {
        TextState("Yes, skip")
      }
    } message: {
      TextState("Are you sure you want to skip the tutorial?")
    }
  }
}

// MARK: - SwiftUI

@ViewAction(for: HowToPlay.self)
struct HowToPlayView: View {
  @Bindable var store: StoreOf<HowToPlay>
    
  var body: some View {
    NavigationStack {
      Group {
        switch store.scope(
          state: \.destinationPath,
          action: \.destinationPath.presented
        )?.case {
          
        case let .page1(store):
          WelcomeView(store: store)
          
        case let .page2(store):
          WhatsTheGoalView(store: store)
          
        case let .page3(store):
          HowToJumpView(store: store)
          
        case let .page4(store):
          ValidMovesView(store: store)
          
        case let .page5(store):
          EndingTheGameView(store: store)
          
        case let .page6(store):
          QuickTipsView(store: store)
          
        case let .page7(store):
          ReadyToPlayView(store: store)
          
        case .none:
          fatalError("Can't be none.")
        }
      }
      .alert(store: self.store.scope(
        state: \.$destination.skipTutorialAlert,
        action: \.destination.skipTutorialAlert
      ))
      .toolbar(content: self.toolbar)
    }
  }
  
  private func toolbar() -> some ToolbarContent {
    Group {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Skip") {
          send(.skipButtonTapped)
        }
        .bold()
        .buttonStyle(.plain)
        .foregroundColor(.accentColor)
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

