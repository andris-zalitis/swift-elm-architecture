# The Elm Architecture for Swift

This is [The Elm Architecture](https://guide.elm-lang.org/architecture/) for [Swift](https://swift.org).

<a href="http://elm-lang.org"><img src="Images/Logo-Elm.png" width="32" height="32" alt="Swift Logo"/></a>
<a href="https://swift.org"><img src="Images/Logo-Swift.png" width="32" height="32" alt="Swift Logo"/></a>

Build status:

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

struct CounterModule: Elm.Module {

    struct Flags {}

    enum Message {
        case increment
        case decrement
    }

    struct Model {
        var count: Int
    }

    struct View {
        let count: String
    }

    enum Command {}
    enum Failure {}

    static func start(with flags: Flags) throws -> Model {
        return Model(count: 0)
    }

    static func update(for message: Message, model: inout Model, perform: (Command) -> Void) throws {
        switch message {
        case .increment: model.count += 1
        case .decrement: model.count -= 1
        }
    }

    static func view(for model: Model) throws -> View {
        let count = String(model.count)
        return View(count: count)
    }
    
}
```

## Imperative shell

<img src="Images/Storyboard.png" width="421" height="535" alt="Storyboard"/>

```swift
import UIKit
import Elm

final class CounterViewController: UIViewController {

    let program = Counter.makeProgram()

    @IBOutlet var countLabel: UILabel?

    @IBOutlet var incrementButton: UIBarButtonItem?
    @IBOutlet var decrementButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        program.setDelegate(self)
    }

    @IBAction private func userDidTapIncrementButton() {
        program.dispatch(.increment)
    }

    @IBAction private func userDidTapDecrementButton() {
        program.dispatch(.decrement)
    }

}
```

```swift
extension CounterViewController: Elm.Delegate {

    typealias Module = CounterModule

    func program(_ program: Program<Module>, didUpdate view: Module.View) {
        countLabel?.text = view.count
    }

    func program(_ program: Program<Module>, didEmit command: Module.Command) {
        fatalError()
    }

}
```

## Unit tests

```swift
import XCTest
import Elm
@testable import Counter

final class CounterModuleModelTests: XCTestCase, Elm.TestCase {

    typealias Module = CounterModule
    let failureReporter = XCTFail

    func testDefault() {
        let test = makeTest(flags: .init())
        let model = test.expectModel()
        expect(model?.count, 0)
    }

    func testIncrement() {
        do {
            let test = makeTest(model: .init(count: 1))
            let model = test.expectModel(for: .increment)
            expect(model?.count, 2)
        }
        do {
            let test = makeTest(model: .init(count: 2))
            let model = test.expectModel(for: .increment)
            expect(model?.count, 3)
        }
    }

    func testDecrement() {
        do {
            let test = makeTest(model: .init(count: -1))
            let model = test.expectModel(for: .decrement)
            expect(model?.count, -2)
        }
        do {
            let test = makeTest(model: .init(count: -2))
            let model = test.expectModel(for: .decrement)
            expect(model?.count, -3)
        }
    }

    func testView() {
        do {
            let test = makeTest(model: .init(count: 1))
            let view = test.expectView()
            expect(view?.count, "1")
        }
        do {
            let test = makeTest(model: .init(count: 2))
            let view = test.expectView()
            expect(view?.count, "2")
        }
    }
    
}
```
