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

public protocol Tests: class, FailureReporter {

    associatedtype Program: Elm.Program

    typealias Seed = Program.Seed
    typealias State = Program.State
    typealias Event = Program.Event
    typealias Action = Program.Action
    typealias View = Program.View
    typealias Failure = Program.Failure

}

public protocol FailureReporter {

    func fail(_ message: String, file: StaticString, line: Int)

}

extension FailureReporter {

    func reportUnexpectedSuccess(file: StaticString, line: Int) {
        fail("Unexpected success", file: file, line: line)
    }

    func reportUnexpectedFailure<Failure>(_ failure: Failure, file: StaticString, line: Int) {
        fail("Unexpected failure: \(failure)", file: file, line: line)
    }

}

public extension Tests {

    func start(with seed: Seed) -> StartResult<Program> {
        let start = Program.start(with: seed)
        return .init(start: start, failureReporter: self)
    }

    func update(for event: Event, state: State) -> UpdateResult<Program> {
        let update = Program.update(for: event, state: state)
        return .init(update: update, failureReporter: self)
    }

    func render(with state: State) -> RenderResult<Program> {
        let render = Program.render(with: state)
        return .init(render: render, failureReporter: self)
    }

}

public enum Expectation {

    public enum State { case state }
    public enum Actions { case actions }
    public enum View { case view }
    public enum Failure { case failure }

}

public struct StartResult<Program: Elm.Program> {

    typealias State = Program.State
    typealias Action = Program.Action
    typealias Failure = Program.Failure

    let start: Start<Program>
    let failureReporter: FailureReporter

    func expect(_: Expectation.State, file: StaticString = #file, line: Int = #line) -> State? {
        switch start.data {
        case .success(state: let state, actions: _):
            return state
        case .failure(let failure):
            failureReporter.reportUnexpectedFailure(failure, file: file, line: line)
            return nil
        }
    }

    func expect(_: Expectation.Actions, file: StaticString = #file, line: Int = #line) -> [Int: Action] {
        switch start.data {
        case .success(state: _, actions: let actions):
            var newActions: [Int: Action] = [:]
            for (index, action) in actions.enumerated() {
                newActions[index] = action
            }
            return newActions
        case .failure(let failure):
            failureReporter.reportUnexpectedFailure(failure, file: file, line: line)
            return [:]
        }
    }

    func expect(_: Expectation.Failure, file: StaticString = #file, line: Int = #line) -> Failure? {
        switch start.data {
        case .success:
            failureReporter.reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .failure(let failure):
            return failure
        }
    }

}

public struct UpdateResult<Program: Elm.Program> {

    typealias State = Program.State
    typealias Action = Program.Action
    typealias Failure = Program.Failure

    let update: Update<Program>
    let failureReporter: FailureReporter

    func expect(_: Expectation.State, file: StaticString = #file, line: Int = #line) -> State? {
        switch update.data {
        case .success(state: let state, actions: _):
            return state
        case .failure(let failure):
            failureReporter.reportUnexpectedFailure(failure, file: file, line: line)
            return nil
        }
    }

    func expect(_: Expectation.Actions, file: StaticString = #file, line: Int = #line) -> [Int: Action] {
        switch update.data {
        case .success(state: _, actions: let actions):
            var newActions: [Int: Action] = [:]
            for (index, action) in actions.enumerated() {
                newActions[index] = action
            }
            return newActions
        case .failure(let failure):
            failureReporter.reportUnexpectedFailure(failure, file: file, line: line)
            return [:]
        }
    }

    func expect(_: Expectation.Failure, file: StaticString = #file, line: Int = #line) -> Failure? {
        switch update.data {
        case .success:
            failureReporter.reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .failure(let failure):
            return failure
        }
    }

}

public struct RenderResult<Program: Elm.Program> {

    typealias View = Program.View
    typealias Failure = Program.Failure

    let render: Render<Program>
    let failureReporter: FailureReporter

    func expect(_: Expectation.View, file: StaticString = #file, line: Int = #line) -> View? {
        switch render.data {
        case .success(view: let view):
            return view
        case .failure(let failure):
            failureReporter.reportUnexpectedFailure(failure, file: file, line: line)
            return nil
        }
    }

    func expect(_: Expectation.Failure, file: StaticString = #file, line: Int = #line) -> Failure? {
        switch render.data {
        case .success:
            failureReporter.reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .failure(let failure):
            return failure
        }
    }

}

public extension Tests {

    func assert<T>(_ value: T, equals expectedValue: T, file: StaticString = #file, line: Int = #line) {
        let value = String(describing: value)
        let expectedValue = String(describing: expectedValue)
        if value != expectedValue {
            let event = value + " is not equal to " + expectedValue
            fail(event, file: file, line: line)
        }
    }

}
