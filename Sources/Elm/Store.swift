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

import Foundation

public protocol StoreDelegate: class {

    associatedtype Program: Elm.Program

    typealias Action = Program.Action
    typealias View = Program.View

    func store(_ store: Store<Program>, didRequest action: Action)
    func store(_ store: Store<Program>, didUpdate view: View)

}

public final class Store<Program: Elm.Program> {

    typealias Seed = Program.Seed
    typealias Event = Program.Event
    typealias State = Program.State
    typealias Action = Program.Action
    typealias View = Program.View

    private let thread = Thread.current
    private var state: State
    public private(set) lazy var view: View = Store.makeView(program: Program.self, state: self.state)

    private typealias ViewSink = (View) -> Void
    private typealias ActionSink = (Action) -> Void

    private var sendView: ViewSink = { _ in }
    private var sendAction: ActionSink = { _ in }

    init<Delegate: Elm.StoreDelegate>(program _: Program.Type, delegate: Delegate, seed: Seed) where Delegate.Program == Program {
        var actions: [Action] = []
        let result = Program.start(with: seed) { action in
            actions.append(action)
        }
        switch result {
        case .success(let state):
            self.state = state
            sendView = { [weak delegate] view in
                delegate?.store(self, didUpdate: view)
            }
            sendAction = { [weak delegate] action in
                delegate?.store(self, didRequest: action)
            }
            updateDelegate(with: actions)
        case .failure(let failure):
            let message = "Fatal error!" + "\n"
                + dumped(Program.start, label: "Location")
                + dumped(failure, label: "Failure")
                + dumped(seed, label: "Seed")
            fatalError(message)
        }
    }

    public func dispatch(_ events: Event...) {
        guard Thread.current == thread else {
            let message = "Invalid thread" + "\n"
                +  dumped(events, label: "Events")
                +  dumped(state, label: "State")
            fatalError(message)
        }
        var actions: [Action] = []
        for event in events {
            let result = Program.update(for: event, state: &state) { action in
                actions.append(action)
            }
            if case .failure(let failure) = result {
                let message = "Fatal error!" + "\n"
                    + dumped(Program.update, label: "Location")
                    + dumped(failure, label: "Failure")
                    + dumped(event, label: "Event")
                    + dumped(state, label: "State")
                fatalError(message)
            }
        }
        view = Store.makeView(program: Program.self, state: state)
        updateDelegate(with: actions)
    }

    private static func makeView(program: Program.Type, state: State) -> View {
        switch program.view(for: state) {
        case .success(let view):
            return view
        case .failure(let failure):
            let message = "Fatal error!" + "\n"
                + dumped(Program.update, label: "Location")
                + dumped(failure, label: "Failure")
                + dumped(state, label: "State")
            fatalError(message)
        }
    }

    private func updateDelegate(with actions: [Action]) {
        sendView(view)
        actions.forEach(sendAction)
    }

}
