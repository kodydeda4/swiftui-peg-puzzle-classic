import Sharing
import Foundation

extension SharedReaderKey where Self == InMemoryKey<Build>.Default {
  static var build: Self {
    Self[.inMemory("build"), default: .previewValue]
  }
}

struct Build: Equatable, Codable {
  let version: Double
}

extension Build {
  static var previewValue = Self(
    version: 0.0
  )
}
