[![Build Status](https://travis-ci.org/michaelnisi/patron.svg)](http://travis-ci.org/michaelnisi/patron)
[![Code Coverage](https://codecov.io/github/michaelnisi/patron/coverage.svg?branch=master)](https://codecov.io/github/michaelnisi/patron?branch=master)

# Patron

Consume JSON HTTP APIs.

Programs often communicate over [HTTP](http://httpwg.org/). The de facto standard notation for payloads in this communication is [JSON](http://www.json.org/). Patron provides a simple interface to send and receive data to and from HTTP servers. It’s purpose is to reduce redundant client code in our programs.

## Symbols

### Classes

- [Patron](#patron-1)

The `Patron` object represents a remote HTTP JSON service endpoint.

### Protocols

- JSONService

The `JSONService` protocol defines a JSON service.

## Patron

The `Patron` class is a convenient way to represent a remote HTTP JSON service endpoint. A `Patron` object provides access to a single service on a specific host via `GET` and `POST` HTTP methods. It assumes that payloads in both directions are JSON.

As `Patron` serializes JSON payloads on the calling thread, it’s not a good idea to use it from the main thread, instead I recommend to run it from within an `Operation`. Usually there is more work to do with the results of your requests: Why not wrap everything neatly into an operation and execute off the main thread?

### Creating a Client

```swift
init(URL baseURL: URL, session: URLSession, target: DispatchQueue)
```

Creates a client for the service at the specified `URL`.

#### Parameters

- `URL` The URL of the service.
- `session` The session to use for HTTP requests.
- `target` A dispatch queue on which to submit callbacks.

#### Returns

Returns the newly initialized `Patron` client.

### Issuing GET Requests

```swift
@discardableResult func get(
  path: String,
  cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
) -> URLSessionTask
```

Issues a `GET` request to the remote API.

#### Parameters

- `path` The URL path including first slash, for example "/user".
- `cb` The callback receiving the JSON result as its first parameter, followed by response, and error. All callback parameters may be `nil`.

#### Returns

An executing `URLSessionTask`.

#### Example

Searching for Swift Repos on GitHub and printing their names.

```swift
import Foundation
import Patron

let github = URL(string: "https://api.github.com")!
let shared = URLSession.shared
let main = DispatchQueue.main

let patron = Patron(URL: github, session: shared, target: main)

patron.get(path: "/search/repositories?q=language:swift") { json, res, er in
  let repos = json!["items"] as! [[String : AnyObject]]
  let names = repos.map { $0["name"]! }
  print(names)
}
```

Find this example in the Playground included in this repo.

#### Query String

If you don‘t feel like stringing together the path yourself, you can pass URL query items.

```swift
@discardableResult func get(
  path: String,
  with query: [URLQueryItem],
  cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
) throws -> URLSessionTask
```

Issues a `GET` request with query string to the remote API.

#### Parameters

- `path` The URL path including first slash, for example "/user".
- `query` An array of URL query items from the `Foundation` framework.
- `cb` The callback receiving the JSON result as its first parameter, followed by response, and error. All callback parameters may be `nil`.

#### Returns

An executing `URLSessionTask`.

#### Additional Parameters

For more control, there‘s an alternative method with `allowsCellularAccess` and `cachePolicy` parameters.

```swift
@discardableResult func get(
  path: String,
  allowsCellularAccess: Bool,
  cachePolicy: URLRequest.CachePolicy,
  cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
) -> URLSessionTask
```

- `allowsCellularAccess` `true` if the request is allowed to use cellular radios.
- `cachePolicy` The cache policy of the request.

### Issuing POST Requests

```swift
@discardableResult func post(
  path: String,
  json: AnyObject,
  cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
) throws -> URLSessionTask
```

Issues a `POST` request to the remote API.

#### Parameters

- `path` The URL path.
- `json` The payload to send as the body of this request.
- `cb` The callback receiving the JSON result as its first parameter, followed by response, and error. All callback parameters may be `nil`.

#### Returns

An executing `URLSessionTask`.

#### Throws

`PatronError.InvalidJSON`, if the potential `json` payload is
not serializable to JSON by `NSJSONSerialization`.

### Getting Information

```swift
var host: String { get }
```

The hostname of the remote service.

```swift
var status: (Int, TimeInterval)? { get }
```

The last `URLSession` or `JSONSerialization` error code, and the timestamp at which it occured in Unix time, seconds since `00:00:00 UTC on 1 January 1970`. The next successful request resets `status` to `nil`.

```swift
var targetQueue: DispatchQueue { get }
```

The dispatch queue to which callbacks are submitted.

## Install

Add the Patron Xcode project to your Workspace—at this time, it only contains an iOS target that builds a dynamic framework. Patron only depends on [Foundation](https://developer.apple.com/reference/Foundation).

## License

[MIT](https://raw.githubusercontent.com/michaelnisi/patron/master/LICENSE)
