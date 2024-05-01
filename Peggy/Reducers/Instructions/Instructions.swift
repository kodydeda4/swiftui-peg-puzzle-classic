import SwiftUI
import ComposableArchitecture

@Reducer
struct Instructions {
  @ObservableState
  struct State: Equatable {
    
  }
  enum Action: ViewAction {
    case view(View)
    
    enum View {
      case dismissButtonTapped
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .view(action):
        switch action {
          
        case .dismissButtonTapped:
          return .run { _ in await self.dismiss() }
          
        }
      }
    }
  }
}

// MARK: - SwiftUI

@ViewAction(for: Instructions.self)
struct InstructionsSheet: View {
  @Bindable var store: StoreOf<Instructions>
  
  var body: some View {
    NavigationStack {
      List {
        Section("1. Getting Started") {
          Text("Tap any peg to remove it and begin the game.")
        }
        .listRowSeparator(.hidden, edges: .bottom)
        
        Section("2. Game Moves") {
          Text("Jump across pegs by tapping over one other into empty spaces until only a single peg remains.")
        }
        .listRowSeparator(.hidden, edges: .bottom)
      }
      .navigationTitle("Instructions")
      .navigationBarTitleDisplayMode(.inline)
      .listStyle(.plain)
      .toolbar {
        Button("Dismiss") {
          send(.dismissButtonTapped)
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  Text("Hello World").sheet(isPresented: .constant(true)) {
    InstructionsSheet(store: Store(initialState: Instructions.State()) {
      Instructions()
    })
  }
}
