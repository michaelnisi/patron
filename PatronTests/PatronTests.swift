//
//  PatronTests.swift
//  PatronTests
//
//  Created by Michael Nisi on 23/11/15.
//  Copyright © 2015 Michael Nisi. All rights reserved.
//

import XCTest
@testable import Patron

final class PatronTests: XCTestCase {
  
  private var svc: Patron!
  
  private func freshSession() -> NSURLSession {
    let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
    conf.HTTPShouldUsePipelining = true
    conf.requestCachePolicy = .ReloadIgnoringLocalCacheData
    
    return NSURLSession(configuration: conf)
  }
  
  private func freshService(port: Int) -> Patron {
    let url = NSURL(string: "http://localhost:\(port)")!
    let s = freshSession()
    let t = dispatch_get_main_queue()
    
    return Patron(URL: url, session: s, target: t)
  }
  
  override func setUp() {
    super.setUp()
    svc = freshService(8080)
  }
  
  override func tearDown() {
    svc = nil
    super.tearDown()
  }
  
  func testDeinit() {
    let exp = expectationWithDescription("get")
    
    svc.get("/slow") { json, res, er in
      XCTAssertNil(er)
      XCTAssertNotNil(res)
      XCTAssertNotNil(json)
      exp.fulfill()
    }
    
    self.svc = nil
    
    self.waitForExpectationsWithTimeout(10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testCancelled() {
    let exp = expectationWithDescription("get")
    let svc = self.svc
    
    let req = svc.get("/hello/michael") { json, res, er in
      XCTAssertNil(json)
      XCTAssertNil(res)
      XCTAssertNotNil(er)
      
      let (code, _) = svc.status!
      XCTAssertEqual(code, -999, "cancelled")
      
      exp.fulfill()
    }
    req.cancel()
    
    self.waitForExpectationsWithTimeout(10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testWrongPort() {
    self.svc = freshService(8081)
    
    let exp = expectationWithDescription("get")
    let svc = self.svc
    
    svc.get("/hello/michael") { json, res, er in
      XCTAssertNil(json)
      XCTAssertNil(res)
      XCTAssertNotNil(er)
      
      let (code, _) = svc.status!
      XCTAssertEqual(code, -1004, "Could not connect to the server.")

      exp.fulfill()
    }
    
    self.waitForExpectationsWithTimeout(10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testHost() {
    XCTAssertEqual(svc.host, "localhost")
  }
  
  func testNotFound() {
    let exp = expectationWithDescription("get")
    let svc = self.svc
    
    svc.get("/nowhere") { json, res, er in
      XCTAssertNotNil(json)
      XCTAssertNotNil(res)
      XCTAssertNil(er, "404 is not an error")
      let http = res as! NSHTTPURLResponse
      XCTAssertEqual(http.statusCode, 404)
      XCTAssertNil(svc.status)
      exp.fulfill()
    }
    
    self.waitForExpectationsWithTimeout(10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testPostInvalidJSON() {
    let exp = expectationWithDescription("post")
    
    do {
      try svc.post("/echo", json: self) { _, _, _ in
        XCTFail("should not be called")
      }
    } catch PatronError.InvalidJSON {
      exp.fulfill()
    } catch {
      XCTFail()
    }

    self.waitForExpectationsWithTimeout(10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testPost() {
    let exp = expectationWithDescription("post")
    
    let count = 1000
    let payload = ["name": "michael"]
    let svc = self.svc
    
    for i in 0...count {
      try! svc.post("/echo", json: payload) { json, response, error in
        XCTAssertNil(error, "\(i): error: \(error)")
        XCTAssertNotNil(response)
        XCTAssertNotNil(json)
        
        let wanted = payload
        
        if let found = json as? [String:String] {
          XCTAssertEqual(found, wanted)
        } else {
          XCTFail("unexpected \(json) \(response)")
        }
        if i == count {
          exp.fulfill()
        }
      }
    }
    
  
    self.waitForExpectationsWithTimeout(10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testGet() {
    let exp = expectationWithDescription("get")
    
    let count = 100
    
    for i in 0...count {
      svc.get("/hello/michael") { json, response, error in
        XCTAssertNil(error, "\(i): error: \(error)")
        XCTAssertNotNil(response)
        XCTAssertNotNil(json)
        
        let wanted = "hello michael"
        if let found = json as? String {
          XCTAssertEqual(found, wanted)
        } else {
          XCTFail("unexpected \(json) \(response)")
        }
        if i == count {
          exp.fulfill()
        }
      }
    }
    
    self.waitForExpectationsWithTimeout(10) { er in
      XCTAssertNil(er)
    }
  }
}
