import Foundation

@available(macOS 10.15, iOS 13.0, *)
public class SearchbaseSDK {
  private let apiToken: String
  private let baseURL = "https://api.searchbase.dev"

  public init(apiToken: String) {
    self.apiToken = apiToken
  }

  public enum SearchError: Error, CustomStringConvertible {
    case invalidURL
    case networkError(Error)
    case noData
    case decodingError(Error)
    case apiError(String)
    case unexpectedResponse(Int)

    public var description: String {
      switch self {
      case .invalidURL:
        return "Invalid URL for the API request."
      case .networkError(let error):
        return "Network error occurred: \(error.localizedDescription)"
      case .noData:
        return "No data received from the API."
      case .decodingError(let error):
        return "Failed to decode the API response: \(error.localizedDescription)"
      case .apiError(let message):
        return "API error: \(message)"
      case .unexpectedResponse(let statusCode):
        return "Unexpected response from the API. Status code: \(statusCode)"
      }
    }
  }

  public func search<T: Decodable>(
    options: SearchOptions
  ) async throws -> SearchResponse<T> {
    guard let url = URL(string: "\(baseURL)/search") else {
      throw SearchError.invalidURL
    }

    var queryDict: [String: Any] = ["index": options.index]
    if let filters = options.filters { queryDict["filters"] = filters.map { $0.toDictionary() } }
    if let sort = options.sort { queryDict["sort"] = sort.map { $0.toDictionary() } }
    if let select = options.select { queryDict["select"] = select }
    if let limit = options.limit { queryDict["limit"] = limit }
    if let offset = options.offset { queryDict["offset"] = offset }

    let body = ["query": queryDict]

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(apiToken, forHTTPHeaderField: "x-searchbase-token")
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw SearchError.unexpectedResponse(0)
    }

    switch httpResponse.statusCode {
    case 200...299:
      do {
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(SearchResponse<T>.self, from: data)
        return searchResponse
      } catch {
        print("Decoding error: \(error)")
        throw SearchError.decodingError(error)
      }
    case 400...499:
      if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
        throw SearchError.apiError(apiError.message)
      } else {
        throw SearchError.unexpectedResponse(httpResponse.statusCode)
      }
    default:
      throw SearchError.unexpectedResponse(httpResponse.statusCode)
    }
  }

  public func searchAll<T: Decodable>(
    options: SearchOptions
  ) -> AsyncThrowingStream<[T], Error> {
    AsyncThrowingStream { continuation in
      Task {
        var offset = 0
        var totalFetched = 0
        var total: Int?

        repeat {
          do {
            var currentOptions = options
            currentOptions.limit = 100  // Set batch size
            currentOptions.offset = offset

            let response: SearchResponse<T> = try await self.search(options: currentOptions)
            continuation.yield(response.records)

            totalFetched += response.records.count
            offset = response.range.end
            total = response.total
          } catch {
            continuation.finish(throwing: error)
            return
          }
        } while totalFetched < (total ?? 0)

        continuation.finish()
      }
    }
  }
}

public struct SearchOptions {
  public let index: String
  public var filters: [SearchFilter]?
  public var sort: [Sort]?
  public var select: [String]?
  public var limit: Int?
  public var offset: Int?

  public init(
    index: String,
    filters: [SearchFilter]? = nil,
    sort: [Sort]? = nil,
    select: [String]? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) {
    self.index = index
    self.filters = filters
    self.sort = sort
    self.select = select
    self.limit = limit
    self.offset = offset
  }
}

public struct SearchFilter: Codable {
  public let field: String
  public let op: String
  public let value: AnyCodable

  public init(field: String, op: String, value: Any) {
    self.field = field
    self.op = op
    self.value = AnyCodable(value)
  }

  public func toDictionary() -> [String: Any] {
    return [
      "field": field,
      "op": op,
      "value": value.value,
    ]
  }
}

public struct Sort: Codable {
  public let field: String
  public let direction: SortDirection

  public init(field: String, direction: SortDirection) {
    self.field = field
    self.direction = direction
  }

  public func toDictionary() -> [String: Any] {
    return [
      "field": field,
      "direction": direction.rawValue,
    ]
  }
}

public enum SortDirection: String, Codable {
  case ascending = "ASC"
  case descending = "DESC"
}

public struct SearchResponse<T: Decodable>: Decodable {
  public let total: Int
  public let range: Range
  public let records: [T]

  public struct Range: Decodable {
    public let start: Int
    public let end: Int
  }
}

public struct AnyCodable: Codable {
  public let value: Any

  public init(_ value: Any) {
    self.value = value
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let intValue = try? container.decode(Int.self) {
      value = intValue
    } else if let doubleValue = try? container.decode(Double.self) {
      value = doubleValue
    } else if let boolValue = try? container.decode(Bool.self) {
      value = boolValue
    } else if let stringValue = try? container.decode(String.self) {
      value = stringValue
    } else if let arrayValue = try? container.decode([AnyCodable].self) {
      value = arrayValue.map { $0.value }
    } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
      value = dictionaryValue.mapValues { $0.value }
    } else {
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "AnyCodable value cannot be decoded")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch value {
    case let intValue as Int:
      try container.encode(intValue)
    case let doubleValue as Double:
      try container.encode(doubleValue)
    case let boolValue as Bool:
      try container.encode(boolValue)
    case let stringValue as String:
      try container.encode(stringValue)
    case let arrayValue as [Any]:
      try container.encode(arrayValue.map { AnyCodable($0) })
    case let dictionaryValue as [String: Any]:
      try container.encode(dictionaryValue.mapValues { AnyCodable($0) })
    default:
      throw EncodingError.invalidValue(
        value,
        EncodingError.Context(
          codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
    }
  }
}

struct APIError: Codable {
  let message: String
}
