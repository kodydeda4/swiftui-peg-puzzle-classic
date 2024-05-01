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
        
      }
      .navigationTitle("Instructions")
      .navigationBarTitleDisplayMode(.inline)
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
