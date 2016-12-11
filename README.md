# Elm

This is [Elm](http://elm-lang.org) [architecture](https://guide.elm-lang.org/architecture/) for [Swift](https://swift.org).

| `master` | `develop` |
| :------- | :-------- |
| [![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=583f5837a72f6501008044ab&branch=master&build=latest)](https://dashboard.buddybuild.com/apps/583f5837a72f6501008044ab/build/latest) | [![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=583f5837a72f6501008044ab&branch=develop&build=latest)](https://dashboard.buddybuild.com/apps/583f5837a72f6501008044ab/build/latest) |

# Example

Let's build a counter:

<img src="Images/Screenshot.png" width="321" height="569" alt="Screenshot"/>

## Functional core

```swift
import Elm

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
import UIKit

class CounterViewController: UIViewController, Subscriber {

    let program = CounterModule.makeProgram()

    typealias View = CounterModule.View
    typealias Command = CounterModule.Command

    @IBOutlet var countLabel: UILabel?

    @IBOutlet var incrementButton: UIBarButtonItem?
    @IBOutlet var decrementButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        program.subscribe(self)
    }

    func update(presenting view: View) {
        countLabel?.text = view.count
    }

    func update(performing command: Command) {}

    @IBAction private func userDidTapIncrementButton() {
        program.dispatch(.increment)
    }

    @IBAction private func userDidTapDecrementButton() {
        program.dispatch(.decrement)
    }

}
```
