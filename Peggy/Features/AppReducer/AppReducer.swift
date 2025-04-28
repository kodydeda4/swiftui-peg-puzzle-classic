import SwiftUI
import ComposableArchitecture

@Reducer struct AppReducer {
  @ObservableState
  struct State: Equatable {
    @Shared(.build) var build
    @Presents var destination: Destination.State?
  }
  
  public enum Action: ViewAction {
    case view(View)
    case destination(PresentationAction<Destination.Action>)
    
    enum View {
      case task
      case playButtonTapped
      case howToPlayButtonTapped
    }
  }
  
  @Dependency(\.build) var build
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .destination:
        return .none
        
      case let .view(action):
        switch action {
          
        case .task:
          state.$build.withLock {
            $0 = Build(version: build.version())
          }
          return .none
          
        case .playButtonTapped:
          state.destination = .game(Game.State())
          return .none
          
        case .howToPlayButtonTapped:
          state.destination = .howToPlay(HowToPlay.State())
          return .none
          
        }
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
  
  @Reducer(state: .equatable)
  enum Destination {
    case game(Game)
    case howToPlay(HowToPlay)
  }
}

// MARK: - SwiftUI

@ViewAction(for: AppReducer.self)
struct AppView: View {
  @Bindable var store: StoreOf<AppReducer>
  
  var body: some View {
    NavigationStack {
      VStack {
        Text("Peg Puzzle Classic")
          .font(.largeTitle)
          .bold()
          .padding(.top, 64)
        
        Text("Version: \(store.build.version.description)")
          .font(.title2)
          .foregroundStyle(.secondary)
        
        Image(.logo)
          .resizable()
          .scaledToFit()
          .frame(width: 150, height: 150)
          .background {
            Circle()
              .foregroundColor(Color(.systemGray6))
          }
          .padding()

        Button("Play") {
          send(.playButtonTapped)
        }
        .buttonStyle(RoundedRectangleButtonStyle())
        
        Button("How To Play") {
          send(.howToPlayButtonTapped)
        }
        .buttonStyle(RoundedRectangleButtonStyle(
          foregroundColor: .accentColor,
          backgroundColor: Color(.systemGray5)
        ))
      }
      .padding()
      .task { await send(.task).finish() }
      .fullScreenCover(item: $store.scope(
        state: \.destination?.game,
        action: \.destination.game
      )) { store in
        GameView(store: store)
      }
      .fullScreenCover(item: $store.scope(
        state: \.destination?.howToPlay,
        action: \.destination.howToPlay
      )) { store in
        HowToPlayView(store: store)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(store: Store(initialState: AppReducer.State()) {
    AppReducer()
  })
}
