import SwiftUI
import ComposableArchitecture

extension GameView {
  var header: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Text("Score")
          .bold()
          .frame(width: 50, alignment: .leading)
          .frame(maxHeight: .infinity)
          .padding()
          .background { Color.accentColor.opacity(0.15) }
        
        Rectangle()
          .frame(width: 0.25)
          .foregroundColor(.accentColor)
        
        Text(store.score.description)
          .padding(.trailing)
          .foregroundColor(.accentColor)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
          .background {
            ProgressView(
              value: CGFloat(store.score),
              total: CGFloat(store.maxScore)
            )
            .progressViewStyle(ScoreProgressStyle())
            .opacity(0.25)
          }
      }
      .frame(height: 50)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background { Color.accentColor.opacity(0.25) }
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .strokeBorder()
          .foregroundColor(.accentColor)
      }
      .padding()
      
      Divider()
    }
    .background {
      Color(.systemGray)
        .opacity(0.1)
        .ignoresSafeArea(edges: .top)
    }
  }
}

private struct ScoreProgressStyle: ProgressViewStyle {
  func makeBody(configuration: Configuration) -> some View {
    GeometryReader { geometry in
      Rectangle()
        .fill(Color.accentColor)
        .frame(
          maxWidth: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
          maxHeight: .infinity
        )
        .animation(.easeInOut, value: configuration.fractionCompleted)
    }
    .frame(maxHeight: .infinity)
  }
}
