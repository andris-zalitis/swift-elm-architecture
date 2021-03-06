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

public protocol Tests: class, ErrorReporter {

    associatedtype Program: Elm.Program

    typealias Seed = Program.Seed
    typealias State = Program.State
    typealias Event = Program.Event
    typealias Action = Program.Action
    typealias View = Program.View
    typealias Error = Program.Error

}

public extension Tests {

    func expect<T>(_ value: T?, equals expectedValue: T, file: StaticString = #file, line: Int = #line) {
        guard let actualValue = value else {
            let message = "nil is not equal to \(expectedValue)"
            fail(message, file: file, line: line)
            return
        }
        expect(actualValue, equals: expectedValue, file: file, line: line)
    }

    func expect<T>(_ value: T, equals expectedValue: T, file: StaticString = #file, line: Int = #line) {
        let value = String(describing: value)
        let expectedValue = String(describing: expectedValue)
        if value != expectedValue {
            let message = "'\(value)' is not equal to '\(expectedValue)'"
            fail(message, file: file, line: line)
        }
    }

}

public extension Tests {

    var program: TestProgram<Program> {
        return .init(errorReporter: self)
    }

}

// MARK: - Test program

public struct TestProgram<Program: Elm.Program> {

    typealias Seed = Program.Seed
    typealias State = Program.State
    typealias Event = Program.Event
    typealias Action = Program.Action
    typealias View = Program.View
    typealias Error = Program.Error

    let errorReporter: ErrorReporter

}

// MARK: - Start

public extension TestProgram {

    func start(with seed: Seed) -> StartResult<Program> {
        let start = Program.start(with: seed)
        return .init(data: start.data, errorReporter: errorReporter)
    }

}

public extension TestProgram where Program.Seed == Void {

    func start() -> StartResult<Program> {
        let start = Program.start(with: Void())
        return .init(data: start.data, errorReporter: errorReporter)
    }

}

public struct StartResult<Program: Elm.Program> {

    typealias Event = Program.Event
    typealias State = Program.State
    typealias Action = Program.Action
    typealias Error = Program.Error

    let data: StartData<Program>
    let errorReporter: ErrorReporter

    public func expectState(file: StaticString = #file, line: Int = #line) -> State? {
        switch data {
        case .next(state: let state, actions: _, event: _):
            return state
        case .error(let error):
            errorReporter.reportUnexpectedError(error, file: file, line: line)
            return nil
        }
    }

    public func expectActions(file: StaticString = #file, line: Int = #line) -> [Int: Action] {
        switch data {
        case .next(state: _, actions: let actions, event: _):
            var newActions: [Int: Action] = [:]
            for (index, action) in actions.enumerated() {
                newActions[index] = action
            }
            return newActions
        case .error(let error):
            errorReporter.reportUnexpectedError(error, file: file, line: line)
            return [:]
        }
    }

    public func expectEvent(file: StaticString = #file, line: Int = #line) -> Event? {
        switch data {
        case .next(state: _, actions: _, event: let event):
            return event
        case .error(let error):
            errorReporter.reportUnexpectedError(error, file: file, line: line)
            return nil
        }
    }

    public func expectError(file: StaticString = #file, line: Int = #line) -> Error? {
        switch data {
        case .next:
            errorReporter.reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .error(let error):
            return error
        }
    }

}

// MARK: - Update

public extension TestProgram {

    func update(for event: Event, state: State) -> UpdateResult<Program> {
        let update = Program.update(for: event, state: state)
        return .init(data: update.data, errorReporter: errorReporter)
    }

}

public struct UpdateResult<Program: Elm.Program> {

    typealias Event = Program.Event
    typealias State = Program.State
    typealias Action = Program.Action
    typealias Error = Program.Error

    let data: UpdateData<Program>
    let errorReporter: ErrorReporter

    public func expectState(file: StaticString = #file, line: Int = #line) -> State? {
        switch data {
        case .next(state: let state, actions: _, event: _):
            return state
        case .error(let error):
            errorReporter.reportUnexpectedError(error, file: file, line: line)
            return nil
        }
    }

    public func expectActions(file: StaticString = #file, line: Int = #line) -> [Int: Action] {
        switch data {
        case .next(state: _, actions: let actions, event: _):
            var newActions: [Int: Action] = [:]
            for (index, action) in actions.enumerated() {
                newActions[index] = action
            }
            return newActions
        case .error(let error):
            errorReporter.reportUnexpectedError(error, file: file, line: line)
            return [:]
        }
    }

    public func expectEvent(file: StaticString = #file, line: Int = #line) -> Event? {
        switch data {
        case .next(state: _, actions: _, event: let event):
            return event
        case .error(let error):
            errorReporter.reportUnexpectedError(error, file: file, line: line)
            return nil
        }
    }

    public func expectError(file: StaticString = #file, line: Int = #line) -> Error? {
        switch data {
        case .next:
            errorReporter.reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .error(let error):
            return error
        }
    }

}

// MARK: - Render

public extension TestProgram {

    func render(with state: State) -> RenderResult<Program> {
        let render = Program.render(with: state)
        return .init(data: render.data, errorReporter: errorReporter)
    }

}

public struct RenderResult<Program: Elm.Program> {

    typealias View = Program.View
    typealias Error = Program.Error

    let data: RenderData<Program>
    let errorReporter: ErrorReporter

    public func expectView(file: StaticString = #file, line: Int = #line) -> View? {
        switch data {
        case .view(let view):
            return view
        case .error(let error):
            errorReporter.reportUnexpectedError(error, file: file, line: line)
            return nil
        }
    }

    public func expectError(file: StaticString = #file, line: Int = #line) -> Error? {
        switch data {
        case .view:
            errorReporter.reportUnexpectedSuccess(file: file, line: line)
            return nil
        case .error(let error):
            return error
        }
    }

}

// MARK: - Error reporter

public protocol ErrorReporter {

    func fail(_ message: String, file: StaticString, line: Int)

}

extension ErrorReporter {

    func reportUnexpectedSuccess(file: StaticString, line: Int) {
        fail("Unexpected success", file: file, line: line)
    }

    func reportUnexpectedError<Error>(_ error: Error, file: StaticString, line: Int) {
        fail("Unexpected error: \(error)", file: file, line: line)
    }

}
