import SwiftUI
import NavigationTransitions
import ComposableArchitecture

@Reducer
struct HowToPlay {

  @ObservableState
  struct State: Equatable {
    var welcome = Welcome.State()
    var path = StackState<Path.State>()
  }
  
  public enum Action: ViewAction {
    case view(View)
    case welcome(Welcome.Action)
    case path(StackActionOf<Path>)
    
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
        
      case .welcome, .path:
        return .none

      case let .view(action):
        switch action {
          
        case .skipButtonTapped:
          return .run { _ in await self.dismiss() }
        }
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension HowToPlay {
   
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
  }
  
  private func root() -> some View {
    WelcomeView(store: store.scope(
      state: \.welcome,
      action: \.welcome
    ))
    .toolbar(content: self.toolbar)
  }
  
  private func destination(
    store: Store<HowToPlay.Path.State, HowToPlay.Path.Action>
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
        Button {
          send(.skipButtonTapped)
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
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

