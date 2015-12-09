//
//  PatronTests.swift
//  PatronTests
//
//  Created by Michael Nisi on 23/11/15.
//  Copyright © 2015 Michael Nisi. All rights reserved.
//

import XCTest
@testable import Patron

class PatronTests: XCTestCase {
  
  var svc: Patron!
  var session: NSURLSession!
  var queue: dispatch_queue_t!
  
  func freshSession () -> NSURLSession {
    let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
    conf.HTTPShouldUsePipelining = true
    conf.requestCachePolicy = .ReloadIgnoringLocalCacheData
    return NSURLSession(configuration: conf)
  }
  
  override func setUp () {
    super.setUp()
    queue = dispatch_queue_create("com.michaelnisi.patron.json", DISPATCH_QUEUE_CONCURRENT)
    session = freshSession()
    let url = NSURL(string: "http://localhost:8080")!
    svc = PatronClient(URL: url, queue: queue, session: session)
  }
  
  override func tearDown () {
    session.invalidateAndCancel()
    super.tearDown()
  }
  
  func testPost () {
    let exp = expectationWithDescription("post")
    let numberOfRequests = 99
    var count = numberOfRequests
    let payload = ["name": "michael"]
    for _ in 0...numberOfRequests {
      try! svc.post("/echo", json: payload) { json, response, error in
        XCTAssertNil(error)
        XCTAssertNotNil(response)
        XCTAssertNotNil(json)
        let wanted = payload
        if let found = json as? [String:String] {
          XCTAssertEqual(found, wanted)
        } else {
          XCTFail("unexpected \(json) \(response)")
        }
        dispatch_sync(dispatch_get_main_queue()) {
          if count-- == 0 {
            exp.fulfill()
          }
        }
      }
    }
    self.waitForExpectationsWithTimeout(10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testGet () {
    let exp = expectationWithDescription("get")
    let numberOfRequests = 99
    var count = numberOfRequests
    for _ in 0...numberOfRequests {
      try! svc.get("/hello/michael") { json, response, error in
        XCTAssertNil(error)
        XCTAssertNotNil(response)
        XCTAssertNotNil(json)
        let wanted = "hello michael"
        if let found = json as? String {
          XCTAssertEqual(found, wanted)
        } else {
          XCTFail("unexpected \(json) \(response)")
        }
        dispatch_sync(dispatch_get_main_queue()) {
          if count-- == 0 {
            exp.fulfill()
          }
        }
      }
    }
    self.waitForExpectationsWithTimeout(10) { er in
      XCTAssertNil(er)
    }
  }
}
