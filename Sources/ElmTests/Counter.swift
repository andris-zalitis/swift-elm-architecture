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

    typealias Seed = Int

    enum Event {
        case increment
        case incrementTwice
        case decrement
    }

    typealias State = Int
    typealias View = String

    enum Action {
        case log(String)
    }

    static func start(with seed: Seed) -> Start<Counter> {
        return .next(
            state: seed,
            actions: [.log("Did call start")]
        )
    }

    static func update(for event: Event, state: State) -> Update<Counter> {
        switch event {
        case .increment:
            return .next(
                state: state + 1,
                actions: [.log("Did call increment")]
            )
        case .incrementTwice:
            return .next(
                state: state + 1,
                actions: [.log("Did call increment twice")],
                event: .increment
            )
        case .decrement:
            return .next(
                state: state - 1,
                actions: [.log("Did call decrement")]
            )
        }
    }

    static func render(with state: State) -> Render<Counter> {
        let view: View = String(state)
        return .view(view)
    }

}

extension Action: Equatable {
    static func == (lhs: Action, rhs: Action) -> Bool {
        return String(describing: lhs) == String(describing: rhs)
    }
}
