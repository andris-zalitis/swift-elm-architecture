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
    static func view(for model: Model) -> View

}

public extension Module {

    static var error: Error {
        return InternalInconsistency()
    }

}

public extension Module {

    static func makeProgram() -> Program<Self> {
        return Program<Self>(module: self)
    }

}

public struct InternalInconsistency: Error {}

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
    private var model = Module.Model()

    public private(set) var view: Module.View

    public init(module: Module.Type) {
        self.module = module
        view = module.view(for: model)
    }

    //
    // MARK: -
    // MARK: Delegate
    //

    public func setDelegate<Delegate: Elm.Delegate>(_ delegate: Delegate) where Delegate.Module == Module {
        sink = (
            view: { [weak delegate] view in
                delegate?.program(self, didUpdate: view)
            },
            command: { [weak delegate] command in
                delegate?.program(self, didEmit: command)
            }
        )
        delegate.program(self, didUpdate: view)
    }

    public func unsetDelegate() {
        sink = nil
    }

    private typealias ViewSink = (Module.View) -> Void
    private typealias CommandSink = (Module.Command) -> Void

    private var sink: (view: ViewSink, command: CommandSink)?

    //
    // MARK: -
    // MARK: Dispatch
    //

    public func dispatch(_ messages: Module.Message...) {
        guard let sink = sink else { return }
        for message in messages {
            do {
                let commands = try module.update(for: message, model: &model)
                view = module.view(for: model)
                sink.view(view)
                commands.forEach(sink.command)
            } catch {
                var standardError = StandardError()
                print("ERROR:", to: &standardError)
                dump(error)
                print("MODULE:", to: &standardError)
                dump(module, to: &standardError)
                print("MESSAGE:", to: &standardError)
                dump(message)
                print("MODEL:", to: &standardError)
                dump(model, to: &standardError)
                fatalError()
            }
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

