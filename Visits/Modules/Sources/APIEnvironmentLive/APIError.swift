import APIEnvironment
import Combine
import Foundation
import NonEmpty
import Types
import Utility


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
      let response = response as! HTTPURLResponse
      let parsingError: APIError<Failure>.ParsingError
      do {
        return Just(try decoder.decode(Success.self, from: data))
          .setFailureType(to: APIError<Failure>.self)
          .eraseToAnyPublisher()
      } catch DecodingError.dataCorrupted(let context) {
        parsingError = .init(stringLiteral: "\(context.debugDescription) Path: \(codingPath(context.codingPath))")
      } catch DecodingError.keyNotFound(let key, let context) {
        parsingError = .init(stringLiteral: "Key \"\(key.stringValue)\" not found at path: \(codingPath(context.codingPath))")
      } catch DecodingError.typeMismatch(_, let context) {
        parsingError = .init(stringLiteral: "\(context.debugDescription) Path: \(codingPath(context.codingPath))")
      } catch DecodingError.valueNotFound(let value, let context) {
        parsingError = .init(stringLiteral: "Value of type \"\(String(describing: value))\" not found at path: \(codingPath(context.codingPath))")
      } catch {
        parsingError = .init(stringLiteral: "Unrecognized decoding error: \(error)")
      }
      
      if let failure = try? decoder.decode(Failure.self, from: data) {
        return Fail(error: .error(failure, response, data))
          .eraseToAnyPublisher()
      } else if let failure = try? decoder.decode(HyperTrackAPIError.self, from: data) {
        return Fail(error: .api(failure, response, data))
          .eraseToAnyPublisher()
      } else if let failure = try? decoder.decode(HyperTrackCriticalAPIError.self, from: data) {
        return Fail(error: .server(failure, response, data))
          .eraseToAnyPublisher()
      } else {
        return Fail(error: .unknown(parsingError, response, data))
          .eraseToAnyPublisher()
      }
    }
    .eraseToAnyPublisher()
}

func codingPath(_ keys: [CodingKey]) -> NonEmptyString {
  keys.reduce(into: "root") { result, key in
    result += "." + key.stringValue
  }
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
      let response = response as! HTTPURLResponse
      let parsingError: APIError<Never>.ParsingError
      do {
        return Just(try decoder.decode(Success.self, from: data))
          .setFailureType(to: APIError<Never>.self)
          .eraseToAnyPublisher()
      } catch DecodingError.dataCorrupted(let context) {
        parsingError = .init(stringLiteral: "\(context.debugDescription) Path: \(codingPath(context.codingPath))")
      } catch DecodingError.keyNotFound(let key, let context) {
        parsingError = .init(stringLiteral: "Key \"\(key.stringValue)\" not found at path: \(codingPath(context.codingPath))")
      } catch DecodingError.typeMismatch(_, let context) {
        parsingError = .init(stringLiteral: "\(context.debugDescription) Path: \(codingPath(context.codingPath))")
      } catch DecodingError.valueNotFound(let value, let context) {
        parsingError = .init(stringLiteral: "Value of type \"\(String(describing: value))\" not found at path: \(codingPath(context.codingPath))")
      } catch {
        parsingError = .init(stringLiteral: "Unrecognized decoding error: \(error)")
      }
      
      if let failure = try? decoder.decode(HyperTrackAPIError.self, from: data) {
        return Fail(error: .api(failure, response, data))
          .eraseToAnyPublisher()
      } else if let failure = try? decoder.decode(HyperTrackCriticalAPIError.self, from: data) {
        return Fail(error: .server(failure, response, data))
          .eraseToAnyPublisher()
      } else {
        return Fail(error: .unknown(parsingError, response, data))
          .eraseToAnyPublisher()
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
