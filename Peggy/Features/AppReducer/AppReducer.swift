import SwiftUI
import ComposableArchitecture

// @DEDA You should animate the homescreen && integrate gamechanger.

@Reducer
struct AppReducer {
  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
  }
  public enum Action: ViewAction {
    case view(View)
    case destination(PresentationAction<Destination.Action>)
    
    enum View {
      case playButtonTapped
      case howToPlayButtonTapped
    }
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case .destination:
        return .none
        
      case let .view(action):
        switch action {
          
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
        
        Text("Version 1.0")
          .font(.title2)
          .foregroundStyle(.secondary)
        
        Circle()
          .frame(
            width:  150,
            height: 150
          )
          .padding()
          .foregroundColor(Color(.systemGray5))
        
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
