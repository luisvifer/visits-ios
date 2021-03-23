import ComposableArchitecture
import DriverID
import PublishableKey

public struct DeepLinkEnvironment {
  public var subscribeToDeepLinks: () -> Effect<(PublishableKey, DriverID?), Never>
  public var continueUserActivity: (NSUserActivity) -> Effect<Never, Never>
  
  public init(
    subscribeToDeepLinks: @escaping () -> Effect<(PublishableKey, DriverID?), Never>,
    continueUserActivity: @escaping (NSUserActivity) -> Effect<Never, Never>
  ) {
    self.subscribeToDeepLinks = subscribeToDeepLinks
    self.continueUserActivity = continueUserActivity
  }
}
