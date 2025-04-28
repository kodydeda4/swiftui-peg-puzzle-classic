import SwiftUI
import ComposableArchitecture

@main
struct Main: App {
  
  @MainActor
  static let store = Store(initialState: AppReducer.State()) {
    AppReducer()
      ._printChanges()
  }
  
  init() {
    @Shared(.hasCompletedHowToPlay) var hasCompletedHowToPlay
    $hasCompletedHowToPlay.withLock { $0 = false }
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: Self.store)
    }
  }
}
