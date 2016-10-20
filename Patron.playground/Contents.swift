//: Playground - noun: a place where people can play

import Foundation
import Patron
import PlaygroundSupport

let url = URL(string: "https://api.github.com")!
let session = URLSession.shared
let target = DispatchQueue.main

let patron = Patron(URL: url, session: session, target: target)
let path = "/search/repositories?q=language:swift"

let task = patron.get(path) { json, response, error in
  assert(error == nil)
  let dict = json as! [String : Any]
  let repos = dict["items"] as! [[String : AnyObject]]
  let names = repos.map { $0["name"]! }
  print(names)
  
  PlaygroundPage.current.finishExecution()
}

PlaygroundPage.current.needsIndefiniteExecution = true