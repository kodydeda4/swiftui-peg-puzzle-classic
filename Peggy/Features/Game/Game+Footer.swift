import SwiftUI
import ComposableArchitecture

extension GameView {
  var footer: some View {
    VStack(spacing: 0) {
      Divider()
      VStack {
        HStack {
          Text("Seconds")
            .bold()
            .frame(width: 70, alignment: .leading)
            .padding()
            .background { Color(.systemGray5) }
          Text(store.secondsElapsed.description)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { Color(.systemGray6) }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder()
            .foregroundColor(Color(.separator))
        }
        HStack {
          Button(action: { send(.undoButtonTapped) }) {
            ButtonLabel(
              title: "Undo",
              systemImage: "arrow.uturn.backward"
            )
          }
          .disabled(store.isUndoButtonDisabled)
          
          Button(action: { send(.pauseButtonTapped) }) {
            ButtonLabel(
              title: store.isPaused ? "Play" : "Pause",
              systemImage: store.isPaused ? "play" : "pause"
            )
          }
          .disabled(store.isPauseButtonDisabled)
          
          Button(action: { send(.restartButtonTapped) }) {
            ButtonLabel(
              title: "Restart",
              systemImage: ""
            )
          }
          .disabled(store.isRestartButtonDisabled)
        }
        .buttonStyle(.plain)
        .padding(.bottom)
      }
      .padding()
    }
    .background {
      Color(.systemGray)
        .opacity(0.1)
        .ignoresSafeArea(edges: .bottom)
    }
  }
}

private struct ButtonLabel: View {
  let title: String
  let systemImage: String
  
  var body: some View {
    HStack {
      Text(title)
        .bold()
      Image(systemName: systemImage)
    }
    .padding(.horizontal)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity)
    .background { Color(.systemGray5) }
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder()
        .foregroundColor(Color(.separator))
    }
    .frame(width: 120)
  }
}