import SwiftUI
import ComposableArchitecture
import Combine

@Reducer
struct AppFeature {
  
  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
    @Shared(.build) var build
    @Shared(.appEvent) var appEvent
    @Shared(.hasCompletedHowToPlay) var hasCompletedHowToPlay
    var path = StackState<Path.State>()
    var cancellables: Set<AnyCancellable> = []
  }
  
  public enum Action: ViewAction {
    case view(View)
    case destination(PresentationAction<Destination.Action>)
    case path(StackActionOf<Path>)
    case appEvent(AppEvent?)
    
    enum View {
      case task
      case playButtonTapped
      case howToPlayButtonTapped
      case settingsButtonTapped
    }
  }
  
  @Dependency(\.build) var build
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .appEvent(.startPlayingButtonTapped):
        state.destination = .game(Game.State())
        state.$appEvent.withLock { $0 = .none }
        return .none
        
      case .destination, .path, .appEvent:
        return .none
        
      case let .view(action):
        switch action {
          
        case .task:
          state.$build.withLock {
            $0 = Build(version: self.build.version())
          }
          if !state.hasCompletedHowToPlay {
            state.destination = .howToPlay(HowToPlay.State())
          }
          return .publisher {
            state.$appEvent.publisher.map(Action.appEvent)
          }
          
        case .playButtonTapped:
          state.destination = .game(Game.State())
          return .none
          
        case .howToPlayButtonTapped:
          state.destination = .howToPlay(HowToPlay.State())
          return .none
          
        case .settingsButtonTapped:
          state.path.append(.settings(SettingsFeature.State()))
          return .none
        }
      }
    }
    .ifLet(\.$destination, action: \.destination)
    .forEach(\.path, action: \.path)
  }
}

extension AppFeature {
  
  @Reducer(state: .equatable)
  enum Path {
    case settings(SettingsFeature)
  }
  
  @Reducer(state: .equatable)
  enum Destination {
    case game(Game)
    case howToPlay(HowToPlay)
  }
}

// MARK: - SwiftUI

@ViewAction(for: AppFeature.self)
struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>
  
  var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path),
      root: self.root,
      destination: self.destination(store:)
    )
  }
  
  private func root() -> some View {
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
      
      Group {
        Button("How To Play") {
          send(.howToPlayButtonTapped)
        }
        Button("Settings") {
          send(.settingsButtonTapped)
        }
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
  
  private func destination(
    store: StoreOf<AppFeature.Path>
  ) -> some View {
    Group {
      switch store.case {
        
      case let .settings(store):
        SettingsView(store: store)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(store: Store(initialState: AppFeature.State()) {
    AppFeature()
  })
}
