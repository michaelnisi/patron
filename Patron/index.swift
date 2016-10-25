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
}

/// Defines an HTTP JSON service.
public protocol JSONService {
  
  @discardableResult func get(
    path: String,
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) -> URLSessionTask
  
  @discardableResult func post(
    path: String,
    json: AnyObject,
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) throws -> URLSessionTask
  
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
/// best idea to use it from the main thread, instead, at least I tend to, run 
/// it from within an `Operation`, because usually there is more work to do with
/// the results of your requests anyways; so why not wrap everything neatly into 
/// an operation and execute *off* the main thread.
public final class Patron: JSONService {
  
  private let baseURL: URL
  
  private let session: URLSession
  
  private let target: DispatchQueue
  
  /// The hostname of the remote service.
  public var host: String { get { return baseURL.host! } }
  
  /// The last `NSURL` or `JSONSerialization` error code, and the timestamp at 
  /// which it occured in seconds since `00:00:00 UTC on 1 January 1970`. The
  /// next successful request resets `status` to `nil`.
  public var status: (Int, TimeInterval)?
  
  /// Creates a client for the service at the provided URL.
  ///
  /// - parameter URL: The URL of the service.
  /// - parameter session: The session to use for HTTP requests.
  /// - parameter target: A dispatch queue on which to submit callbacks.
  /// 
  /// - returns: The newly initialized `Patron` client.
  public init(
    URL baseURL: URL,
    session: URLSession,
    target: DispatchQueue
  ) {
    self.baseURL = baseURL
    self.session = session
    self.target = target
  }
  
  deinit {
    session.invalidateAndCancel()
  }
  
  private func dataTaskWithRequest(
    _ req: URLRequest,
    cb: @escaping (AnyObject?, URLResponse?, Error?) -> Void
  ) -> URLSessionTask {
    let task = session.dataTask(with: req, completionHandler: { data, res, error in
      
      func dispatch(_ json: Any?, _ error: Error?) {
        if let er = error {
          self.status = (er._code, Date().timeIntervalSince1970)
        }
        self.target.async {
          cb(json as AnyObject?, res, error)
        }
      }

      guard error == nil else {
        return dispatch(nil, error)
      }
      
      self.status = nil
      
      do {
        let json = try JSONSerialization.jsonObject(
          with: data!, options: []
        )
        dispatch(json, nil)
      } catch let er {
        dispatch(nil, er)
      }
    }) 
    
    task.resume()
    
    return task
  }
  
  /// Issues a `GET` request to the remote API.
  ///
  /// - parameter path: The URL path including first slash, for example "/user".
  /// - parameter cb: The callback receiving the JSON result as its first
  /// parameter, followed by response, and error. All callback parameters may be
  /// `nil`.
  ///
  /// - returns: An executing `URLSessionTask`.
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
  /// - parameter path: The URL path.
  /// - parameter json: The payload to send as the body of this request.
  /// - parameter cb: The callback receiving the JSON result as its first
  /// parameter, followed by response, and error. All callback parameters may be
  /// `nil`.
  ///
  /// - returns: An executing `URLSessionTask`.
  ///
  /// - throws: `PatronError.InvalidJSON`, if the potential `json` payload is 
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
