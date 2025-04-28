import Sharing

extension SharedReaderKey where Self == AppStorageKey<Bool>.Default {
  static var hasCompletedHowToPlay: Self {
    Self[.appStorage("hasCompletedHowToPlay"), default: false]
  }
}
