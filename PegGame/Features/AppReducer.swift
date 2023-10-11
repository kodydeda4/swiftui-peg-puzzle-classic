import SwiftUI
import ComposableArchitecture

struct AppReducer: Reducer {
  struct State: Equatable {
    @PresentationState var destination: Destination.State?
  }
  
  enum Action: Equatable {
    case view(View)
    case destination(PresentationAction<Destination.Action>)
    
    enum View: BindableAction, Equatable {
      case newGameButtonTapped
      case binding(BindingAction<State>)
    }
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer(action: /Action.view)
    Reduce { state, action in
      switch action {
        
      case let .view(action):
        switch action {
        
        case .newGameButtonTapped:
          state.destination = .newGame()
          return .none
          
        case .binding:
          return .none
        }
        
      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: /Action.destination) {
      Destination()
    }
  }
  
  struct Destination: Reducer {
    enum State: Equatable {
      case newGame(Game.State = .init())
    }
    enum Action: Equatable {
      case newGame(Game.Action)
    }
    var body: some ReducerOf<Self> {
      Scope(state: /State.newGame, action: /Action.newGame) {
        Game()
      }
    }
  }
}

// MARK: - SwiftUI

struct AppView: View {
  let store: StoreOf<AppReducer>
  
  //let columns = [GridItem(.flexible()), GridItem(.flexible())]

  var body: some View {
    WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
      NavigationStack {
        VStack {
          VStack {
            HStack {
              Image(systemName: "leaf")
                .resizable()
                .scaledToFit()
                .foregroundColor(.accentColor)
                .padding(8)
                .frame(width: 50, height: 50)
                .background { Color.white }
                .mask { Image(systemName: "app.fill").resizable().scaledToFit() }
                .shadow(color: Color.accentColor.opacity(0.25), radius: 8, y: 2)
                .padding(.trailing, 4)
              
              Text("Peggy")
            }
            .font(.title)
            .fontWeight(.bold)
          }
          .frame(height: 100)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color.accentColor.gradient.opacity(0.15))
          .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder()
              .foregroundColor(.accentColor)
          }
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .frame(height: 100)
          .padding(.bottom)
          
          VStack {
            Button("Play") {
              viewStore.send(.newGameButtonTapped)
            }
            .buttonStyle(RoundedRectangleButtonStyle())
            
            Button("Settings") {
              //
            }
            .buttonStyle(RoundedRectangleButtonStyle(
              foregroundColor: .secondary,
              backgroundColor: Color(.systemGray5)
            ))
          }
          .frame(width: 250)
          
          Spacer()
        }
        .padding()
        .navigationTitle("___")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(
          store: store.scope(state: \.$destination, action: AppReducer.Action.destination),
          state: /AppReducer.Destination.State.newGame,
          action: AppReducer.Destination.Action.newGame,
          content: NewGameView.init(store:)
        )
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(store: Store(
    initialState: AppReducer.State(),
    reducer: AppReducer.init
  ))
}
