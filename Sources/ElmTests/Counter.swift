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

    static func start(with seed: Seed, perform: (Action) -> Void) -> Result<State, Failure> {
        perform(.log("Did start"))
        let state = State(count: seed.count)
        return .success(state)
    }

    static func update(for event: Event, state: inout State, perform: (Action) -> Void) -> Result<Success, Failure> {
        switch event {
        case .increment:
            state.count += 1
            perform(.log("Did increment"))
        case .decrement:
            state.count -= 1
            perform(.log("Did decrement"))
        }
        return .success()
    }

    static func view(for state: State) -> Result<View, Failure> {
        let counterText = String(state.count)
        let view = View(count: counterText)
        return .success(view)
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
