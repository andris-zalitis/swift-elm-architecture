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

    private func reportUnexpectedSuccess(file: StaticString, line: Int) {
        fail("Unexpected success", file: file, line: line)
    }

    private func reportUnexpectedFailure<Failure>(_ failure: Failure, file: StaticString, line: Int) {
        fail("Unexpected failure: \(failure)", file: file, line: line)
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
