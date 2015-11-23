//
//  index.swift
//  Patron
//
//  Created by Michael Nisi on 22/11/15.
//  Copyright © 2015 Michael Nisi. All rights reserved.
//

import Foundation
import Ola

public enum PatronError: ErrorType {
  case NoData
}

public class PatronOperation: NSOperation {
  let queue: dispatch_queue_t
  let session: NSURLSession
  let req: NSURLRequest
  let timeout: dispatch_time_t
  
  public var response: NSURLResponse?
  public var error: ErrorType?
  public var result: AnyObject?
  
  public init (
    session: NSURLSession,
    request: NSURLRequest,
    queue: dispatch_queue_t,
    timeout: dispatch_time_t = DISPATCH_TIME_FOREVER) {
      self.session = session
      self.req = request
      self.queue = queue
      self.timeout = timeout
  }
  
  var sema: dispatch_semaphore_t?
  
  func lock () {
    if !cancelled && sema == nil {
      sema = dispatch_semaphore_create(0)
      dispatch_semaphore_wait(sema!, timeout)
    }
  }
  
  func unlock () {
    if let sema = self.sema {
      dispatch_semaphore_signal(sema)
    }
  }
  
  weak var task: NSURLSessionTask?
  
  func request () {
    self.task?.cancel()
    self.task = nil
    
    let task = session.dataTaskWithRequest(req) { [weak self] data, response, error in
      if self?.cancelled == true {
        return
      }
      self?.response = response
      
      if let er = error {
        if er.code == NSURLErrorNotConnectedToInternet ||
          er.code == NSURLErrorNetworkConnectionLost {
            self?.check()
        } else {
          self?.error = er
          
          // TODO: Retry after three, six, and nine seconds
          
          self?.unlock()
        }
        return
      }
      do {
        guard let d = data else { throw PatronError.NoData }
        let result = try NSJSONSerialization.JSONObjectWithData(d, options: .AllowFragments)
        self?.result = result
      } catch let er {
        self?.error = er
      }
      defer {
        self?.unlock()
      }
    }
    task.resume()
    
    self.task = task
  }
  
  var allowsCellularAccess: Bool { get {
    return session.configuration.allowsCellularAccess }
  }
  
  func reachable (status: OlaStatus) -> Bool {
    return status == .Reachable || (status == .Cellular && allowsCellularAccess)
  }
  
  lazy var ola: Ola? = { [unowned self] in
    Ola(host: self.req.URL!.host!, queue: self.queue)
  }()
  
  func check () {
    if let ola = self.ola {
      if reachable(ola.reach()) {
        request()
      } else {
        ola.reachWithCallback() { [weak self] status in
          if self?.cancelled == false && self?.reachable(status) == true {
            self?.request()
          }
        }
      }
    } else {
      print("could not initialize ola")
    }
  }
  
  public override func main () {
    if cancelled { return }
    request()
    lock()
  }
  
  public override func cancel () {
    task?.cancel()
    unlock()
    super.cancel()
  }
}

