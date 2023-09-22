import SwiftUI
import ComposableArchitecture

struct AppView: View {
  struct Node: Identifiable, Equatable {
    var id: [Int] { [row, col] }
    let row: Int
    let col: Int
    var done = false
  }
  
  @State var pegs = IdentifiedArrayOf<Node>(uniqueElements: (0..<5).map { row in (0..<row+1).map { Node(row: row, col: $0) } }.flatMap { $0 })
  @State var selection: Node? = nil
  
  private func pegView(peg: Node) -> some View {
    Button(action: { selection = peg }) {
      Circle()
        .frame(width: 30, height: 30)
        .foregroundColor(selection == peg ? .accentColor : .primary)
    }
    .buttonStyle(.plain)
    .animation(.default, value: selection)
  }
  
  var body: some View {
    VStack {
      ForEach(0..<5) { row in
        HStack {
          ForEach(0..<row+1) { col in
            pegView(peg: pegs[id: [row, col]]!)
          }
        }
      }
    }
  }
}

#Preview {
  AppView()
}
