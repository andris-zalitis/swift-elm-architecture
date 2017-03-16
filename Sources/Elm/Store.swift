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
        case .next(state: let nextState, actions: let actions, event: let event):
            state = nextState
            sendView = { [weak delegate] view in
                delegate?.store(self, didUpdate: view)
            }
            sendAction = { [weak delegate] action in
                delegate?.store(self, didRequest: action)
            }
            sendView(view)
            actions.forEach(sendAction)
            if let event = event {
                dispatch(event)
            }
        case .error(let error):
            let message = "Fatal error!" + "\n"
                + String(dumping: Program.start, label: "Location")
                + String(dumping: error, label: "Error")
                + String(dumping: seed, label: "Seed")
            fatalError(message)
        }
    }

    public func dispatch(_ event: Event) {
        guard Thread.current == thread else {
            let message = "Invalid thread" + "\n"
                +  String(dumping: event, label: "Event")
                +  String(dumping: state, label: "State")
            fatalError(message)
        }
        let update = Program.update(for: event, state: state)
        switch update.data {
        case .next(state: let state, actions: let actions, event: let event):
            if let state = state {
                self.state = state
                view = Store.makeView(program: Program.self, state: state)
                sendView(view)
            }
            actions.forEach(sendAction)
            if let event = event {
                dispatch(event)
            }
        case .error(let error):
            let message = "Fatal error!" + "\n"
                + String(dumping: Program.update, label: "Location")
                + String(dumping: error, label: "Error")
                + String(dumping: event, label: "Event")
                + String(dumping: state, label: "State")
            fatalError(message)
        }
    }

    private static func makeView(program: Program.Type, state: State) -> View {
        let render = program.render(with: state)
        switch render.data {
        case .success(view: let view):
            return view
        case .error(let error):
            let message = "Fatal error!" + "\n"
                + String(dumping: Program.render, label: "Location")
                + String(dumping: error, label: "Error")
                + String(dumping: state, label: "State")
            fatalError(message)
        }
    }

}

extension String {

    init<Value>(dumping value: Value, label: String) {
        self.init()
        dump("\(label):\n", to: &self, indent: 1)
    }

}
