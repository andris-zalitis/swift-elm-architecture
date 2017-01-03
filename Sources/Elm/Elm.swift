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

    static func start(with flags: Flags) throws -> Model
    static func update(for message: Message, model: inout Model, perform: (Command) -> Void) throws
    static func view(for model: Model) throws -> View

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
// MARK: Start test
//

public protocol StartTest: class, TestBase {

    associatedtype Module: Elm.Module

    var fixture: StartFixture<Module> { get set }

}

public extension StartTest {

    typealias Flags = Module.Flags

    var flags: Flags {
        get {
            guard let flags = fixture.flags else {
                preconditionFailure("Flags not set")
            }
            return flags
        }
        set {
            fixture.flags = newValue
        }
    }

}

public extension StartTest {

    typealias Model = Module.Model

    var model: Model {
        switch fixture.results {
        case .success(let model):
            return model
        case .failure(let failure):
            let failure = String(describing: failure)
            fatalError("Unexpected failure: " + failure)
        case .trap(let trap):
            fatalError(trap)
        }
    }

}

public extension StartTest {

    typealias Failure = Module.Failure

    var failure: Failure? {
        switch fixture.results {
        case .success:
            return nil
        case .failure(let failure):
            return failure
        case .trap(let trap):
            fatalError(trap)
        }
    }

}

public extension StartTest {

    var trap: String? {
        if case .trap(let trap) = fixture.results {
            return trap
        }
        return nil
    }

}

public struct StartFixture<Module: Elm.Module> {

    typealias Flags = Module.Flags
    typealias Failure = Module.Failure

    public init() {}

    var flags: Flags?

    var results: StartResults<Module> {
        guard let flags = flags else {
            return .trap("Flags not set")
        }
        do {
            let model = try Module.start(with: flags)
            return .success(model)
        } catch {
            guard let failure = error as? Failure else {
                return .trap("Foreign failure")
            }
            return .failure(failure)
        }
    }
    
}

enum StartResults<Module: Elm.Module> {

    typealias Model = Module.Model
    typealias Failure = Module.Failure

    case success(Model)
    case failure(Failure)
    case trap(String)

}

//
// MARK: -
// MARK: Update test
//

public protocol UpdateTest: class, TestBase {

    associatedtype Module: Elm.Module

    var fixture: UpdateFixture<Module> { get set }

}

public extension UpdateTest {

    typealias Model = Module.Model

    var model: Model {
        get {
            switch fixture.results {
            case .success(let model, _):
                return model
            case .failure(let failure):
                let failure = String(describing: failure)
                fatalError("Unexpected failure: " + failure)
            case .trap(let trap):
                fatalError(trap)
            }
        }
        set {
            fixture.model = newValue
        }
    }

}

public extension UpdateTest {

    typealias Message = Module.Message

    var message: Message {
        get {
            guard let message = fixture.message else {
                fatalError("Message not set")
            }
            return message
        }
        set {
            fixture.message = newValue
        }
    }

}

public extension UpdateTest {

    typealias Command = Module.Command

    var commands: [Command] {
        switch fixture.results {
        case .success(_, let commands):
            return commands
        case .failure(let failure):
            let failure = String(describing: failure)
            fatalError("Unexpected failure: " + failure)
        case .trap(let trap):
            fatalError(trap)
        }
    }

    var command: Command? {
        guard let command = commands.first, commands.count == 1 else {
            return nil
        }
        return command
    }

}

public extension UpdateTest {

    typealias Failure = Module.Failure

    var failure: Failure? {
        switch fixture.results {
        case .success:
            return nil
        case .failure(let failure):
            return failure
        case .trap(let trap):
            fatalError(trap)
        }
    }

}

public extension UpdateTest {

    var trap: String? {
        if case .trap(let trap) = fixture.results {
            return trap
        }
        return nil
    }

}

public struct UpdateFixture<Module: Elm.Module> {

    typealias Model = Module.Model
    typealias Message = Module.Message
    typealias Command = Module.Command
    typealias Failure = Module.Failure

    public init() {}

    var model: Model?
    var message: Message?

    var results: UpdateResults<Module> {
        guard let model = model else {
            return .trap("Model not set")
        }
        guard let message = message else {
            return .trap("Message not set")
        }
        do {
            var model = model
            var commands: [Command] = []
            try Module.update(for: message, model: &model) { command in
                commands.append(command)
            }
            return .success(model, commands)
        } catch {
            guard let failure = error as? Failure else {
                return .trap("Foreign failure")
            }
            return .failure(failure)
        }
    }
    
}

enum UpdateResults<Module: Elm.Module> {

    typealias Model = Module.Model
    typealias Command = Module.Command
    typealias Failure = Module.Failure

    case success(Model, [Command])
    case failure(Failure)
    case trap(String)

}

//
// MARK: -
// MARK: View test
//

public protocol ViewTest: class, TestBase {

    associatedtype Module: Elm.Module

    var fixture: ViewFixture<Module> { get set }
    
}

public extension ViewTest {

    typealias Model = Module.Model

    var model: Model {
        get {
            guard let model = fixture.model else {
                fatalError("Model not set")
            }
            return model
        }
        set {
            fixture.model = newValue
        }
    }

}

public extension ViewTest {

    typealias View = Module.View

    var view: View {
        switch fixture.results {
        case .success(let view):
            return view
        case .failure(let failure):
            let failure = String(describing: failure)
            fatalError("Unexpected failure: " + failure)
        case .trap(let trap):
            fatalError(trap)
        }
    }

}

public extension ViewTest {

    typealias Failure = Module.Failure

    var failure: Failure? {
        switch fixture.results {
        case .success:
            return nil
        case .failure(let failure):
            return failure
        case .trap(let trap):
            fatalError(trap)
        }
    }

}

public extension ViewTest {

    var trap: String? {
        if case .trap(let trap) = fixture.results {
            return trap
        }
        return nil
    }

}

public struct ViewFixture<Module: Elm.Module> {

    typealias Model = Module.Model
    typealias Failure = Module.Failure

    public init() {}

    var model: Model?

    var results: ViewResults<Module> {
        guard let model = model else {
            return .trap("Model not set")
        }
        do {
            let view = try Module.view(for: model)
            return .success(view)
        } catch {
            guard let failure = error as? Failure else {
                return .trap("Foreign failure")
            }
            return .failure(failure)
        }
    }
    
}

enum ViewResults<Module: Elm.Module> {

    typealias View = Module.View
    typealias Failure = Module.Failure

    case success(View)
    case failure(Failure)
    case trap(String)

}

//
// MARK: -
// MARK: Test base
//

public protocol TestBase {

    // XCTFail
    typealias FailureReporter = (
        String, // message
        StaticString, // file
        UInt // line
        ) -> Void


    var failureReporter: FailureReporter { get }
    var trap: String? { get }

}

public extension TestBase {


    func expect(_ value: @autoclosure () -> Bool, file: StaticString = #file, line: Int = #line) {
        expect(value, true, file: file, line: line)
    }

    func expect<T>(_ value: @autoclosure () -> T, _ expectedValue: @autoclosure () -> T, file: StaticString = #file, line: Int = #line) {
        if let trap = trap {
            failureReporter(trap, file, UInt(line))
            return
        }
        let value = String(describing: value())
        let expectedValue = String(describing: expectedValue())
        if value != expectedValue {
            let message = value + " is not equal to " + expectedValue
            failureReporter(message, file, UInt(line))
        }
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
