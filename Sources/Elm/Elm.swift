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

//
// MARK: -
// MARK: Module
//

public protocol Module {

    associatedtype Flags
    associatedtype Message
    associatedtype Model
    associatedtype Command
    associatedtype View
    associatedtype Failure

    static func model(loading flags: Flags) throws -> Model
    static func update(for message: Message, model: inout Model, perform: (Command) -> Void) throws
    static func view(presenting model: Model) throws -> View

}

public extension Module {

    static func makeProgram(flags: Flags) -> Program<Self> {
        return Program<Self>(module: self, flags: flags)
    }

}

//
// MARK: -
// MARK: Delegate
//

public protocol Delegate: class {

    associatedtype Module: Elm.Module

    func program(_ program: Program<Module>, didUpdate view: Module.View)
    func program(_ program: Program<Module>, didEmit command: Module.Command)

}

//
// MARK: -
// MARK: Program
//

public final class Program<Module: Elm.Module> {

    //
    // MARK: -
    // MARK: Initialization
    //

    private let module: Module.Type

    typealias Flags = Module.Flags
    typealias Message = Module.Message
    typealias Model = Module.Model
    typealias Command = Module.Command
    typealias View = Module.View

    private var model: Model
    public private(set) lazy var view: View = Program.makeView(module: self.module, model: self.model)

    init(module: Module.Type, flags: Flags) {
        self.module = module
        do {
            model = try module.model(loading: flags)
        } catch {
            print("FATAL: \(module).update function did throw!", to: &standardError)
            dump(error, to: &standardError, name: "Error")
            dump(flags, to: &standardError, name: "Flags")
            fatalError()
        }
    }

    //
    // MARK: -
    // MARK: Delegate
    //

    public func setDelegate<Delegate: Elm.Delegate>(_ delegate: Delegate) where Delegate.Module == Module {
        sendView = { [weak delegate] view in
            delegate?.program(self, didUpdate: view)
        }
        sendCommand = { [weak delegate] command in
            delegate?.program(self, didEmit: command)
        }
        delegate.program(self, didUpdate: view)
    }

    public func unsetDelegate() {
        sendView = { _ in }
        sendCommand = { _ in }
    }

    private typealias ViewSink = (View) -> Void
    private typealias CommandSink = (Command) -> Void

    private var sendView: ViewSink = { _ in }
    private var sendCommand: CommandSink = { _ in }

    //
    // MARK: -
    // MARK: Dispatch
    //

    public func dispatch(_ messages: Message...) {
        var commands: [Command] = []
        for message in messages {
            do {
                try module.update(for: message, model: &model) { command in
                    commands.append(command)
                }
            } catch {
                print("FATAL: \(module).update function did throw!", to: &standardError)
                dump(error, to: &standardError, name: "Error")
                dump(message, to: &standardError, name: "Message")
                dump(model, to: &standardError, name: "Model")
                fatalError()
            }
        }
        view = Program.makeView(module: module, model: model)
        sendView(view)
        commands.forEach(sendCommand)
    }

    private static func makeView(module: Module.Type, model: Model) -> View {
        do {
            return try module.view(presenting: model)
        } catch {
            print("FATAL: \(module).view function did throw!", to: &standardError)
            dump(error, to: &standardError, name: "Error")
            dump(model, to: &standardError, name: "Model")
            fatalError()
        }
    }

}

//
// MARK: -
// MARK: Tests
//

public protocol Tests: class {

    associatedtype Module: Elm.Module

    typealias Flags = Module.Flags
    typealias Model = Module.Model
    typealias Message = Module.Message
    typealias Command = Module.Command
    typealias View = Module.View
    typealias Failure = Module.Failure

    // XCTFail
    typealias FailureReporter = (
        String, // message
        StaticString, // file
        UInt // line
        ) -> Void


    var failureReporter: FailureReporter { get }

}

public extension Tests {

    func expectFailure(loading flags: Flags, file: StaticString = #file, line: Int = #line) -> Failure? {
        do {
            _ = try Module.model(loading: flags)
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

    func expectFailure(presenting model: Model, file: StaticString = #file, line: Int = #line) -> Failure? {
        do {
            _ = try Module.view(presenting: model)
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

    func expectFailure(for message: Message, model: Model, file: StaticString = #file, line: Int = #line) -> Failure? {
        do {
            var model = model
            try Module.update(for: message, model: &model) { _ in }
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

    func expectUpdate(for message: Message, model: Model, file: StaticString = #file, line: Int = #line) -> Update<Module>? {
        do {
            var model = model
            var commands: [Command] = []
            try Module.update(for: message, model: &model) { command in
                commands.append(command)
            }
            return Update(model: model, commands: commands)
        } catch {
            reportUnexpectedFailure(error, file: file, line: line)
            return nil
        }
    }

    func expectModel(loading flags: Flags, file: StaticString = #file, line: Int = #line) -> Model? {
        do {
            return try Module.model(loading: flags)
        } catch {
            reportUnexpectedFailure(error, file: file, line: line)
            return nil
        }
    }

    func expectView(presenting model: Model, file: StaticString = #file, line: Int = #line) -> View? {
        do {
            return try Module.view(presenting: model)
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

    private func fail(_ message: String, subject: Any, file: StaticString = #file, line: Int = #line) {
        fail(message + ":" + " " + String(describing: subject), file: file, line: line)
    }

    private func fail(_ message: String, file: StaticString = #file, line: Int = #line) {
        failureReporter(message, file, UInt(line))
    }

}

public extension Tests {

    func expect(_ value: @autoclosure () -> Bool, file: StaticString = #file, line: Int = #line) {
        expect(value, true, file: file, line: line)
    }

    func expect<T>(_ value: @autoclosure () -> T, _ expectedValue: @autoclosure () -> T, file: StaticString = #file, line: Int = #line) {
        let value = String(describing: value())
        let expectedValue = String(describing: expectedValue())
        if value != expectedValue {
            let message = value + " is not equal to " + expectedValue
            failureReporter(message, file, UInt(line))
        }
    }

}

public struct Update<Module: Elm.Module> {

    typealias Model = Module.Model
    typealias Command = Module.Command

    public let model: Model
    public let commands: [Command]

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

let lineBreak = "\n"
