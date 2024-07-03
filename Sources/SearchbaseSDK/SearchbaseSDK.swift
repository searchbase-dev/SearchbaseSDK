import Foundation

/// A client for interacting with the Searchbase API.
@available(macOS 10.15, iOS 13.0, *)
public class SearchbaseSDK {
  private let apiToken: String
  private let baseURL = "https://api.searchbase.dev"

  /// Initializes a new instance of the SearchbaseSDK.
  /// - Parameter apiToken: The API token for authenticating with the Searchbase API.
  public init(apiToken: String) {
    self.apiToken = apiToken
  }

  /// Represents errors that can occur when interacting with the Searchbase API.
  public enum SearchError: Error {
    case invalidURL
    case networkError(Error)
    case noData
    case decodingError(Error)
    case apiError(String)
  }

  /// Performs a search operation on the specified index.
  /// - Parameters:
  ///   - index: The name of the index to search.
  ///   - filters: Optional array of filters to apply to the search.
  ///   - select: Optional array of field names to include in the results.
  ///   - limit: Optional limit on the number of results to return.
  ///   - offset: Optional offset for pagination.
  /// - Returns: A SearchResponse containing the search results.
  /// - Throws: A SearchError if the operation fails.
  public func search(
    index: String, filters: [Filter]? = nil, select: [String]? = nil, limit: Int? = nil,
    offset: Int? = nil
  ) async throws -> SearchResponse {
    guard let url = URL(string: "\(baseURL)/search") else {
      throw SearchError.invalidURL
    }

    var queryDict: [String: Any] = ["index": index]
    if let filters = filters { queryDict["filters"] = filters.map { $0.toDictionary() } }
    if let select = select { queryDict["select"] = select }
    if let limit = limit { queryDict["limit"] = limit }
    if let offset = offset { queryDict["offset"] = offset }

    let body = ["query": queryDict]

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(apiToken, forHTTPHeaderField: "x-searchbase-token")
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)

    do {
      return try JSONDecoder().decode(SearchResponse.self, from: data)
    } catch {
      if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
        throw SearchError.apiError(apiError.message)
      } else {
        throw SearchError.decodingError(error)
      }
    }
  }

  /// Performs a search operation that automatically fetches all results, handling pagination internally.
  /// - Parameters:
  ///   - index: The name of the index to search.
  ///   - filters: Optional array of filters to apply to the search.
  ///   - select: Optional array of field names to include in the results.
  ///   - batchSize: The number of results to fetch in each API call. Defaults to 100.
  /// - Returns: An AsyncThrowingStream that yields arrays of SearchResults.
  public func searchAll(
    index: String, filters: [Filter]? = nil, select: [String]? = nil, batchSize: Int = 100
  ) -> AsyncThrowingStream<[SearchResult], Error> {
    AsyncThrowingStream { continuation in
      Task {
        var offset = 0
        var totalFetched = 0
        var total: Int?

        repeat {
          do {
            let response = try await self.search(
              index: index, filters: filters, select: select, limit: batchSize, offset: offset)
            continuation.yield(response.results)

            totalFetched += response.results.count
            offset += batchSize
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

/// Represents a filter to be applied in a search operation.
public struct Filter: Codable {
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

/// Represents the response from a search operation.
public struct SearchResponse: Codable {
  public let results: [SearchResult]
  public let total: Int
  public let limit: Int
  public let offset: Int
}

/// Represents a single result in a search operation.
public struct SearchResult: Codable {
  public let id: String
  public let fields: [String: AnyCodable]
}

/// A type that can encode and decode values of any type.
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

/// Represents an error returned by the API.
struct APIError: Codable {
  let message: String
}
