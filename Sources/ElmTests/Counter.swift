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

@testable import Elm

typealias Seed = Counter.Seed
typealias Event = Counter.Event
typealias View = Counter.View
typealias State = Counter.State
typealias Action = Counter.Action

struct Counter: Program {

    struct Seed {
        let count: Int
    }

    enum Event {
        case increment, decrement
    }

    struct State {
        var count: Int
    }

    struct View {
        let count: String
    }

    enum Action {
        case log(String)
    }

    enum Failure {}

    static func start(with seed: Seed) -> Start<Counter> {
        let initialState = State(count: seed.count)
        let initialAction = Action.log("Did start")
        return .init(state: initialState, actions: initialAction)
    }

    static func update(for event: Event, state: State) -> Update<Counter> {
        let nextState: State
        let nextAction: Action
        switch event {
        case .increment:
            nextState = .init(count: state.count + 1)
            nextAction = .log("Did increment")
        case .decrement:
            nextState = .init(count: state.count - 1)
            nextAction = .log("Did decrement")
        }
        return .init(state: nextState, actions: nextAction)
    }

    static func scene(for state: State) -> Scene<Counter> {
        let count = String(state.count)
        let view = View(count: count)
        return .init(view: view)
    }

}

extension Action: Equatable {
    static func == (lhs: Action, rhs: Action) -> Bool {
        return String(describing: lhs) == String(describing: rhs)
    }
}

extension View: Equatable {
    static func == (lhs: View, rhs: View) -> Bool {
        return String(describing: lhs) == String(describing: rhs)
    }
}
