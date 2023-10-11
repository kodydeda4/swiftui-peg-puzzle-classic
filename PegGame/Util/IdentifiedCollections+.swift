import IdentifiedCollections

extension Array where Element: Identifiable {
  var identified: IdentifiedArrayOf<Element> {
    .init(uniqueElements: self)
  }
}
