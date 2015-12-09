//
//  index.swift
//  Patron
//
//  Created by Michael Nisi on 22/11/15.
//  Copyright © 2015 Michael Nisi. All rights reserved.
//

import Foundation

public enum PatronError: ErrorType {
  case InvalidURL
  case NIY
}

/// **Patron** is a simple client that consumes JSON HTTP APIs.
public protocol Patron {
  
  /// Issues a `GET` request to the remote API.
  ///
  /// - Parameter path: The URL path.
  /// - Parameter cb: The callback receiving the JSON result as its first parameter.
  ///
  /// - Returns: A new `NSURLSessionTask`.
  ///
  /// - Throws: `PatronError.InvalidURL` if the provided path does not yield a valid URL.
  func get (path: String, cb: (AnyObject?, NSURLResponse?, ErrorType?) -> Void) throws -> NSURLSessionTask
  
  /// Issues a `POST` request to the remote API.
  ///
  /// - Parameter path: The URL path.
  /// - Parameter json: The JSON payload to send as the body of this request.
  /// - Parameter cb: The callback receiving the JSON result as its first parameter.
  ///
  /// - Returns: A new `NSURLSessionTask`.
  ///
  /// - Throws: `PatronError.InvalidURL` if the provided path does not yield a valid URL.
  func post (path: String, json: AnyObject, cb: (AnyObject?, NSURLResponse?, ErrorType?) -> Void) throws -> NSURLSessionTask
  
}

/// A **Patron** implementation.
public class PatronClient: Patron {
  
  let baseURL: NSURL
  let queue: dispatch_queue_t
  let session: NSURLSession
  
  /// Creates a client for the service at the provided URL.
  ///
  /// - Parameter URL: The URL of the service.
  /// - Parameter queue: A dispatch queue to serialize to and from JSON.
  /// - Parameter session: The session to use for HTTP requests.
  /// 
  /// - Returns: The newly initialized PatronClient object.
  public init (
    URL baseURL: NSURL,
    queue: dispatch_queue_t,
    session: NSURLSession) {
      
    self.baseURL = baseURL
    self.queue = queue
    self.session = session
  }
  
  typealias SessionCallback = (AnyObject?, NSURLResponse?, ErrorType?) -> Void
  
  func dataTaskWithRequest (req: NSURLRequest, cb: SessionCallback) throws -> NSURLSessionTask {
    let queue = self.queue
    let task = session.dataTaskWithRequest(req) { data, res, error in
      guard error == nil else {
        return cb(nil, res, error!)
      }
      dispatch_async(queue) {
        do {
          let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
          cb(json, res, nil)
        } catch let er {
          cb(nil, res, er)
        }
      }
    }
    task.resume()
    return task
  }

  public func get (path: String, cb: (AnyObject?, NSURLResponse?, ErrorType?) -> Void) throws -> NSURLSessionTask {
    guard let url = NSURL(string: path, relativeToURL: baseURL) else {
      throw PatronError.InvalidURL
    }
    let req = NSURLRequest(URL: url)
    return try dataTaskWithRequest(req, cb: cb)
  }
  
  public func post (path: String, json: AnyObject, cb: (AnyObject?, NSURLResponse?, ErrorType?) -> Void) throws -> NSURLSessionTask {
    guard let url = NSURL(string: path, relativeToURL: baseURL) else {
      throw PatronError.InvalidURL
    }
    var er: ErrorType?
    var HTTPBody: NSData?
    dispatch_sync(queue) {
      do {
        HTTPBody = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
      } catch let error {
        er = error
      }
    }
    guard er == nil else {
      throw er!
    }
    let req = NSMutableURLRequest(URL: url)
    req.HTTPBody = HTTPBody
    req.HTTPMethod = "POST"
    return try dataTaskWithRequest(req, cb: cb)
  }
}