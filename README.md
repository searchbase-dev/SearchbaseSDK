# SearchbaseSDK

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)

SearchbaseSDK is a powerful Swift SDK for integrating the Searchbase API into your macOS, iOS, tvOS, and watchOS applications. It provides a convenient way to interact with the Searchbase API, allowing you to build complex search experiences in your applications.

## Features

- Easy to integrate with Searchbase API
- Supports macOS, iOS, tvOS, and watchOS
- Asynchronous functions for network calls
- Customizable search options with filters, sorting, and pagination
- Detailed error handling

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.0+

## Installation

### CocoaPods

You can install SearchbaseSDK via [CocoaPods](https://cocoapods.org/). Add the following line to your `Podfile`:

```ruby
pod 'SearchbaseSDK', '~> 1.0.0'
```

Then run:

```bash
pod install
```

### Swift Package Manager

You can also integrate SearchbaseSDK using [Swift Package Manager](https://swift.org/package-manager/). Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/searchbase-dev/SearchbaseSDK.git", from: "1.0.0")
]
```

## Usage

### Initialization

First, import the SDK and initialize it with your API token:

```swift
import SearchbaseSDK

@available(macOS 10.15, iOS 13.0, *)
let searchbase = SearchbaseSDK(apiToken: "your-api-token")
```

### Performing a Search

To perform a search, create an instance of `SearchOptions` and call the `search` method:

```swift
let options = SearchOptions(index: "your_index", filters: nil, sort: nil, select: nil, limit: 10, offset: 0)

Task {
    do {
        let response: SearchResponse<YourModel> = try await searchbase.search(options: options)
        print("Total records: \(response.total)")
        print("Records: \(response.records)")
    } catch {
        print("Error: \(error)")
    }
}
```

### Handling Pagination

To handle pagination and retrieve all results, use the `searchAll` method:

```swift
Task {
    do {
        for try await records in searchbase.searchAll(options: options) {
            print("Fetched \(records.count) records")
        }
    } catch {
        print("Error: \(error)")
    }
}
```

### Models

Define your models to match the expected response structure:

```swift
struct YourModel: Decodable {
    let id: String
    let name: String
    // Other properties...
}
```

### Error Handling

The SDK provides detailed error handling for various scenarios:

```swift
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
```

## License

SearchbaseSDK is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request with your improvements.

## Contact

For support or any questions, please contact us at [support@searchbase.dev](mailto:support@searchbase.dev).
