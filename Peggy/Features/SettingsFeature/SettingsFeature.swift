import SwiftUI
import ComposableArchitecture

@Reducer
struct SettingsFeature {
  @ObservableState
  struct State: Equatable {
    //    @Shared
  }
  
  enum Action: ViewAction {
    case view(View)
    
    enum View {
      //      case doneButtonTapped
      //      case newGameButtonTapped
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
        
      case let .view(action):
        switch action {
          //...
        }
      }
    }
  }
}
// MARK: - SwiftUI

@ViewAction(for: SettingsFeature.self)
struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>
  
  var body: some View {
    VStack {
      Text("Settings")
      
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  SettingsView(store: Store(initialState: SettingsFeature.State()) {
    SettingsFeature()
  })
}

