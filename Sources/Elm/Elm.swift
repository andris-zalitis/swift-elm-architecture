// The MIT License (MIT)
//
// Copyright (c) 2017 Rudolf Adamkovič
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//
// MARK: -
// MARK: Program
//

public protocol Program {

    associatedtype Seed
    associatedtype Event
    associatedtype State
    associatedtype Action
    associatedtype View
    associatedtype Failure

    static func start(with seed: Seed, perform: (Action) -> Void) -> Result<State, Failure>
    static func update(for event: Event, state: inout State, perform: (Action) -> Void) -> Result<Success, Failure>
    static func view(for state: State) -> Result<View, Failure>

}

public extension Program {

    static func makeStore<Delegate: Elm.Delegate>(delegate: Delegate, seed: Seed) -> Store<Self> where Delegate.Program == Self {
        return Store<Self>(program: self, delegate: delegate, seed: seed)
    }

}

public enum Result<Success, Failure> {

    case success(Success)
    case failure(Failure)

}

public typealias Success = ()

//
// MARK: -
// MARK: Delegate
//

public protocol Delegate: class {

    associatedtype Program: Elm.Program

    typealias Action = Program.Action
    typealias View = Program.View

    func store(_ store: Store<Program>, didRequest action: Action)
    func store(_ store: Store<Program>, didUpdate view: View)

}

//
// MARK: -
// MARK: Store
//

public final class Store<Program: Elm.Program> {

    typealias Seed = Program.Seed
    typealias Event = Program.Event
    typealias State = Program.State
    typealias Action = Program.Action
    typealias View = Program.View

    private var state: State
    public private(set) lazy var view: View = Store.makeView(program: Program.self, state: self.state)

    private typealias ViewSink = (View) -> Void
    private typealias ActionSink = (Action) -> Void

    private var sendView: ViewSink = { _ in }
    private var sendAction: ActionSink = { _ in }

    init<Delegate: Elm.Delegate>(program: Program.Type, delegate: Delegate, seed: Seed) where Delegate.Program == Program {
        var actions: [Action] = []
        let result = program.start(with: seed) { action in
            actions.append(action)
        }
        switch result {
        case .success(let state):
            self.state = state
            sendView = { [weak delegate] view in
                delegate?.store(self, didUpdate: view)
            }
            sendAction = { [weak delegate] action in
                delegate?.store(self, didRequest: action)
            }
            updateDelegate(with: actions)
        case .failure(let failure):
            print("FATAL: \(program).start function did fail!", to: &standardError)
            dump(failure, to: &standardError, name: "Failure")
            dump(seed, to: &standardError, name: "Seed")
            fatalError()
        }
    }

    public func dispatch(_ events: Event...) {
        var actions: [Action] = []
        for event in events {
            let result = Program.update(for: event, state: &state) { action in
                actions.append(action)
            }
            if case .failure(let failure) = result {
                print("FATAL: \(Program.self).update function did fail!", to: &standardError)
                dump(failure, to: &standardError, name: "Failure")
                dump(event, to: &standardError, name: "Event")
                dump(state, to: &standardError, name: "State")
                fatalError()
            }
        }
        view = Store.makeView(program: Program.self, state: state)
        updateDelegate(with: actions)
    }

    private static func makeView(program: Program.Type, state: State) -> View {
        switch program.view(for: state) {
        case .success(let view):
            return view
        case .failure(let failure):
            print("FATAL: \(program).view function did fail!", to: &standardError)
            dump(failure, to: &standardError, name: "Error")
            dump(state, to: &standardError, name: "State")
            fatalError()
        }
    }

    private func updateDelegate(with actions: [Action]) {
        guard Thread.isMainThread else {
            OperationQueue.main.addOperation { [weak store = self] in
                store?.updateDelegate(with: actions)
            }
            return
        }
        sendView(view)
        actions.forEach(sendAction)
    }

}

//
// MARK: -
// MARK: Tests
//

public protocol Tests: class {

    associatedtype Program: Elm.Program

    typealias Seed = Program.Seed
    typealias State = Program.State
    typealias Event = Program.Event
    typealias Action = Program.Action
    typealias View = Program.View
    typealias Failure = Program.Failure

    // XCTFail
    typealias FailureReporter = (
        String, // event
        StaticString, // file
        UInt // line
        ) -> Void

    var failureReporter: FailureReporter { get }

}

public extension Tests {

    func expectFailure(with seed: Seed, file: StaticString = #file, line: Int = #line) -> Failure? {
        let result = Program.start(with: seed) { _ in }
        switch result {
        case .success:
            reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .failure(let failure):
            return failure
        }
    }

    func expectFailure(for state: State, file: StaticString = #file, line: Int = #line) -> Failure? {
        let result = Program.view(for: state)
        switch result {
        case .success:
            reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .failure(let failure):
            return failure
        }
    }

    func expectFailure(for event: Event, state: State, file: StaticString = #file, line: Int = #line) -> Failure? {
        var state = state
        let result = Program.update(for: event, state: &state) { _ in }
        switch result {
        case .success:
            reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .failure(let failure):
            return failure
        }
    }

    func expectUpdate(for event: Event, state: State, file: StaticString = #file, line: Int = #line) -> Update<Program>? {
        var state = state
        var actions: [Action] = []
        let result = Program.update(for: event, state: &state) { action in
            actions.append(action)
        }
        switch result {
        case .success:
            return Update(state: state, actions: Lens(content: actions))
        case .failure(let failure):
            reportUnexpectedFailure(failure, file: file, line: line)
            return nil
        }
    }

    func expectStart(with seed: Seed, file: StaticString = #file, line: Int = #line) -> Start<Program>? {
        var actions: [Action] = []
        let result = Program.start(with: seed) { action in
            actions.append(action)
        }
        switch result {
        case .success(let state):
            return Start(state: state, actions: Lens(content: actions))
        case .failure(let failure):
            reportUnexpectedFailure(failure, file: file, line: line)
            return nil
        }
    }

    func expectView(for state: State, file: StaticString = #file, line: Int = #line) -> View? {
        let result = Program.view(for: state)
        switch result {
        case .success(let view):
            return view
        case .failure(let failure):
            reportUnexpectedFailure(failure, file: file, line: line)
            return nil
        }
    }

    private func reportUnexpectedSuccess(file: StaticString = #file, line: Int = #line) {
        fail("Unexpected success", file: file, line: line)
    }

    private func reportUnexpectedFailure<Failure>(_ failure: Failure, file: StaticString = #file, line: Int = #line) {
        fail("Unexpected failure", subject: failure)
    }

    private func fail(_ event: String, subject: Any, file: StaticString = #file, line: Int = #line) {
        fail(event + ":" + " " + String(describing: subject), file: file, line: line)
    }

    private func fail(_ event: String, file: StaticString = #file, line: Int = #line) {
        failureReporter(event, file, UInt(line))
    }

}

public extension Tests {

    func expect<T>(_ value: T, _ expectedValue: T, file: StaticString = #file, line: Int = #line) {
        let value = String(describing: value)
        let expectedValue = String(describing: expectedValue)
        if value != expectedValue {
            let event = value + " is not equal to " + expectedValue
            failureReporter(event, file, UInt(line))
        }
    }

}

public typealias Start<Program: Elm.Program> = TestResult<Program>
public typealias Update<Program: Elm.Program> = TestResult<Program>

public struct TestResult<Program: Elm.Program> {

    typealias State = Program.State
    typealias Action = Program.Action

    public let state: State
    public let actions: Lens<Action>

}

public extension TestResult {

    var action: Action? {
        guard actions.content.count == 1 else {
            return nil
        }
        return actions[0]
    }

}

public struct Lens<T> {

    let content: [T]

    public subscript (_ index: Int) -> T? {
        guard content.indices.contains(index) else {
            return nil
        }
        return content[index]
    }

}

//
// MARK: -
// MARK: Utilities
//

private struct StandardError: TextOutputStream {
    public mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

private var standardError = StandardError()
