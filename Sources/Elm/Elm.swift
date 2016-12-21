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

    associatedtype Message
    associatedtype Model: Initable
    associatedtype Command
    associatedtype View

    static func update(for message: Message, model: inout Model) throws -> [Command]
    static func view(for model: Model) throws -> View

}

public extension Module {

    static var error: Error {
        return GenericError()
    }

}

public extension Module {

    static func makeProgram() -> Program<Self> {
        return Program<Self>(module: self)
    }

}

public struct GenericError: Error {}

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

    typealias Message = Module.Message
    typealias Model = Module.Model
    typealias Command = Module.Command
    typealias View = Module.View

    private var model = Model()
    public private(set) lazy var view: View = Program.makeView(module: self.module, model: self.model)

    public init(module: Module.Type) {
        self.module = module
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
                let commands = try module.update(for: message, model: &model)
                commands.forEach(sendCommand)
            } catch {
                var standardError = StandardError()
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
            var standardError = StandardError()
            print("FATAL: \(module).view function did throw!", to: &standardError)
            dump(error, to: &standardError, name: "Error")
            dump(model, to: &standardError, name: "Model")
            fatalError()
        }
    }

}

//
// MARK: -
// MARK: Utilities
//

public protocol Initable {
    init()
}

private struct StandardError: TextOutputStream {
    public mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

