import Dependencies
import DependenciesMacros
import Foundation
import Tagged

@DependencyClient
struct BuildClient {
  var version: () -> Double = { 0.0 }
}

extension DependencyValues {
  var build: BuildClient {
    get { self[BuildClient.self] }
    set { self[BuildClient.self] = newValue }
  }
}

extension BuildClient: TestDependencyKey {
  static let testValue = Self()
}

extension BuildClient {
  static let previewValue = Self(
    version: { 0.0 }
  )
}

extension BuildClient: DependencyKey {
  static let liveValue = Self(
    version: {
      (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
        .flatMap(Double.init)
      ?? 0.0
    }
  )
}

