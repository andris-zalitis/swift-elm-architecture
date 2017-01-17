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
    // MARK: Delegate
    //

    func testWeakDelegate() {

        var recorder: Recorder? = Recorder()

        _ = Counter.makeProgram(delegate: recorder!, flags: .init(count: 0))

        weak var weakRecorder: Recorder? = recorder
        recorder = nil

        XCTAssertNil(weakRecorder)

    }

    //
    // MARK: -
    // MARK: Dispatch
    //

    func testDispatch() {

        let recorder = Recorder()
        let program = Counter.makeProgram(delegate: recorder, flags: .init(count: 1))

        //
        // MARK: -
        // MARK: Initialization
        //

        XCTAssertEqual(program.view, View(counterText: "1"))

        XCTAssertEqual(recorder.commands.count, 1)
        XCTAssertEqual(recorder.commands.last, .log("Did start"))

        XCTAssertEqual(recorder.views.count, 1)
        XCTAssertEqual(recorder.views.last, View(counterText: "1"))

        //
        // MARK: -
        // MARK: First message
        //

        program.dispatch(.increment)

        XCTAssertEqual(program.view, View(counterText: "2"))

        XCTAssertEqual(recorder.commands.count, 2)
        XCTAssertEqual(recorder.commands.last, .log("Did increment"))

        XCTAssertEqual(recorder.views.count, 2)
        XCTAssertEqual(recorder.views.last, View(counterText: "2"))

        //
        // MARK: -
        // MARK: Second message
        //

        program.dispatch(.decrement)

        XCTAssertEqual(program.view, View(counterText: "1"))

        XCTAssertEqual(recorder.commands.count, 3)
        XCTAssertEqual(recorder.commands.last, .log("Did decrement"))

        XCTAssertEqual(recorder.views.count, 3)
        XCTAssertEqual(recorder.views.last, View(counterText: "1"))

    }

    func testDispatchMultipleMessages() {

        let recorder = Recorder()
        let program = Counter.makeProgram(delegate: recorder, flags: .init(count: 2))

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

typealias Message = Counter.Message
typealias View = Counter.View
typealias Model = Counter.Model
typealias Command = Counter.Command

//
// MARK: -
// MARK: Module
//

struct Counter: Module {

    struct Flags {
        let count: Int
    }

    enum Message {
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

    static func start(loading flags: Flags, perform: (Command) -> Void) throws -> Model {
        perform(.log("Did start"))
        return Model(count: flags.count)
    }

    static func update(for message: Message, model: inout Model, perform: (Command) -> Void) throws {
        switch message {
        case .increment:
            model.count += 1
            perform(.log("Did increment"))
        case .decrement:
            model.count -= 1
            perform(.log("Did decrement"))
        }
    }

    static func view(presenting model: Model) -> View {
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
// MARK: Recorder
//

final class Recorder: Delegate {

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
