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
  
  fileprivate var svc: JSONService!
  
  fileprivate func freshSession() -> URLSession {
    let conf = URLSessionConfiguration.default
    conf.httpShouldUsePipelining = true
    conf.requestCachePolicy = .reloadIgnoringLocalCacheData
    
    return URLSession(configuration: conf)
  }
  
  fileprivate func freshService(_ port: Int) -> Patron {
    let url = URL(string: "http://localhost:\(port)")!
    let s = freshSession()
    let t = DispatchQueue.main
    
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
    let exp = expectation(description: "Deinit")
    
    svc.get(path: "/slow") { json, res, er in
      XCTAssertNil(er)
      XCTAssertNotNil(res)
      XCTAssertNotNil(json)
      exp.fulfill()
    }
    
    self.svc = nil
    
    self.waitForExpectations(timeout: 10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testCancelled() {
    let exp = expectation(description: "Cancelled")
    let svc = self.svc
    
    let req = svc?.get(path: "/hello/michael") { json, res, er in
      XCTAssertNil(json)
      XCTAssertNil(res)
      XCTAssertNotNil(er)
      
      let (code, _) = (svc?.status!)!
      XCTAssertEqual(code, -999, "cancelled")
      
      exp.fulfill()
    }
    req?.cancel()
    
    self.waitForExpectations(timeout: 10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testWrongPort() {
    self.svc = freshService(7331)
    
    let exp = expectation(description: "WrongPort")
    let svc = self.svc
    
    svc?.get(path: "/hello/michael") { json, res, er in
      XCTAssertNil(json)
      XCTAssertNil(res)
      XCTAssertNotNil(er)
      
      let (code, _) = (svc?.status!)!
      
      XCTAssertEqual(code, -1004, "Could not connect to the server.")

      exp.fulfill()
    }
    
    self.waitForExpectations(timeout: 10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testHost() {
    XCTAssertEqual(svc.host, "localhost")
  }
  
  func testNotFound() {
    let exp = expectation(description: "NotFound")
    let svc = self.svc
    
    svc?.get(path: "/nowhere") { json, res, er in
      let dict = json as! [String : String]
      let code = dict["code"]! as String
      XCTAssertEqual(code, "ResourceNotFound")
      
      XCTAssertNotNil(res)
      XCTAssertNil(er)
      
      exp.fulfill()
    }
    
    self.waitForExpectations(timeout: 10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testGetInvalidJSON() {
    let exp = expectation(description: "GetInvalidJSON")
    
    svc.get(path: "/invalid") { json, res, error in
      XCTAssertNil(json)
      XCTAssertNotNil(res)
      XCTAssertEqual(error!._code, 3840)
      exp.fulfill()
    }
    
    self.waitForExpectations(timeout: 10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testPostInvalidJSON() {
    let exp = expectation(description: "PostInvalidJSON")
    
    do {
      try svc.post(path: "/echo", json: self) { _, _, _ in
        XCTFail("should not be called")
      }
    } catch PatronError.invalidJSON {
      exp.fulfill()
    } catch {
      XCTFail()
    }

    self.waitForExpectations(timeout: 10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testPost() {
    let exp = expectation(description: "Post")
    
    let payload  = ["name": "michael"]
    let svc = self.svc
    
    try! svc?.post(path: "/echo", json: payload as AnyObject) { json, response, error in
      XCTAssertNil(error, "should not error: \(String(describing: error))")
      XCTAssertNotNil(response)
      XCTAssertNotNil(json)
      
      let wanted = payload
      
      if let found = json as? [String : String] {
        XCTAssertEqual(found, wanted)
      } else {
        XCTFail("unexpected \(String(describing: json)) \(String(describing: response))")
      }
      
      exp.fulfill()
    }
    
    self.waitForExpectations(timeout: 10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testGet() {
    let exp = expectation(description: "Get")

    svc.get(path: "/hello/michael") { json, response, error in
      XCTAssertNil(error, "should not error: \(String(describing: error))")
      XCTAssertNotNil(response)
      XCTAssertNotNil(json)

      let wanted = ["message": "hello, michael"]
      let found = json as! [String : String]
      XCTAssertEqual(found, wanted)
      
      exp.fulfill()
    }
    
    self.waitForExpectations(timeout: 10) { er in
      XCTAssertNil(er)
    }
  }
  
  func testGetArrayOfDictionaries() {
    let exp = expectation(description: "GetArrayOfDictionaries")
    
    svc.get(path: "/potus") { json, response, error in
      XCTAssertNil(error, "should not error: \(String(describing: error))")
      XCTAssertNotNil(response)
      XCTAssertNotNil(json)
    
      let presidents = json as! [[String : Any]]
      let found: [String] = presidents.map { $0["name"] as! String }
      let wanted = ["Barack Obama", "George W. Bush", "Bill Clinton"]
      XCTAssertEqual(found, wanted)
  
      exp.fulfill()
    }
    
    self.waitForExpectations(timeout: 10) { er in
      XCTAssertNil(er)
    }
  }
}
