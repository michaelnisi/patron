# patron - consume JSON via HTTP

The **Patron** iOS framework provides a client to consume JSON HTTP APIs.

[![Build Status](https://travis-ci.org/michaelnisi/patron.svg)](http://travis-ci.org/michaelnisi/patron)

## Example

```swift
import Foundation
import Patron

let url = NSURL(string: "https://api.github.com")!
let session = NSURLSession.sharedSession()
let target = dispatch_get_main_queue()

let patron = Patron(URL: url, session: session, target: target)

patron.get("/search/repositories?q=language:swift") { json, response, error in
  assert(error == nil)
  let repos = json!["items"] as! [[String : AnyObject]]
  let names = repos.map { $0["name"]! }
  print(names)
}
```

## License

[MIT License](https://raw.githubusercontent.com/michaelnisi/patron/master/LICENSE)
