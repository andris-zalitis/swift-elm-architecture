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
        let start = Program.start(with: seed)
        switch start.data {
        case .success(state: let nextState, actions: let actions):
            state = nextState
            sendView = { [weak delegate] view in
                delegate?.store(self, didUpdate: view)
            }
            sendAction = { [weak delegate] action in
                delegate?.store(self, didRequest: action)
            }
            sendView(view)
            actions.forEach(sendAction)
        case .error(let error):
            let message = "Fatal error!" + "\n"
                + dumped(Program.start, label: "Location")
                + dumped(error, label: "Error")
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
        var didUpdateState = false
        for event in events {
            let update = Program.update(for: event, state: state)
            switch update.data {
            case .success(state: let newState, actions: let newActions):
                if let newState = newState {
                    didUpdateState = true
                    state = newState
                }
                actions.append(contentsOf: newActions)
            case .error(let error):
                let message = "Fatal error!" + "\n"
                    + dumped(Program.update, label: "Location")
                    + dumped(error, label: "Error")
                    + dumped(event, label: "Event")
                    + dumped(state, label: "State")
                fatalError(message)
            }
        }
        if didUpdateState {
            view = Store.makeView(program: Program.self, state: state)
            sendView(view)
        }
        actions.forEach(sendAction)
    }

    private static func makeView(program: Program.Type, state: State) -> View {
        let render = program.render(with: state)
        switch render.data {
        case .success(view: let view):
            return view
        case .error(let error):
            let message = "Fatal error!" + "\n"
                + dumped(Program.update, label: "Location")
                + dumped(error, label: "Error")
                + dumped(state, label: "State")
            fatalError(message)
        }
    }

}

private func dumped<T>(_ value: T, label: String) -> String {
    var result = label + ":" + "\n"
    dump(value, to: &result, indent: 1)
    return result
}
