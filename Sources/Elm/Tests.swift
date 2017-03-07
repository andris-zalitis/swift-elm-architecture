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

public protocol Tests: class {

    associatedtype Program: Elm.Program

    typealias Seed = Program.Seed
    typealias State = Program.State
    typealias Event = Program.Event
    typealias Action = Program.Action
    typealias View = Program.View
    typealias Failure = Program.Failure

    func fail(_ message: String, file: StaticString, line: Int)

}

public extension Tests {

    public typealias Start<State, Action> = Result<State, Action>

    func expectStart(with seed: Seed, file: StaticString = #file, line: Int = #line) -> Start<State, Action>? {
        switch Program.start(with: seed) {
        case .state(let state, perform: let actions):
            return Start<State, Action>(state: state, actions: actions)
        case .failure(let failure):
            reportUnexpectedFailure(failure, file: file, line: line)
            return nil
        }
    }

    func expectFailure(with seed: Seed, file: StaticString = #file, line: Int = #line) -> Failure? {
        switch Program.start(with: seed) {
        case .state:
            reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .failure(let failure):
            return failure
        }
    }

}

public extension Tests {

    public typealias Update<State, Action> = Result<State, Action>

    func expectUpdate(for event: Event, state: State, file: StaticString = #file, line: Int = #line) -> Update<State, Action>? {
        switch Program.update(for: event, state: state) {
        case .state(let state, perform: let actions):
            return Start<State, Action>(state: state, actions: actions)
        case .failure(let failure):
            reportUnexpectedFailure(failure, file: file, line: line)
            return nil
        }
    }

    func expectFailure(for event: Event, state: State, file: StaticString = #file, line: Int = #line) -> Failure? {
        switch Program.update(for: event, state: state) {
        case .state:
            reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .failure(let failure):
            return failure
        }
    }

}

public extension Tests {

    func expectView(for state: State, file: StaticString = #file, line: Int = #line) -> View? {
        switch Program.view(for: state) {
        case .view(let view):
            return view
        case .failure(let failure):
            reportUnexpectedFailure(failure, file: file, line: line)
            return nil
        }
    }

    func expectFailure(for state: State, file: StaticString = #file, line: Int = #line) -> Failure? {
        switch Program.view(for: state) {
        case .view:
            reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .failure(let failure):
            return failure
        }
    }

}

public extension Tests {

    func expect<T>(_ value: T, _ expectedValue: T, file: StaticString = #file, line: Int = #line) {
        let value = String(describing: value)
        let expectedValue = String(describing: expectedValue)
        if value != expectedValue {
            let event = value + " is not equal to " + expectedValue
            fail(event, file: file, line: line)
        }
    }

}

extension Tests {

    func reportUnexpectedSuccess(file: StaticString, line: Int) {
        fail("Unexpected success", file: file, line: line)
    }

    func reportUnexpectedFailure<Failure>(_ failure: Failure, file: StaticString, line: Int) {
        fail("Unexpected failure: \(failure)", file: file, line: line)
    }

}

public struct Result<State, Action> {

    public let state: State
    public let actions: [Int: Action]

    init(state: State, actions: [Action]) {
        self.state = state
        self.actions = {
            var newActions: [Int: Action] = [:]
            for (index, action) in actions.enumerated() {
                newActions[index] = action
            }
            return newActions
        }()
    }

}
