//: Playground - noun: a place where people can play

import Foundation
import Patron
import PlaygroundSupport

let url = URL(string: "https://api.github.com")!
let session = URLSession.shared
let target = DispatchQueue.main

let patron = Patron(URL: url, session: session, target: target)

patron.get(path: "/search/repositories?q=language:swift") { json, response, error in
  assert(error == nil)
  let repos = json!["items"] as! [[String : AnyObject]]
  let names = repos.map { $0["name"]! }
  print(names)
  
  PlaygroundPage.current.finishExecution()
}

PlaygroundPage.current.needsIndefiniteExecution = true
