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

    associatedtype Flags = Empty
    associatedtype Message
    associatedtype Model
    associatedtype Command = Empty
    associatedtype View
    associatedtype Failure = Empty

    static func start(with flags: Flags) throws -> Model
    static func update(for message: Message, model: inout Model, perform: (Command) -> Void) throws
    static func view(for model: Model) throws -> View

}

public extension Module where Flags == Empty {

    static func makeProgram() -> Program<Self> {
        return Program<Self>(module: self, flags: Empty())
    }

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

extension Delegate where Module.Command == Empty {

    func program(_ program: Program<Module>, didEmit command: Module.Command) {}

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
            model = try module.start(with: flags)
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
        for message in messages {
            do {
                var commands: [Command] = []
                try module.update(for: message, model: &model) { command in
                    commands.append(command)
                }
                commands.forEach(sendCommand)
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
    }

    private static func makeView(module: Module.Type, model: Model) -> View {
        do {
            return try module.view(for: model)
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
// MARK: Test
//

public protocol TestCase: class {

    associatedtype Module: Elm.Module

    typealias Flags = Module.Flags
    typealias Message = Module.Message
    typealias Model = Module.Model
    typealias Command = Module.Command
    typealias View = Module.View
    typealias Failure = Module.Failure

    var failureReporter: FailureReporter { get }

}

public extension TestCase {

    func expect<T>(_ value: T, _ expectedValue: T, file: StaticString = #file, line: Int = #line) {
        let value = String(describing: value)
        let expectedValue = String(describing: expectedValue)
        if value != expectedValue {
            let message = value + " is not equal to " + expectedValue
            failureReporter(message, file, UInt(line))
        }
    }

}

public extension TestCase {

    func makeTest(flags: Flags) -> FlagsTest<Module> {
        return FlagsTest(module: Module.self, flags: flags, failureReporter: failureReporter)
    }

}

public struct FlagsTest<Module: Elm.Module>: Test {

    typealias Flags = Module.Flags
    typealias Model = Module.Model
    typealias Failure = Module.Failure

    public let module: Module.Type
    public let flags: Flags

    let failureReporter: FailureReporter

}

public extension FlagsTest {

    func expectModel(file: StaticString = #file, line: Int = #line) -> Model? {
        do {
            return try module.start(with: flags)
        } catch {
            logUnknownFailure(error, file: file, line: line)
            return nil
        }
    }

    func expectFailure(file: StaticString = #file, line: Int = #line) -> Failure? {
        do {
            _ = try module.start(with: flags)
            logUnexpectedSuccess(file: file, line: line)
            return nil
        } catch {
            if let failure = error as? Failure { return failure }
            logUnknownFailure(error, file: file, line: line)
            return nil
        }
    }

}

public extension TestCase {

    func makeTest(model: Model) -> ModelTest<Module> {
        return ModelTest(module: Module.self, model: model, failureReporter: failureReporter)
    }

}

public struct ModelTest<Module: Elm.Module>: Test {

    typealias Message = Module.Message
    typealias Model = Module.Model
    typealias Command = Module.Command
    typealias View = Module.View
    typealias Failure = Module.Failure

    public let module: Module.Type
    public let model: Model

    let failureReporter: FailureReporter
    
}

public extension ModelTest {

    func expectCommands(for message: Message, file: StaticString = #file, line: Int = #line) -> [Command]? {
        do {
            var mutableModel = model
            var commands: [Command] = []
            try module.update(for: message, model: &mutableModel) { command in
                commands.append(command)
            }
            return commands
        } catch {
            logUnexpectedFailure(error, file: file, line: line)
            return nil
        }
    }

    func expectCommand(for message: Message, file: StaticString = #file, line: Int = #line) -> Command? {
        guard let commands = expectCommands(for: message, file: file, line: line) else {
            return nil
        }
        guard let command = commands.first else {
            fail(message: "No commands", subject: commands, file: file, line: line)
            return nil
        }
        guard commands.count == 1 else {
            fail(message: "Multiple commands", subject: commands, file: file, line: line)
            return nil
        }
        return command
    }

    func expectModel(for message: Message, file: StaticString = #file, line: Int = #line) -> Model? {
        do {
            var mutableModel = model
            try module.update(for: message, model: &mutableModel) { command in }
            return mutableModel
        } catch {
            logUnexpectedFailure(error, file: file, line: line)
            return nil
        }
    }

    func expectView(file: StaticString = #file, line: Int = #line) -> View? {
        do {
            return try module.view(for: model)
        } catch {
            logUnexpectedFailure(error, file: file, line: line)
            return nil
        }
    }

    func expectFailure(file: StaticString = #file, line: Int = #line) -> Failure? {
        do {
            _ = try module.view(for: model)
            logUnexpectedSuccess(file: file, line: line)
            return nil
        } catch {
            if let failure = error as? Failure { return failure }
            logUnknownFailure(error, file: file, line: line)
            return nil
        }
    }

    func expectFailure(for message: Message, file: StaticString = #file, line: Int = #line) -> Failure? {
        do {
            var mutableModel = model
            try module.update(for: message, model: &mutableModel) { command in }
            logUnexpectedSuccess(file: file, line: line)
            return nil
        } catch {
            if let failure = error as? Failure { return failure }
            logUnknownFailure(error, file: file, line: line)
            return nil
        }
    }

}

protocol Test {

    var failureReporter: FailureReporter { get }

}

extension Test {

    func logUnexpectedSuccess(file: StaticString = #file, line: Int = #line) {
        fail(message: "Unexpected success", file: file, line: line)
    }

    func logUnexpectedFailure(_ failure: Error, file: StaticString = #file, line: Int = #line) {
        fail(message: "Unexpected failure", subject: failure, file: file, line: line)
    }

    func logUnknownFailure(_ failure: Error, file: StaticString = #file, line: Int = #line) {
        fail(message: "Unknown failure", subject: failure, file: file, line: line)
    }

    func fail<T>(message: String, subject: T, file: StaticString = #file, line: Int = #line) {
        let message = message + ":" + " " + String(describing: subject)
        fail(message: message, file: file, line: line)
    }

    private func fail(message: String, file: StaticString = #file, line: Int = #line) {
        failureReporter(message, file, UInt(line))
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

let lineBreak = "\n"

// XCTFail
public typealias FailureReporter = (
    String, // message
    StaticString, // file
    UInt // line
    ) -> Void

public struct Empty {}
