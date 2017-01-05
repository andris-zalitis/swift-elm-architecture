// The MIT License (MIT)
//
// Copyright (c) 2016 Rudolf Adamkovič
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

    func testReferenceDelegateWeakly() {

        var recorder: Recorder? = Recorder()

        let program = Counter.makeProgram()
        program.setDelegate(recorder!)

        weak var weakRecorder: Recorder? = recorder
        recorder = nil

        XCTAssertNil(weakRecorder)

    }

    func testRemoveDelegate() {

        let recorder = Recorder()
        let program = Counter.makeProgram()

        program.setDelegate(recorder)

        recorder.commands.removeAll()
        recorder.views.removeAll()

        program.unsetDelegate()

        program.dispatch(.increment)
        program.dispatch(.decrement)

        XCTAssertTrue(recorder.commands.isEmpty)
        XCTAssertTrue(recorder.views.isEmpty)

    }

    //
    // MARK: -
    // MARK: Dispatch
    //

    func testDispatch() {

        let recorder = Recorder()
        let program = Counter.makeProgram()
        program.setDelegate(recorder)

        //
        // MARK: -
        // MARK: Initialization
        //

        XCTAssertEqual(program.view, View(counterText: "0"))

        XCTAssertEqual(recorder.commands.count, 0)

        XCTAssertEqual(recorder.views.count, 1)
        XCTAssertEqual(recorder.views[0], View(counterText: "0"))

        //
        // MARK: -
        // MARK: First message
        //

        program.dispatch(.increment)

        XCTAssertEqual(program.view, View(counterText: "1"))

        XCTAssertEqual(recorder.commands.count, 1)
        XCTAssertEqual(recorder.commands[0], .log("Did increment"))

        XCTAssertEqual(recorder.views.count, 2)
        XCTAssertEqual(recorder.views[0], View(counterText: "0"))
        XCTAssertEqual(recorder.views[1], View(counterText: "1"))

        //
        // MARK: -
        // MARK: Second message
        //

        program.dispatch(.decrement)

        XCTAssertEqual(program.view, View(counterText: "0"))

        XCTAssertEqual(recorder.commands.count, 2)
        XCTAssertEqual(recorder.commands[0], .log("Did increment"))
        XCTAssertEqual(recorder.commands[1], .log("Did decrement"))

        XCTAssertEqual(recorder.views.count, 3)
        XCTAssertEqual(recorder.views[0], View(counterText: "0"))
        XCTAssertEqual(recorder.views[1], View(counterText: "1"))
        XCTAssertEqual(recorder.views[2], View(counterText: "0"))

    }

    func testDispatchMultipleMessages() {

        let recorder = Recorder()
        let program = Counter.makeProgram()

        program.setDelegate(recorder)

        program.dispatch(.increment, .decrement)

        XCTAssertEqual(recorder.commands.count, 2)
        XCTAssertEqual(recorder.commands[0], .log("Did increment"))
        XCTAssertEqual(recorder.commands[1], .log("Did decrement"))

        XCTAssertEqual(recorder.views.count, 2)
        XCTAssertEqual(recorder.views[0], View(counterText: "0"))
        XCTAssertEqual(recorder.views[1], View(counterText: "0"))

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

    struct Flags {}

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

    static func model(loading flags: Flags) -> Model {
        return Model(count: 0)
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

extension Counter {

    static func makeProgram() -> Program<Counter> {
        let flags = Flags()
        return makeProgram(flags: flags)
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
