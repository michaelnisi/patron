//: Playground - noun: a place where people can play

import Foundation
import Patron
import XCPlayground

let url = NSURL(string: "https://api.github.com")!
let session = NSURLSession.sharedSession()
let target = dispatch_get_main_queue()

let patron = Patron(URL: url, session: session, target: target)

patron.get("/search/repositories?q=language:swift") { json, response, error in
  assert(error == nil)
  let repos = json!["items"] as! [[String : AnyObject]]
  let names = repos.map { $0["name"]! }
  print(names)
  XCPlaygroundPage.currentPage.finishExecution()
}

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true