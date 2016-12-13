# Elm Architecture for Swift

This is [Elm Architecture](https://guide.elm-lang.org/architecture/) for [Swift](https://swift.org).

<a href="http://elm-lang.org"><img src="Images/Logo-Elm.png" width="32" height="32" alt="Swift Logo"/></a>
<a href="https://swift.org"><img src="Images/Logo-Swift.png" width="32" height="32" alt="Swift Logo"/></a>

Build status:

| `master` | `develop` |
| :------- | :-------- |
| [![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=583f5837a72f6501008044ab&branch=master&build=latest)](https://dashboard.buddybuild.com/apps/583f5837a72f6501008044ab/build/latest) | [![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=583f5837a72f6501008044ab&branch=develop&build=latest)](https://dashboard.buddybuild.com/apps/583f5837a72f6501008044ab/build/latest) |

# Example

Let's build a counter:

<img src="Images/Screenshot.png" width="321" height="569" alt="Screenshot"/>

## Functional core

```swift
struct CounterModule: Module {

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

    let program = CounterModule.makeProgram()

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

extension CounterViewController: ElmDelegate {

    typealias Module = CounterModule

    func program(_ program: Program<Module>, didUpdate view: Module.View) {
        countLabel?.text = view.count
    }

    func program(_ program: Program<Module>, didEmit command: Module.Command) {
        // TODO: Add command
    }

}
```

## Unit tests

```swift
class CounterModuleTests: XCTestCase {

    typealias Module = CounterModule

    typealias Model = Module.Model
    typealias View = Module.View

    func testDefault() {
        let model = Model()
        XCTAssertEqual(model.count, 0)
    }

    func testIncrement1() {
        var model = Model(count: 1)
        let commands = Module.update(for: .increment, model: &model)
        XCTAssertEqual(model.count, 2)
        XCTAssertTrue(commands.isEmpty)
    }

    func testIncrement2() {
        var model = Model(count: 2)
        let commands = Module.update(for: .increment, model: &model)
        XCTAssertEqual(model.count, 3)
        XCTAssertTrue(commands.isEmpty)
    }

    func testDecrement1() {
        var model = Model(count: -1)
        let commands = Module.update(for: .decrement, model: &model)
        XCTAssertEqual(model.count, -2)
        XCTAssertTrue(commands.isEmpty)
    }

    func testDecrement2() {
        var model = Model(count: -2)
        let commands = Module.update(for: .decrement, model: &model)
        XCTAssertEqual(model.count, -3)
        XCTAssertTrue(commands.isEmpty)
    }

    func testView1() {
        let model = Model(count: 1)
        let view = Module.view(for: model)
        XCTAssertEqual(view.count, "1")
    }

    func testView2() {
        let model = Model(count: 2)
        let view = Module.view(for: model)
        XCTAssertEqual(view.count, "2")
    }

}
```
