# The Elm Architecture for Swift

This is [The Elm Architecture](https://guide.elm-lang.org/architecture/) for [Swift](https://swift.org).

<a href="http://elm-lang.org"><img src="Images/Logo-Elm.png" width="32" height="32" alt="Elm Logo"/></a>
<a href="https://swift.org"><img src="Images/Logo-Swift.png" width="32" height="32" alt="Swift Logo"/></a>

[![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=583f5837a72f6501008044ab&branch=master&build=latest)](https://dashboard.buddybuild.com/apps/583f5837a72f6501008044ab/build/latest)

# About

_The Elm Architecture_ is a simple pattern for architecting apps. It is great for modularity, code reuse, and testing. Ultimately, it makes it easy to create complex apps that stay healthy as you refactor and add features.

# Interface

```swift
public protocol Program {

    associatedtype Seed
    associatedtype Event
    associatedtype State
    associatedtype Action
    associatedtype View
    associatedtype Failure

    static func start(with seed: Seed) -> Start<Self>
    static func update(for event: Event, state: State) -> Update<Self>
    static func render(for state: State) -> Render<Self>

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

    struct State {
        var count: Int
    }

    enum Action {}

    struct View {
        let count: String
    }

    enum Failure {}

    static func start(with seed: Seed) -> Start<Counter> {
        let initialState = State(count: seed.count)
        return .init(state: initialState)
    }

    static func update(for event: Event, state: State) -> Update<Counter> {
        let nextState: State
        switch event {
        case .increment: nextState = .init(count: state.count + 1)
        case .decrement: nextState = .init(count: state.count - 1)
        }
        return .init(state: nextState)
    }

    static func render(for state: State) -> Render<Counter> {
        let count = String(state.count)
        let view = View(count: count)
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

class CounterTests: XCTestCase, Tests {

    typealias Program = Counter

    func testStart() {
        let start = start(with: .init())
        let state = start.expect(.state)
        assert(state?.count, equals: 0)
    }

    func testIncrement1() {
        let update = update(for: .userDidTapIncrementButton, state: .init(count: 1))
        let state = update.expect(.state)
        assert(state?.count, equals: 2)
    }

    func testIncrement2() {
        let update = update(for: .userDidTapIncrementButton, state: .init(count: 2))
        let state = update.expect(.state)
        assert(state?.count, equals: 3)
    }

    func testDecrement1() {
        let update = update(for: .userDidTapDecrementButton, state: .init(count: -1))
        let state = update.expect(.state)
        assert(state?.count, equals: -2)
    }

    func testDecrement2() {
        let update = update(for: .userDidTapDecrementButton, state: .init(count: -2))
        let state = update.expect(.state)
        assert(state?.count, equals: -3)
    }

    func testView1() {
        let render = render(for: .init(count: 1))
        let view = render.expect(.view)
        assert(view?.count, equals: "1")
    }

    func testView2() {
        let render = render(for: .init(count: 2))
        let view = render.expect(.view)
        assert(view?.count, equals: "2")
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
