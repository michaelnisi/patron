### 6.0.0 (2018-01-19)

- TODO

### 4.0.2 (2017-01-31)

Just some maintenance sliding into the new year.

- [fa59561](https://github.com/michaelnisi/patron/commit/fa59561d5709f29760a9a05b9e9e1ea3259ffaa6) Remove `node_modules` from repo.
([@michaelnisi](https://github.com/michaelnisi))

- [ab7aeab](https://github.com/michaelnisi/patron/commit/ab7aeab2863c104a4672c51be6936503945a1097) Installing Node.js dependencies before testing to fix Travis CI build.
([@michaelnisi](https://github.com/michaelnisi))

- [e893fc5](https://github.com/michaelnisi/patron/commit/e893fc5cfa783f4dce641e061caa3be62c7b05ba) Upgrade to Xcode 8.2.1, yielding a broken Travis CI build, caused by missing Node.js dependencies, required for running the tests.
([@michaelnisi](https://github.com/michaelnisi))

### 4.0.1 (2016-10-28)

Updating dependent libs, I learned that I needed these two practical tweaks.

- [ae220f9](https://github.com/michaelnisi/patron/commit/ae220f9a2ad44a0a74d27d08f340044c203ca29c) To submit reachability events on the same queue, from a different source, I needed an easy way to access the target queue.
([@michaelnisi](https://github.com/michaelnisi))

- [06fc9a1](https://github.com/michaelnisi/patron/commit/06fc9a1449bea10b0777d186d1d50c7ed100f934) Complying with Apple’s recommendation, supporting the latest two iOS versions, this sets the iOS deployment target to 9.0.
([@michaelnisi](https://github.com/michaelnisi))

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
