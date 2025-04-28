import SwiftUI
import NavigationTransitions
import ComposableArchitecture

@Reducer
struct HowToPlay {

  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
    var welcome = Welcome.State()
    var path = StackState<Path.State>()
    @Shared(.hasCompletedHowToPlay) var hasCompletedHowToPlay
  }
  
  public enum Action: ViewAction {
    case view(View)
    case welcome(Welcome.Action)
    case path(StackActionOf<Path>)
    case destination(PresentationAction<Destination.Action>)
    
    enum View {
      case skipButtonTapped
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Scope(state: \.welcome, action: \.welcome) {
      Welcome()
    }
    Reduce { state, action in
      switch action {
        
      case let .destination(.presented(.skipTutorialAlert(action))):
        switch action {
          
        case .confirm:
          state.$hasCompletedHowToPlay.withLock { $0 = true }
          return .run { _ in await self.dismiss() }
          
        case .cancel:
          state.destination = .none
          return .none
        }
        
      case .welcome, .path, .destination:
        return .none

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
    .forEach(\.path, action: \.path)
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
  enum Path {
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
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path),
      root: self.root,
      destination: self.destination(store:)
    )
    .navigationTransition(.fade(.in).animation(.none))
    .alert(store: self.store.scope(
      state: \.$destination.skipTutorialAlert,
      action: \.destination.skipTutorialAlert
    ))
  }
  
  private func root() -> some View {
    WelcomeView(store: store.scope(
      state: \.welcome,
      action: \.welcome
    ))
    .toolbar(content: self.toolbar)
  }
  
  private func destination(
    store: StoreOf<HowToPlay.Path>
  ) -> some View {
    Group {
      switch store.case {
        
      case let .page2(store: store):
        WhatsTheGoalView(store: store)

      case let .page3(store: store):
        HowToJumpView(store: store)

      case let .page4(store: store):
        ValidMovesView(store: store)

      case let .page5(store: store):
        EndingTheGameView(store: store)

      case let .page6(store: store):
        QuickTipsView(store: store)

      case let .page7(store):
        ReadyToPlayView(store: store)
      }
    }
    .toolbar(content: self.toolbar)
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

