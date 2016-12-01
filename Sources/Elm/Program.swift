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

import Foundation

public final class Program<Main: Module> {

    //
    // MARK: -
    // MARK: Initialization
    //

    public typealias Module = Main.Type
    public let module: Module

    public init(module: Module) {
        self.module = module
    }

    //
    // MARK: -
    // MARK: Messages
    //

    typealias Message = Main.Message

    public func dispatch(_ message: Message) {
        let commands = module.update(for: message, model: &model)
        updateView()
        broadcastView()
        broadcastCommands(commands)
    }

    //
    // MARK: -
    // MARK: Model
    //

    typealias Model = Main.Model
    private var model = Model()

    //
    // MARK: -
    // MARK: Commands
    //

    typealias Command = Main.Command

    private func broadcastCommands(_ commands: [Command]) {
        for command in commands {
            for subscriber in subscribers {
                subscriber.update(performing: command)
            }
        }
    }

    //
    // MARK: -
    // MARK: Subscribers
    //

    public func subscribe<Target: Subscriber>(_ subscriber: Target)
        where Target.View == View, Target.Command == Command {
            guard !subscriberReferences.contains(subscriber) else { return }
            subscriberReferences.add(subscriber)
            subscriber.update(presenting: view)
    }

    var subscribers: [AnySubscriber] {
        let objects = subscriberReferences.allObjects
        let type = [AnySubscriber].self
        return unsafeCast(objects, as: type)
    }

    private let subscriberReferences = ObjectTable.weakObjects()
    typealias ObjectTable = NSHashTable<AnyObject>

    //
    // MARK: -
    // MARK: View
    //

    typealias View = Main.View

    public private(set) lazy var view: View = self.makeView()

    private func makeView() -> View {
        return module.view(for: model)
    }

    private func broadcastView() {
        for subscriber in subscribers {
            subscriber.update(presenting: view)
        }
    }

    private func updateView() {
        view = makeView()
    }

}
