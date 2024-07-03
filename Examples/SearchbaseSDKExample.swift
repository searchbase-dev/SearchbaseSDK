import SearchbaseSDK

@available(macOS 10.15, iOS 13.0, *)
struct SearchbaseExample {
  let sdk = SearchbaseSDK(apiToken: "your_api_token_here")

  func performSearch() async {
    do {
      let response = try await sdk.search(
        index: "products",
        filters: [Filter(field: "category", op: "EQUAL", value: "electronics")],
        select: ["name", "price"],
        limit: 10
      )

      print("Total results: \(response.total)")
      for result in response.results {
        if let name = result.fields["name"]?.value as? String,
          let price = result.fields["price"]?.value as? Double
        {
          print("Product: \(name), Price: $\(price)")
        }
      }
    } catch {
      print("An error occurred: \(error)")
    }
  }

  func searchAllProducts() async {
    do {
      for try await results in sdk.searchAll(index: "products", batchSize: 50) {
        for result in results {
          if let name = result.fields["name"]?.value as? String {
            print("Product: \(name)")
          }
        }
      }
    } catch {
      print("An error occurred: \(error)")
    }
  }
}

// Usage
@available(macOS 10.15, iOS 13.0, *)
func main() async {
  let example = SearchbaseExample()
  await example.performSearch()
  await example.searchAllProducts()
}

// To run this example, you would typically call it from an async context like this:
// Task {
//     await main()
// }
