import Foundation
import IdentifiedCollections

struct Peg: Identifiable, Equatable {
  var id: [Int] { [row, col] }
  let row: Int
  let col: Int
  var completed = false
}

extension Peg {
  static func grid() -> IdentifiedArrayOf<Peg> {
    IdentifiedArrayOf<Peg>(
      uniqueElements: (0..<5).map { row in
        (0..<row+1).map {
          Peg(row: row, col: $0)
        }
      }.flatMap {
        $0
      }
    )
  }
  
  static func between(_ a: Peg, _ b: Peg, in pegs: IdentifiedArrayOf<Peg>) -> Peg {
    pegs[id: [
      (a.row - b.row) == 0 ? a.row : {
        switch (a.row - b.row) {
        case +2: return -1 + a.row
        case -2: return +1 + a.row
        default: fatalError()
        }
      }(),
      (a.col - b.col) == 0 ? a.col : {
        switch (a.col - b.col) {
        case +2: return -1 + a.col
        case -2: return +1 + a.col
        default: fatalError()
        }
      }()
    ]]!
  }
}
