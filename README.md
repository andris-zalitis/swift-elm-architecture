# The Elm Architecture for Swift

<a href="http://elm-lang.org"><img src="Images/Logo-Elm.png" width="32" height="32" alt="Elm Logo"/></a>
<a href="https://swift.org"><img src="Images/Logo-Swift.png" width="32" height="32" alt="Swift Logo"/></a>
<a href="https://dashboard.buddybuild.com/apps/583f5837a72f6501008044ab/build/latest"><img src="https://dashboard.buddybuild.com/api/statusImage?appID=583f5837a72f6501008044ab&branch=master&build=latest" alt="Continuous Integration"/></a>

[The Elm Architecture](https://guide.elm-lang.org/architecture/) is a simple pattern for architecting apps. It is great for modularity, code reuse, and testing. Ultimately, it makes it easy to create complex apps that stay healthy as you refactor and add features.

# Interface

```swift
protocol Program {

    associatedtype Seed
    associatedtype Event
    associatedtype State
    associatedtype Action
    associatedtype View
    associatedtype Failure

    static func start(with seed: Seed) -> Start<Self>
    static func update(for event: Event, state: State) -> Update<Self>
    static func render(with state: State) -> Render<Self>

}
```

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

    typealias State = Int

    enum Action {}

    typealias View = String

    enum Failure {}

    static func start(with seed: Seed) -> Start<Counter> {
        return .init(state: 0)
    }

    static func update(for event: Event, state: State) -> Update<Counter> {
        switch event {
        case .increment: return .init(state: state + 1)
        case .decrement: return .init(state: state - 1)
        }
    }

    static func render(with state: State) -> Render<Counter> {
        let view = String(state)
        return .init(view: view)
    }
    
}
```

## Imperative shell

<img src="Images/Storyboard.png" width="421" height="535" alt="Storyboard"/>

```swift
import UIKit
import Elm

class CounterViewController: UIViewController, StoreDelegate {

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
        countLabel.text = view
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

class CounterTests: XCTestCase, Tests {

    typealias Program = Counter

    func testStart() {
        let start = start(with: .init())
        let state = start.expect(.state)
        assert(state, equals: 0)
    }

    func testIncrement1() {
        let update = update(for: .userDidTapIncrementButton, state: 1)
        let state = update.expect(.state)
        assert(state, equals: 2)
    }

    func testIncrement2() {
        let update = update(for: .userDidTapIncrementButton, state: 2)
        let state = update.expect(.state)
        assert(state, equals: 3)
    }

    func testDecrement1() {
        let update = update(for: .userDidTapDecrementButton, state: -1)
        let state = update.expect(.state)
        assert(state, equals: -2)
    }

    func testDecrement2() {
        let update = update(for: .userDidTapDecrementButton, state: -2)
        let state = update.expect(.state)
        assert(state, equals: -3)
    }

    func testView1() {
        let render = render(with: 1)
        let view = render.expect(.view)
        assert(view, equals: "1")
    }

    func testView2() {
        let render = render(with: 2)
        let view = render.expect(.view)
        assert(view, equals: "2")
    }

    func fail(_ message: String, file: StaticString, line: Int) {
        XCTFail(message, file: file, line: UInt(line))
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
* Add _Run Script_ build phase to both `App` and `AppTests` targets
  * Script: `carthage copy-frameworks`
  * Input files:`$(SRCROOT)/Carthage/Build/iOS/Elm.framework`
