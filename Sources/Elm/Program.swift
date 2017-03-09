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

public protocol Program {

    associatedtype Seed
    associatedtype Event
    associatedtype State
    associatedtype Action
    associatedtype View
    associatedtype Failure

    static func start(with seed: Seed) -> Start<Self>
    static func update(for event: Event, state: State) -> Update<Self>
    static func render(with state: State) -> Render<Self>

}

public struct Start<Program: Elm.Program> {

    typealias State = Program.State
    typealias Action = Program.Action
    typealias Failure = Program.Failure

    let data: StartData<Program>

    public init(state: State) {
        data = .success(state: state, actions: [])
    }

    public init(state: State, actions: Action...) {
        data = .success(state: state, actions: actions)
    }

    public init(failure: Failure) {
        data = .failure(failure)
    }

}

enum StartData<Program: Elm.Program> {

    typealias State = Program.State
    typealias Action = Program.Action
    typealias Failure = Program.Failure

    case success(state: State, actions: [Action])
    case failure(Failure)

}

public struct Update<Program: Elm.Program> {

    typealias State = Program.State
    typealias Action = Program.Action
    typealias Failure = Program.Failure

    let data: UpdateData<Program>

    public init(state: State) {
        data = .success(state: state, actions: [])
    }

    public init(state: State, actions: Action...) {
        data = .success(state: state, actions: actions)
    }

    public init(actions: Action...) {
        data = .success(state: nil, actions: actions)
    }

    public static var skip: Update {
        return .init()
    }

}

enum UpdateData<Program: Elm.Program> {

    typealias State = Program.State
    typealias Action = Program.Action
    typealias Failure = Program.Failure

    case success(state: State?, actions: [Action])
    case failure(Failure)

}

public struct Render<Program: Elm.Program> {

    typealias View = Program.View
    typealias Failure = Program.Failure

    let data: RenderData<Program>

    init(view: View) {
        data = .success(view: view)
    }

    init(failure: Failure) {
        data = .failure(failure)
    }

}

enum RenderData<Program: Elm.Program> {

    typealias View = Program.View
    typealias Failure = Program.Failure

    case success(view: View)
    case failure(Failure)

}

public extension Program {

    static func makeStore<Delegate: StoreDelegate>(delegate: Delegate, seed: Seed) -> Store<Self> where Delegate.Program == Self {
        return Store<Self>(program: self, delegate: delegate, seed: seed)
    }

}
