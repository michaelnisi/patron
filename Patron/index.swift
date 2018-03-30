//
//  index.swift
//  Patron
//
//  Created by Michael Nisi on 22/11/15.
//  Copyright © 2015 Michael Nisi. All rights reserved.
//

import Foundation

// MARK: API

public enum PatronError: Error {
  case invalidJSON
  case invalidURL(String, [URLQueryItem]?)
}

/// Defines a JSON HTTP client.
public protocol JSONService {

  @discardableResult func get(
    path: String,
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) -> URLSessionTask

  @discardableResult func get(
    path: String,
    with query: [URLQueryItem],
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) throws -> URLSessionTask

  @discardableResult func post(
    path: String,
    json: AnyObject,
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) throws -> URLSessionTask

  @discardableResult func get(
    path: String,
    allowsCellularAccess: Bool,
    cachePolicy: URLRequest.CachePolicy,
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) -> URLSessionTask

  var host: String { get }

  var status: (Int, TimeInterval)? { get }
}

// MARK: -

/// The `Patron` class is a convenient way to represent a remote HTTP JSON
/// service endpoint. A `Patron` object provides access to a single service
/// on a specific host via `GET` and `POST` HTTP methods. It assumes that
/// payloads in both directions are JSON.
///
/// As `Patron` serializes JSON payloads on the calling thread, it is not the
/// best idea to use it from the main thread, instead, it is intended to run
/// within an `Operation` or a closure, off the main thread, encapsulating
/// request, response, and serialization.
public final class Patron: JSONService {

  fileprivate let baseURL: URL

  private let session: URLSession

  /// The hostname of the remote service.
  public var host: String { get { return baseURL.host! } }
  
  private let sQueue = DispatchQueue(label: "ink.codes.patron-\(UUID().uuidString)")
  
  private var _status: (Int, TimeInterval)?

  /// The last `NSURL` or `JSONSerialization` error code, and the timestamp at
  /// which it occured in seconds since `00:00:00 UTC on 1 January 1970`. The
  /// next successful request resets `status` to `nil`.
  public var status: (Int, TimeInterval)? {
    get {
      return sQueue.sync {
        return _status
      }
    }
    set {
      sQueue.sync {
        _status = newValue
      }
    }
  }

  /// Creates a client for the service at the provided URL.
  ///
  /// - Parameters:
  ///   - URL: The URL of the service.
  ///   - session: The session to use for HTTP requests.
  ///
  /// - Returns: The newly initialized `Patron` client.
  public init(URL baseURL: URL, session: URLSession) {
    self.baseURL = baseURL
    self.session = session
  }

  deinit {
    session.invalidateAndCancel()
  }

  fileprivate func dataTaskWithRequest(
    _ req: URLRequest,
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) -> URLSessionTask {
    let task = session.dataTask(with: req) { data, res, error in
      func done(_ json: Any?, _ error: Error?) {
        if let er = error {
          self.status = (er._code, Date().timeIntervalSince1970)
        }
        cb(json as AnyObject?, res, error)
      }

      guard error == nil else {
        return done(nil, error)
      }

      self.status = nil

      do {
        let json = try JSONSerialization.jsonObject(
          with: data!, options: []
        )
        done(json, nil)
      } catch let er {
        done(nil, er)
      }
    }

    task.resume()

    return task
  }

  /// Issues a `GET` request to the remote API.
  ///
  /// - Parameters:
  ///   - path: The URL path including first slash, for example "/user".
  ///   - cb: The callback receiving the JSON result as its first parameter,
  /// followed by response, and error. All callback parameters may be `nil`.
  ///
  /// - Returns: An executing `URLSessionTask`.
  public func get(
    path: String,
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) -> URLSessionTask {
    let url = URL(string: path, relativeTo: baseURL)!
    let req = URLRequest(url: url)

    return dataTaskWithRequest(req, cb: cb)
  }

  /// Issues a `POST` request to the remote API.
  ///
  /// - Parameters:
  ///   - path: The URL path.
  ///   - json: The payload to send as the body of this request.
  ///   - cb: The callback receiving the JSON result as its first
  /// parameter, followed by response, and error. All callback parameters may be
  /// `nil`.
  ///
  /// - Returns: An executing `URLSessionTask`.
  ///
  /// - Throws: `PatronError.InvalidJSON`, if the potential `json` payload is
  /// not serializable to JSON by `NSJSONSerialization`.
  public func post(
    path: String,
    json: AnyObject,
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) throws -> URLSessionTask {
    guard JSONSerialization.isValidJSONObject(json) else {
      throw PatronError.invalidJSON
    }

    let data = try JSONSerialization.data(
      withJSONObject: json, options: .prettyPrinted
    )

    let url = URL(string: path, relativeTo: baseURL)!
    let req = NSMutableURLRequest(url: url)
    req.httpBody = data
    req.httpMethod = "POST"

    return dataTaskWithRequest(req as URLRequest, cb: cb)
  }
}

// MARK: - Additional Parameters

extension Patron {

  /// Issues a `GET` request to the remote API, allowing additional parameters.
  ///
  /// - Parameters:
  ///   - path: The URL path including first slash, for example "/user".
  ///   - cb: The callback receiving the JSON result as its first
  /// parameter, followed by response, and error. All callback parameters may be
  /// `nil`.
  ///   - allowsCellularAccess: `true` if the request is allowed to use
  /// cellular radios.
  ///   - cachePolicy: The cache policy of the request.
  ///
  /// - Returns: An executing `URLSessionTask`.
  public func get(
    path: String,
    allowsCellularAccess: Bool,
    cachePolicy: URLRequest.CachePolicy,
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) -> URLSessionTask {
    let url = URL(string: path, relativeTo: baseURL)!

    var req = URLRequest(url: url)
    req.allowsCellularAccess = allowsCellularAccess
    req.cachePolicy = cachePolicy

    return dataTaskWithRequest(req, cb: cb)
  }

}

// MARK: - Query String

extension Patron {

  /// Issues a `GET` request with a query string to the remote API.
  ///
  /// - Parameters:
  ///   - path: The URL path including first slash, for example "/user".
  ///   - query: The query items of the request.
  ///   - cb: The callback receiving the JSON result as its first parameter,
  /// followed by response, and error. All callback parameters may be `nil`.
  ///
  /// - Returns: An executing `URLSessionTask`.
  ///
  /// - Throws: Might throw `PatronError.invalidURL(String, [URLQueryItem]?)`.
  public func get(
    path: String,
    with query: [URLQueryItem],
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) throws -> URLSessionTask {
    guard let a = URL(string: path, relativeTo: baseURL),
      var comps = URLComponents(url: a, resolvingAgainstBaseURL: true) else {
      throw PatronError.invalidURL(path, query)
    }

    comps.queryItems = query

    guard let url = comps.url else {
      throw PatronError.invalidURL(path, query)
    }

    let req = URLRequest(url: url)

    return dataTaskWithRequest(req, cb: cb)
  }

}
