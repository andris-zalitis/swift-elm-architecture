# The Elm Architecture for Swift

This is [The Elm Architecture](https://guide.elm-lang.org/architecture/) for [Swift](https://swift.org).

Questions? Comments? Concerns? [Say hello!](https://twitter.com/salutis)

<a href="http://elm-lang.org"><img src="Images/Logo-Elm.png" width="32" height="32" alt="Elm Logo"/></a>
<a href="https://swift.org"><img src="Images/Logo-Swift.png" width="32" height="32" alt="Swift Logo"/></a>

| `master` | `develop` |
| :------- | :-------- |
| [![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=583f5837a72f6501008044ab&branch=master&build=latest)](https://dashboard.buddybuild.com/apps/583f5837a72f6501008044ab/build/latest) | [![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=583f5837a72f6501008044ab&branch=develop&build=latest)](https://dashboard.buddybuild.com/apps/583f5837a72f6501008044ab/build/latest) |

# About

_The Elm Architecture_ is a simple pattern for architecting apps. It is great for modularity, code reuse, and testing. Ultimately, it makes it easy to create complex apps that stay healthy as you refactor and add features.

# Example

Let's build a counter:

<img src="Images/Screenshot.png" width="321" height="569" alt="Screenshot"/>

## Functional core

```swift
import Elm

struct Counter: Program {

    struct Seed {}

    enum Event {
        case userDidTapIncrementButton
        case userDidTapDecrementButton
    }

    struct State {
        var count: Int
    }

    struct View {
        let count: String
    }

    enum Action {}
    enum Failure {}

    static func start(with seed: Seed, perform: (Action) -> Void) throws -> State {
        return .init(count: 0)
    }

    static func update(for event: Event, state: inout State, perform: (Action) -> Void) throws {
        switch event {
        case .userDidTapIncrementButton:
            state.count += 1
        case .userDidTapDecrementButton:
            state.count -= 1
        }
    }

    static func view(for state: State) throws -> View {
        let count = String(state.count)
        return .init(count: count)
    }
    
}
```

## Imperative shell

<img src="Images/Storyboard.png" width="421" height="535" alt="Storyboard"/>

```swift
import UIKit
import Elm

class CounterViewController: UIViewController, Elm.Delegate {

    typealias Program = Counter
    var store: Store<Program>!

    @IBOutlet var countLabel: UILabel!
    @IBOutlet var incrementButton: UIBarButtonItem!
    @IBOutlet var decrementButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        store = Counter.makeStore(delegate: self, seed: .init())
    }

    @IBAction func userDidTapIncrementButton() {
        store.dispatch(.userDidTapIncrementButton)
    }

    @IBAction func userDidTapDecrementButton() {
        store.dispatch(.userDidTapDecrementButton)
    }

    func store(_ store: Store<Program>, didUpdate view: Program.View) {
        countLabel.text = view.count
    }

    func store(_ store: Store<Program>, didRequest action: Program.Action) {
        fatalError()
    }
    
}
```

## Unit tests

```swift
import XCTest
import Elm

@testable import Counter

class CounterTests: XCTestCase, Elm.Tests {

    typealias Program = Counter
    let failureReporter = XCTFail

    func test() {
        let start = expectStart(with: .init())
        expect(start?.state.count, 0)
    }

    func testIncrement1() {
        let update = expectUpdate(for: .userDidTapIncrementButton, state: .init(count: 1))
        expect(update?.state.count, 2)
    }

    func testIncrement2() {
        let update = expectUpdate(for: .userDidTapIncrementButton, state: .init(count: 2))
        expect(update?.state.count, 3)
    }

    func testDecrement1() {
        let update = expectUpdate(for: .userDidTapDecrementButton, state: .init(count: -1))
        expect(update?.state.count, -2)
    }

    func testDecrement2() {
        let update = expectUpdate(for: .userDidTapDecrementButton, state: .init(count: -2))
        expect(update?.state.count, -3)
    }

    func testView1() {
        let view = expectView(for: .init(count: 1))
        expect(view?.count, "1")
    }

    func testView2() {
        let view = expectView(for: .init(count: 2))
        expect(view?.count, "2")
    }
    
}
```

# Installation

* Add `github "salutis/swift-elm-architecture"` to `Cartfile`
* Run `carthage bootstrap`
* Drag `Carthage/Build/iOS/Elm.framework` to Xcode project
  * Targets:
    * `App`: Yes
    * `AppTests`: Yes
* Add _Copy Files_ build phase to both `App` and `AppTests` targets
  * Destination: `Frameworks`
  * Name: `Elm.framework`
* Add _Run Script_ build phase to both `App` and `AppTests` targets
  * Script: `carthage copy-frameworks`
  * Input files:`$(SRCROOT)/Carthage/Build/iOS/Elm.framework`
