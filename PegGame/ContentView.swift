import SwiftUI
import ComposableArchitecture

struct AppView: View {
  
  struct Peg: Identifiable, Equatable {
    var id: [Int] { [row, col] }
    let row: Int
    let col: Int
    var done = false
  }
  
  @State var pegs = IdentifiedArrayOf<Peg>(uniqueElements: (0..<5).map { row in (0..<row+1).map { Peg(row: row, col: $0) } }.flatMap { $0 })
  @State var selection: Peg? = nil
  
  private func isSelectable(_ peg: Peg) -> Bool {
    guard let selection = selection else { return true }
    return [
      pegs[id: [selection.row+2, selection.col]],
      pegs[id: [selection.row-2, selection.col]],
      pegs[id: [selection.row, selection.col+2]],
      pegs[id: [selection.row, selection.col-2]],
    ]
      .compactMap { $0 }
      .contains(peg)
  }
  
  
  
  private func pegView(peg: Peg) -> some View {
    Button(action: {
      if let s = selection {
        pegs[id: [s.row - 1, s.col - 1]]?.done.toggle()
        selection = nil
      } else {
        selection = selection != peg ? peg : nil
      }
    }) {
      Circle()
        .frame(width: 50, height: 50)
        .foregroundColor(selection == peg ? .accentColor : peg.done ? Color.red.opacity(0.5) : .primary)
        .opacity(selection == nil || selection == peg ? 1 : 0.5)
        .opacity(isSelectable(peg) ? 1 : 0.5)
    }
    .buttonStyle(.plain)
    .animation(.default, value: selection)
  }
  
  var body: some View {
    NavigationStack {
      VStack {
        ForEach(0..<5) { row in
          HStack {
            ForEach(0..<row+1) { col in
              pegView(peg: pegs[id: [row, col]]!)
            }
          }
        }
      }
      .navigationTitle("Peg Game")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

#Preview {
  AppView()
}
