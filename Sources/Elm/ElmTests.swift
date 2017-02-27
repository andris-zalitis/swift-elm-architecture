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

import XCTest

@testable import Elm

//
// MARK: -
// MARK: Tests
//

class ElmTests: XCTestCase {

    //
    // MARK: -
    // MARK: Memory
    //

    func testWeakDelegate() {

        var recorder: DataRecorder? = DataRecorder()

        _ = Counter.makeProgram(delegate: recorder!, seed: .init(count: 0))

        weak var weakRecorder: DataRecorder? = recorder
        recorder = nil

        XCTAssertNil(weakRecorder)

    }

    //
    // MARK: -
    // MARK: Threading
    //

    func testDelegateStartOnMainThread() {

        let recorder = ThreadRecorder()

        let didUpdateView = expectation(description: "")
        let didEmitCommand = expectation(description: "")
        recorder.didUpdateView = didUpdateView.fulfill
        recorder.didEmitCommand = didEmitCommand.fulfill

        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation {
            _ = Counter.makeProgram(delegate: recorder, seed: .init())
        }

        waitForExpectations(timeout: 60) { _ in
            XCTAssertEqual(recorder.didUpdateViewOnThread, Thread.main)
            XCTAssertEqual(recorder.didEmitCommandOnThread, Thread.main)
        }

    }

    func testDelegateUpdateOnMainThread() {

        let recorder = ThreadRecorder()
        let program = Counter.makeProgram(delegate: recorder, seed: .init())

        let didUpdateView = expectation(description: "")
        let didEmitCommand = expectation(description: "")
        recorder.didUpdateView = didUpdateView.fulfill
        recorder.didEmitCommand = didEmitCommand.fulfill

        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation {
            program.dispatch(.increment)
        }

        waitForExpectations(timeout: 60) { _ in
            XCTAssertEqual(recorder.didUpdateViewOnThread, Thread.main)
            XCTAssertEqual(recorder.didEmitCommandOnThread, Thread.main)
        }

    }

    //
    // MARK: -
    // MARK: Data
    //

    func testDispatch() {

        let recorder = DataRecorder()
        let program = Counter.makeProgram(delegate: recorder, seed: .init(count: 1))

        // Start

        XCTAssertEqual(program.view, View(counterText: "1"))

        XCTAssertEqual(recorder.commands.count, 1)
        XCTAssertEqual(recorder.commands.last, .log("Did start"))

        XCTAssertEqual(recorder.views.count, 1)
        XCTAssertEqual(recorder.views.last, View(counterText: "1"))

        // Event 1

        program.dispatch(.increment)

        XCTAssertEqual(program.view, View(counterText: "2"))

        XCTAssertEqual(recorder.commands.count, 2)
        XCTAssertEqual(recorder.commands.last, .log("Did increment"))

        XCTAssertEqual(recorder.views.count, 2)
        XCTAssertEqual(recorder.views.last, View(counterText: "2"))

        // Event 2

        program.dispatch(.decrement)

        XCTAssertEqual(program.view, View(counterText: "1"))

        XCTAssertEqual(recorder.commands.count, 3)
        XCTAssertEqual(recorder.commands.last, .log("Did decrement"))

        XCTAssertEqual(recorder.views.count, 3)
        XCTAssertEqual(recorder.views.last, View(counterText: "1"))

    }

    func testDispatchMultipleEvents() {

        let recorder = DataRecorder()
        let program = Counter.makeProgram(delegate: recorder, seed: .init(count: 2))

        program.dispatch(.increment, .decrement)

        XCTAssertEqual(recorder.commands, [
            .log("Did start"),
            .log("Did increment"),
            .log("Did decrement")
            ]
        )

        XCTAssertEqual(recorder.views, [
            .init(counterText: "2"),
            .init(counterText: "2")
            ]
        )

    }

}

//
// MARK: -
// MARK: Shortcuts
//

typealias Seed = Counter.Seed
typealias Event = Counter.Event
typealias View = Counter.View
typealias Model = Counter.Model
typealias Command = Counter.Command

extension Seed {

    init() {
        count = 0
    }

}

//
// MARK: -
// MARK: Module
//

struct Counter: Module {

    struct Seed {
        let count: Int
    }

    enum Event {
        case increment
        case decrement
    }

    struct Model {
        var count: Int
    }

    struct View {
        let counterText: String
    }

    enum Command {
        case log(String)
    }

    enum Failure {}

    static func start(with seed: Seed, perform: (Command) -> Void) throws -> Model {
        perform(.log("Did start"))
        return Model(count: seed.count)
    }

    static func update(for event: Event, model: inout Model, perform: (Command) -> Void) throws {
        switch event {
        case .increment:
            model.count += 1
            perform(.log("Did increment"))
        case .decrement:
            model.count -= 1
            perform(.log("Did decrement"))
        }
    }

    static func view(for model: Model) -> View {
        let counterText = String(model.count)
        return View(counterText: counterText)
    }

}

//
// MARK: -
// MARK: Equatable conformances
//

extension Command: Equatable {
    static func ==(lhs: Command, rhs: Command) -> Bool {
        return String(describing: lhs) == String(describing: rhs)
    }
}

extension View: Equatable {
    static func ==(lhs: View, rhs: View) -> Bool {
        return String(describing: lhs) == String(describing: rhs)
    }
}

//
// MARK: -
// MARK: Recorders
//

final class DataRecorder: Delegate {

    typealias Module = Counter

    //
    // MARK: -
    // MARK: Capture views
    //

    var views: [View] = []

    func program(_ program: Program<Counter>, didUpdate view: Counter.View) {
        views.append(view)
    }

    //
    // MARK: -
    // MARK: Capture commands
    //

    var commands: [Command] = []

    func program(_ program: Program<Counter>, didEmit command: Counter.Command) {
        commands.append(command)
    }

}

final class ThreadRecorder: Elm.Delegate {

    var didUpdateView: () -> Void = { _ in }
    private(set) var didUpdateViewOnThread: Thread?

    var didEmitCommand: () -> Void = { _ in }
    private(set) var didEmitCommandOnThread: Thread?

    func program(_ program: Program<Counter>, didUpdate view: Counter.View) {
        didUpdateViewOnThread = Thread.current
        didUpdateView()
    }

    func program(_ program: Program<Counter>, didEmit command: Counter.Command) {
        didEmitCommandOnThread = Thread.current
        didEmitCommand()
    }

}
