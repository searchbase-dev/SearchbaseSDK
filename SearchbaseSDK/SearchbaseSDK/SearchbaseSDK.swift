import Foundation

/// A client for interacting with the Searchbase API.
@available(macOS 10.15, iOS 13.0, *)

public struct SearchResponse: Decodable {
  public let total: Int
  public let range: Range
  public let records: [SearchResult]

  public struct Range: Decodable {
    public let start: Int
    public let end: Int
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    total = try container.decode(Int.self, forKey: .total)
    range = try container.decode(Range.self, forKey: .range)
    records = try container.decode([SearchResult].self, forKey: .records)
  }

  private enum CodingKeys: String, CodingKey {
    case total, range, records
  }
}

public struct SearchResult: Decodable {
  public let id: String
  public let title: String
  public let url: String
  public let rent: Int
  public let bedrooms: Int
  public let bathrooms: Int
  public let source: String
  public let neighborhood: Int
  public let originalNeighborhood: String
  public let thumbnailURLs: [String]
  public let createdAt: Timestamp

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    title = try container.decode(String.self, forKey: .title)
    url = try container.decode(String.self, forKey: .url)
    rent = try container.decode(Int.self, forKey: .rent)
    bedrooms = try container.decode(Int.self, forKey: .bedrooms)
    bathrooms = try container.decode(Int.self, forKey: .bathrooms)
    source = try container.decode(String.self, forKey: .source)
    neighborhood = try container.decode(Int.self, forKey: .neighborhood)
    originalNeighborhood = try container.decode(String.self, forKey: .originalNeighborhood)
    thumbnailURLs = try container.decode([String].self, forKey: .thumbnailURLs)
    createdAt = try container.decode(Timestamp.self, forKey: .createdAt)
  }

  private enum CodingKeys: String, CodingKey {
    case id, title, url, rent, bedrooms, bathrooms, source, neighborhood, originalNeighborhood
    case thumbnailURLs
    case createdAt
  }
}

public struct Timestamp: Decodable {
  public let _seconds: Int64
  public let _nanoseconds: Int64

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    _seconds = try container.decode(Int64.self, forKey: ._seconds)
    _nanoseconds = try container.decode(Int64.self, forKey: ._nanoseconds)
  }

  private enum CodingKeys: String, CodingKey {
    case _seconds, _nanoseconds
  }
}

public class SearchbaseSDK {
  private let apiToken: String
  private let baseURL = "https://api.searchbase.dev"

  /// Initializes a new instance of the SearchbaseSDK.
  /// - Parameter apiToken: The API token for authenticating with the Searchbase API.
  public init(apiToken: String) {
    self.apiToken = apiToken
  }

  /// Represents errors that can occur when interacting with the Searchbase API.
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

  /// Performs a search operation on the specified index.
  /// - Parameters:
  ///   - index: The name of the index to search.
  ///   - filters: Optional array of filters to apply to the search.
  ///   - sort: Optional array of sort options to apply to the search results.
  ///   - select: Optional array of field names to include in the results.
  ///   - limit: Optional limit on the number of results to return.
  ///   - offset: Optional offset for pagination.
  /// - Returns: A SearchResponse containing the search results.
  /// - Throws: A SearchError if the operation fails.
  public func search(
    index: String,
    filters: [Filter]? = nil,
    sort: [Sort]? = nil,
    select: [String]? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws -> SearchResponse {
    guard let url = URL(string: "\(baseURL)/search") else {
      throw SearchError.invalidURL
    }

    var queryDict: [String: Any] = ["index": index]
    if let filters = filters { queryDict["filters"] = filters.map { $0.toDictionary() } }
    if let sort = sort { queryDict["sort"] = sort.map { $0.toDictionary() } }
    if let select = select { queryDict["select"] = select }
    if let limit = limit { queryDict["limit"] = limit }
    if let offset = offset { queryDict["offset"] = offset }

    let body = ["query": queryDict]

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(apiToken, forHTTPHeaderField: "x-searchbase-token")
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    print("Request URL: \(url)")
    print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
    print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw SearchError.unexpectedResponse(0)
    }

    print("Response status code: \(httpResponse.statusCode)")
    print("Response headers: \(httpResponse.allHeaderFields)")
    print("Response body: \(String(data: data, encoding: .utf8) ?? "")")

    switch httpResponse.statusCode {
    case 200...299:
      do {
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(SearchResponse.self, from: data)
        return searchResponse
      } catch {
        print("Decoding error: \(error)")
        if let decodingError = error as? DecodingError {
          print("Decoding error details: \(decodingError)")
        }
        throw SearchError.decodingError(error)
      }
    case 400...499:
      let errorBody = String(data: data, encoding: .utf8) ?? "No error message"
      print("API Error Body: \(errorBody)")
      if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
        throw SearchError.apiError(apiError.message)
      } else {
        throw SearchError.unexpectedResponse(httpResponse.statusCode)
      }
    default:
      throw SearchError.unexpectedResponse(httpResponse.statusCode)
    }
  }

  /// Performs a search operation that automatically fetches all results, handling pagination internally.
  /// - Parameters:
  ///   - index: The name of the index to search.
  ///   - filters: Optional array of filters to apply to the search.
  ///   - sort: Optional array of sort options to apply to the search results.
  ///   - select: Optional array of field names to include in the results.
  ///   - batchSize: The number of results to fetch in each API call. Defaults to 100.
  /// - Returns: An AsyncThrowingStream that yields arrays of SearchResults.
  public func searchAll(
    index: String,
    filters: [Filter]? = nil,
    sort: [Sort]? = nil,
    select: [String]? = nil,
    batchSize: Int = 100
  ) -> AsyncThrowingStream<[SearchResult], Error> {
    AsyncThrowingStream { continuation in
      Task {
        var offset = 0
        var totalFetched = 0
        var total: Int?

        repeat {
          do {
            let response = try await self.search(
              index: index,
              filters: filters,
              sort: sort,
              select: select,
              limit: batchSize,
              offset: offset
            )
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

/// Represents a sort option for search operations.
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

/// Represents the direction of sorting.
public enum SortDirection: String, Codable {
  case ascending = "ASC"
  case descending = "DESC"
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
