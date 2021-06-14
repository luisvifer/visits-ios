import APIEnvironment
import Combine
import Foundation
import Utility
import Types


func callAPI<Success: Decodable, Failure: Decodable>(
  session: URLSession = URLSession.shared,
  request: URLRequest,
  success: Success.Type,
  failure: Failure.Type,
  decoder: JSONDecoder = JSONDecoder()
) -> AnyPublisher<Success, APIError<Failure>> {
  session.dataTaskPublisher(for: request)
    .mapError { APIError<Failure>.network($0) }
    .flatMap { data, response -> AnyPublisher<Success, APIError<Failure>> in
      do {
        return Just(try decoder.decode(Success.self, from: data))
          .setFailureType(to: APIError<Failure>.self)
          .eraseToAnyPublisher()
      } catch {
        if let failure = try? decoder.decode(Failure.self, from: data) {
          return Fail(error: .error(failure))
            .eraseToAnyPublisher()
        } else if let failure = try? decoder.decode(HyperTrackAPIError.self, from: data) {
          return Fail(error: .api(failure))
            .eraseToAnyPublisher()
        } else if let failure = try? decoder.decode(HyperTrackCriticalAPIError.self, from: data) {
          return Fail(error: .server(failure))
            .eraseToAnyPublisher()
        } else {
          return Fail(error: .unknown(data, response as! HTTPURLResponse))
            .eraseToAnyPublisher()
        }
      }
    }
    .eraseToAnyPublisher()
}

func callAPI<Success: Decodable>(
  session: URLSession = URLSession.shared,
  request: URLRequest,
  success: Success.Type,
  decoder: JSONDecoder = JSONDecoder()
) -> AnyPublisher<Success, APIError<Never>> {
  session.dataTaskPublisher(for: request)
    .mapError { APIError<Never>.network($0) }
    .flatMap { data, response -> AnyPublisher<Success, APIError<Never>> in
      do {
        return Just(try decoder.decode(Success.self, from: data))
          .setFailureType(to: APIError<Never>.self)
          .eraseToAnyPublisher()
      } catch {
        if let failure = try? decoder.decode(HyperTrackAPIError.self, from: data) {
          return Fail(error: .api(failure))
            .eraseToAnyPublisher()
        } else if let failure = try? decoder.decode(HyperTrackCriticalAPIError.self, from: data) {
          return Fail(error: .server(failure))
            .eraseToAnyPublisher()
        } else {
          return Fail(error: .unknown(data, response as! HTTPURLResponse))
            .eraseToAnyPublisher()
        }
      }
    }
    .eraseToAnyPublisher()
}


func callAPIWithAuth<Success: Decodable>(
  publishableKey: PublishableKey,
  deviceID: DeviceID,
  success: Success.Type,
  decoder: JSONDecoder = JSONDecoder(),
  request: @escaping (Token) -> URLRequest
) -> AnyPublisher<Success, APIError<Never>> {
  getToken(auth: publishableKey, deviceID: deviceID)
    .flatMap { callAPI(request: request($0), success: success, decoder: decoder) }
    .eraseToAnyPublisher()
}

extension AnyPublisher {
  func catchToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
    self
      .map { Result.success($0) }
      .catch(Result.failure >>> Just.init)
      .eraseToAnyPublisher()
  }
}
