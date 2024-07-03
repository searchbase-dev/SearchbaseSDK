import XCTest

@testable import SearchbaseSDK

@available(macOS 10.15, iOS 13.0, *)
final class SearchbaseSDKTests: XCTestCase {
  var sdk: SearchbaseSDK!

  override func setUp() {
    super.setUp()
    sdk = SearchbaseSDK(apiToken: "test_token")
  }

  func testFilterToDictionary() {
    let filter = Filter(field: "price", op: "GTE", value: 100)
    let dict = filter.toDictionary()

    XCTAssertEqual(dict["field"] as? String, "price")
    XCTAssertEqual(dict["op"] as? String, "GTE")
    XCTAssertEqual(dict["value"] as? Int, 100)
  }

  func testFilterCodable() throws {
    let filter = Filter(field: "price", op: "GTE", value: 100)
    let encoded = try JSONEncoder().encode(filter)
    let decoded = try JSONDecoder().decode(Filter.self, from: encoded)

    XCTAssertEqual(filter.field, decoded.field)
    XCTAssertEqual(filter.op, decoded.op)
    XCTAssertEqual(filter.value.value as? Int, 100)
  }

  func testAnyCodableEncoding() throws {
    let testCases: [String: Any] = [
      "int": 42,
      "double": 3.14,
      "bool": true,
      "string": "hello",
      "array": [1, 2, 3],
      "dictionary": ["key": "value"],
    ]

    for (key, value) in testCases {
      let anyCodable = AnyCodable(value)
      let encoded = try JSONEncoder().encode(anyCodable)
      let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)

      XCTAssertEqual(
        String(data: encoded, encoding: .utf8),
        String(data: try JSONEncoder().encode(value), encoding: .utf8), "Encoding failed for \(key)"
      )
      XCTAssertEqual(
        decoded.value as? AnyHashable, value as? AnyHashable, "Decoding failed for \(key)")
    }
  }

  func testSearchResponseDecoding() throws {
    let json = """
      {
          "results": [
              {
                  "id": "1",
                  "fields": {
                      "name": "Test Product",
                      "price": 99.99,
                      "inStock": true
                  }
              }
          ],
          "total": 1,
          "limit": 10,
          "offset": 0
      }
      """

    let data = json.data(using: .utf8)!
    let response = try JSONDecoder().decode(SearchResponse.self, from: data)

    XCTAssertEqual(response.results.count, 1)
    XCTAssertEqual(response.results[0].id, "1")
    XCTAssertEqual(response.results[0].fields["name"]?.value as? String, "Test Product")
    XCTAssertEqual(response.results[0].fields["price"]?.value as? Double, 99.99)
    XCTAssertEqual(response.results[0].fields["inStock"]?.value as? Bool, true)
    XCTAssertEqual(response.total, 1)
    XCTAssertEqual(response.limit, 10)
    XCTAssertEqual(response.offset, 0)
  }

  // Note: Add more tests for search and searchAll methods using dependency injection for URLSession to mock network calls
}
