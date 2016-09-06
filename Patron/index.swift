//
//  index.swift
//  Patron
//
//  Created by Michael Nisi on 22/11/15.
//  Copyright © 2015 Michael Nisi. All rights reserved.
//

import Foundation

// MARK: API

public enum PatronError: ErrorType {
  case InvalidJSON
}

/// Defines requirements for accessing a remote JSON service API.
public protocol JSONService {
  
  func get(
    path: String,
    cb: (AnyObject?, NSURLResponse?, ErrorType?) -> Void
  ) -> NSURLSessionTask
  
  func post(
    path: String,
    json: AnyObject,
    cb: (AnyObject?, NSURLResponse?, ErrorType?) -> Void
  ) throws -> NSURLSessionTask
  
  var host: String { get }
  
  var status: (Int, NSTimeInterval)? { get }
}

// MARK: -

/// The `Patron` class is a convenient way to model a remote HTTP JSON
/// service endpoint. A `Patron` object provides access to a single service
/// on a specific host via `GET` and `POST` HTTP methods. It assumes that
/// payloads in both directions are notated in JSON. 
///
/// As `Patron` serializes JSON payloads on the calling thread, it is not the 
/// best idea to use it from the main thread, instead, at least I tend to, run 
/// it from within `NSOperation`, because usually there is more work to do with 
/// the results of your requests anyways; so why not wrap everything neatly into 
/// an operation and execute *off* the main thread.
public final class Patron: JSONService {
  
  private let baseURL: NSURL
  
  private let session: NSURLSession
  
  private let target: dispatch_queue_t
  
  /// The hostname of the remote service.
  public var host: String { get { return baseURL.host! } }
  
  /// The last `NSURL` error code, and the timestamp at which it occured in
  /// seconds since `00:00:00 UTC on 1 January 1970`. The next successful
  /// request resets `status` to `nil`.
  public var status: (Int, NSTimeInterval)?
  
  /// Creates a client for the service at the provided URL.
  ///
  /// - parameter URL: The URL of the service.
  /// - parameter session: The session to use for HTTP requests.
  /// - parameter target: A dispatch queue on which to submit callbacks.
  /// 
  /// - returns: The newly initialized `Patron` client.
  public init(
    URL baseURL: NSURL,
    session: NSURLSession,
    target: dispatch_queue_t
  ) {
    self.baseURL = baseURL
    self.session = session
    self.target = target
  }
  
  deinit {
    session.invalidateAndCancel()
  }
  
  private func dataTaskWithRequest(
    req: NSURLRequest,
    cb: (AnyObject?, NSURLResponse?, ErrorType?) -> Void
  ) -> NSURLSessionTask {
    
    let task = session.dataTaskWithRequest(req) { data, res, error in
      var json: AnyObject? = nil
      var parseError: ErrorType? = nil
      
      defer {
        dispatch_async(self.target) {
          cb(json, res, error ?? parseError)
        }
      }
      
      guard error == nil else {
        return self.status = (error!.code, NSDate().timeIntervalSince1970)
      }
      
      self.status = nil
      
      do {
        return json = try NSJSONSerialization.JSONObjectWithData(
          data!, options: .AllowFragments
        )
      } catch let er {
        return parseError = er
      }
    }
    
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
  /// - returns: An executing `NSURLSessionTask`.
  public func get(
    path: String,
    cb: (AnyObject?, NSURLResponse?, ErrorType?) -> Void
  ) -> NSURLSessionTask {
    
    let url = NSURL(string: path, relativeToURL: baseURL)!
    let req = NSURLRequest(URL: url)
    
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
  /// - returns: An executing `NSURLSessionTask`.
  ///
  /// - throws: `PatronError.InvalidJSON`, if the potential `json` payload is 
  /// not serializable to JSON by `NSJSONSerialization`.
  public func post(
    path: String,
    json: AnyObject,
    cb: (AnyObject?, NSURLResponse?, ErrorType?) -> Void
  ) throws -> NSURLSessionTask {
    
    guard NSJSONSerialization.isValidJSONObject(json) else {
      throw PatronError.InvalidJSON
    }
    
    let data = try NSJSONSerialization.dataWithJSONObject(
      json, options: .PrettyPrinted
    )
    
    let url = NSURL(string: path, relativeToURL: baseURL)!
    let req = NSMutableURLRequest(URL: url)
    req.HTTPBody = data
    req.HTTPMethod = "POST"
    
    return dataTaskWithRequest(req, cb: cb)
  }
}