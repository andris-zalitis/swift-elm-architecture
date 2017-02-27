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
// MARK: Module
//

public protocol Module {

    associatedtype Seed
    associatedtype Event
    associatedtype State
    associatedtype Action
    associatedtype View
    associatedtype Failure

    static func start(with seed: Seed, perform: (Action) -> Void) throws -> State
    static func update(for event: Event, state: inout State, perform: (Action) -> Void) throws
    static func view(for state: State) throws -> View

}

public extension Module {

    static func makeProgram<Delegate: Elm.Delegate>(delegate: Delegate, seed: Seed) -> Program<Self> where Delegate.Module == Self {
        return Program<Self>(module: self, delegate: delegate, seed: seed)
    }

}

//
// MARK: -
// MARK: Delegate
//

public protocol Delegate: class {

    associatedtype Module: Elm.Module

    typealias Action = Module.Action
    typealias View = Module.View

    func program(_ program: Program<Module>, didRequest action: Action)
    func program(_ program: Program<Module>, didUpdate view: View)

}

//
// MARK: -
// MARK: Program
//

public final class Program<Module: Elm.Module> {

    typealias Seed = Module.Seed
    typealias Event = Module.Event
    typealias State = Module.State
    typealias Action = Module.Action
    typealias View = Module.View

    private var state: State
    public private(set) lazy var view: View = Program.makeView(module: Module.self, state: self.state)

    private typealias ViewSink = (View) -> Void
    private typealias ActionSink = (Action) -> Void

    private var sendView: ViewSink = { _ in }
    private var sendAction: ActionSink = { _ in }

    init<Delegate: Elm.Delegate>(module: Module.Type, delegate: Delegate, seed: Seed) where Delegate.Module == Module {
        var actions: [Action] = []
        do {
            state = try module.start(with: seed) { action in
                actions.append(action)
            }
        } catch {
            print("FATAL: \(module).start function did throw!", to: &standardError)
            dump(error, to: &standardError, name: "Error")
            dump(seed, to: &standardError, name: "Seed")
            fatalError()
        }
        sendView = { [weak delegate] view in
            delegate?.program(self, didUpdate: view)
        }
        sendAction = { [weak delegate] action in
            delegate?.program(self, didRequest: action)
        }
        updateDelegate(with: actions)
    }

    public func dispatch(_ events: Event...) {
        var actions: [Action] = []
        for event in events {
            do {
                try Module.update(for: event, state: &state) { action in
                    actions.append(action)
                }
            } catch {
                print("FATAL: \(Module.self).update function did throw!", to: &standardError)
                dump(error, to: &standardError, name: "Error")
                dump(event, to: &standardError, name: "Event")
                dump(state, to: &standardError, name: "State")
                fatalError()
            }
        }
        view = Program.makeView(module: Module.self, state: state)
        updateDelegate(with: actions)
    }

    private static func makeView(module: Module.Type, state: State) -> View {
        do {
            return try module.view(for: state)
        } catch {
            print("FATAL: \(module).view function did throw!", to: &standardError)
            dump(error, to: &standardError, name: "Error")
            dump(state, to: &standardError, name: "State")
            fatalError()
        }
    }

    private func updateDelegate(with actions: [Action]) {
        guard Thread.isMainThread else {
            OperationQueue.main.addOperation { [weak program = self] in
                program?.updateDelegate(with: actions)
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

    associatedtype Module: Elm.Module

    typealias Seed = Module.Seed
    typealias State = Module.State
    typealias Event = Module.Event
    typealias Action = Module.Action
    typealias View = Module.View
    typealias Failure = Module.Failure

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
        do {
            _ = try Module.start(with: seed) { _ in }
            reportUnexpectedSuccess()
            return nil
        } catch {
            guard let failure = error as? Failure else {
                reportUnknownFailure(error, file: file, line: line)
                return nil
            }
            return failure
        }
    }

    func expectFailure(for state: State, file: StaticString = #file, line: Int = #line) -> Failure? {
        do {
            _ = try Module.view(for: state)
            reportUnexpectedSuccess()
            return nil
        } catch {
            guard let failure = error as? Failure else {
                reportUnknownFailure(error, file: file, line: line)
                return nil
            }
            return failure
        }
    }

    func expectFailure(for event: Event, state: State, file: StaticString = #file, line: Int = #line) -> Failure? {
        do {
            var state = state
            try Module.update(for: event, state: &state) { _ in }
            reportUnexpectedSuccess()
            return nil
        } catch {
            guard let failure = error as? Failure else {
                reportUnknownFailure(error, file: file, line: line)
                return nil
            }
            return failure
        }
    }

    func expectUpdate(for event: Event, state: State, file: StaticString = #file, line: Int = #line) -> Update<Module>? {
        do {
            var state = state
            var actions: [Action] = []
            try Module.update(for: event, state: &state) { action in
                actions.append(action)
            }
            return Update(state: state, actions: Lens(content: actions))
        } catch {
            reportUnexpectedFailure(error, file: file, line: line)
            return nil
        }
    }

    func expectStart(with seed: Seed, file: StaticString = #file, line: Int = #line) -> Start<Module>? {
        do {
            var actions: [Action] = []
            let state = try Module.start(with: seed) { action in
                actions.append(action)
            }
            return Start(state: state, actions: Lens(content: actions))
        } catch {
            reportUnexpectedFailure(error, file: file, line: line)
            return nil
        }
    }

    func expectView(for state: State, file: StaticString = #file, line: Int = #line) -> View? {
        do {
            return try Module.view(for: state)
        } catch {
            reportUnexpectedFailure(error, file: file, line: line)
            return nil
        }
    }

    private func reportUnexpectedSuccess(file: StaticString = #file, line: Int = #line) {
        fail("Unexpected success", file: file, line: line)
    }

    private func reportUnknownFailure<Failure>(_ failure: Failure, file: StaticString = #file, line: Int = #line) {
        fail("Unknown failure", subject: failure)
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

public typealias Start<Module: Elm.Module> = Result<Module>
public typealias Update<Module: Elm.Module> = Result<Module>

public struct Result<Module: Elm.Module> {

    typealias State = Module.State
    typealias Action = Module.Action

    public let state: State
    public let actions: Lens<Action>

}

public extension Result {

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
