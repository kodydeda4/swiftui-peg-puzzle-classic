import ComposableArchitecture

extension Pegboard.State {
  enum Direction: CaseIterable {
    case left
    case leftUp
    case leftDown
    case right
    case rightUp
    case rightDown
  }
  
  static func makePegs() -> IdentifiedArrayOf<Peg> {
    (0..<5).map { row in
      (0..<row+1).map { col in
        Peg(row: row, col: col)
      }
    }
    .flatMap { $0 }
    .identified
  }
  
  var isFirstMove: Bool {
    pegs.filter(\.isRemoved).isEmpty
  }
  
  func peg(between a: Peg, and b: Peg) -> Peg? {
    pegs[id: [
      a.row+((a.row-b.row) * -1/2),
      a.col+((a.col-b.col) * -1/2)
    ]]
  }
  
  func pegs(acrossFrom peg: Peg) -> [Peg] {
    Direction.allCases.compactMap {
      self.peg(direction: $0, of: peg, offset: 2)
    }
  }
  
  func peg(direction: Direction, of peg: Peg, offset: Int) -> Peg? {
    switch direction {
    case .left      : pegs[id: [peg.row, peg.col-offset]]
    case .leftUp    : pegs[id: [peg.row-offset, peg.col-offset]]
    case .leftDown  : pegs[id: [peg.row+offset, peg.col]]
    case .right     : pegs[id: [peg.row, peg.col+offset]]
    case .rightUp   : pegs[id: [peg.row-offset, peg.col]]
    case .rightDown : pegs[id: [peg.row+offset, peg.col+offset]]
    }
  }
  
  var potentialMoves: Int {
    isFirstMove ? pegs.count : pegs.map(potentialMoves).reduce(0, +)
  }
  
  func potentialMoves(for peg: Peg) -> Int {
    guard !peg.isRemoved else { return 0 }
    
    return Direction.allCases.map {
      guard
        let adjacent = self.peg(direction: $0, of: peg, offset: 1),
        let across = self.peg(direction: $0, of: peg, offset: 2)
      else { return false }
      return !adjacent.isRemoved && across.isRemoved
    }
    .filter({ $0 == true })
    .count
  }
}
