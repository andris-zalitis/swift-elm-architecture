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
struct Counter: Elm.Module {

    enum Message {
        case increment
        case decrement
    }

    struct Model: Initable {
        var count = 0
    }

    struct View {
        let count: String
    }

    enum Command {}

    static func update(for message: Message, model: inout Model) -> [Command] {
        switch message {
        case .increment: model.count += 1
        case .decrement: model.count -= 1
        }
        return []
    }

    static func view(for model: Model) -> View {
        let count = String(model.count)
        return View(count: count)
    }
    
}
```

## Imperative shell

<img src="Images/Storyboard.png" width="421" height="535" alt="Storyboard"/>

```swift
class CounterViewController: UIViewController {

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

    typealias Module = Counter

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
typealias Module = Counter
```

```swift
class CounterTests: XCTestCase {

    func testInit() {
        let model = Model()
        XCTAssertEqual(model.count, 0)
    }

    func testIncrement() {
        do {
            var model = Model(count: 1)
            let commands = Module.update(for: .increment, model: &model)
            XCTAssertEqual(model, Model(count: 2))
            XCTAssertTrue(commands.isEmpty)
        }
        do {
            var model = Model(count: 2)
            let commands = Module.update(for: .increment, model: &model)
            XCTAssertEqual(model, Model(count: 3))
            XCTAssertTrue(commands.isEmpty)
        }
    }

    func testDecrement() {
        do {
            var model = Model(count: -1)
            let commands = Module.update(for: .decrement, model: &model)
            XCTAssertEqual(model, Model(count: -2))
            XCTAssertTrue(commands.isEmpty)
        }
        do {
            var model = Model(count: -2)
            let commands = Module.update(for: .decrement, model: &model)
            XCTAssertEqual(model, Model(count: -3))
            XCTAssertTrue(commands.isEmpty)
        }
    }

    func testView() {
        do {
            let model = Model(count: 1)
            let view = Module.view(for: model)
            XCTAssertEqual(view.count, "1")
        }
        do {
            let model = Model(count: 2)
            let view = Module.view(for: model)
            XCTAssertEqual(view.count, "2")
        }
    }
    
}
```

```swift
typealias Model = Module.Model

extension Model: Equatable {
    public static func ==(lhs: Model, rhs: Model) -> Bool {
        return String(describing: lhs) == String(describing: rhs)
    }
}
```
