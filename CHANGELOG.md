### 4.0.0 (2016-10-22)

Realizing that callbacks should pass `AnyObject?` instead of `Any?`, I’ve decided to roll back the previous change. However, this comes with the drawback of not allowing fragments in JSON HTTP bodies, but this is acceptable, a decent JSON API should not return unboxed primitives.
([@michaelnisi](https://github.com/michaelnisi))

#### Callbacks

- Type `json` as `AnyObject` instead of `Any`

#### Documentation

- Write a nice README

### 3.0.0 (2016-10-20)

The objective of this release is Swift 3 and Xcode 8, while improving CI.
([@michaelnisi](https://github.com/michaelnisi))

#### Swift 3

- Migrate to Swift 3

#### XCode 8

- Use `PlaygroundSupport` in Playground

#### Code Coverage

- Gather test coverage data for iOS
- Add [CodeCov](https://codecov.io/)-badge

#### CI

- Conditionally start test server via Xcode Run Script or Make
