import Foundation
import IdentifiedCollections

struct Peg: Identifiable, Equatable {
  var id: [Int] { [row, col] }
  let row: Int
  let col: Int
  var isRemoved = false
}
