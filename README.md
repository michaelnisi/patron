# patron - consume JSON via HTTP

The **Patron** iOS framework provides a client to consume JSON HTTP APIs.

[![Build Status](https://travis-ci.org/michaelnisi/patron.svg)](http://travis-ci.org/michaelnisi/patron)
[![Code Coverage](https://codecov.io/github/michaelnisi/patron/coverage.svg?branch=master)](https://codecov.io/github/michaelnisi/patron?branch=master)

## Example

```swift
import Foundation
import Patron

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
}
```

## License

[MIT License](https://raw.githubusercontent.com/michaelnisi/patron/master/LICENSE)
