import Credentials
import DeviceID
import DriverID
import Experience
import PublishableKey
import PushStatus
import SDK
import TabSelection
import Visit

public enum StorageState: Equatable {
  case signIn(Email?)
  case signUp(Email?)
  case driverID(DriverID?, PublishableKey)
  case visits(Set<Visit>, TabSelection, PublishableKey, DriverID, PushStatus, Experience)
}

public enum RestoredState: Equatable {
  case deepLink
  case signIn(Email?)
  case signUp(Email?)
  case driverID(DriverID?, PublishableKey)
  case visits(Set<Visit>, TabSelection, PublishableKey, DriverID, DeviceID, SDKUnlockedStatus, PushStatus, Permissions, Experience)
}
