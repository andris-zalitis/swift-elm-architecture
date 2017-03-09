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

    associatedtype Seed = Void
    associatedtype Event
    associatedtype State
    associatedtype Action = Void
    associatedtype View = Void
    associatedtype Error = Void

    static func start(with seed: Seed) -> Start<Self>
    static func update(for event: Event, state: State) -> Update<Self>
    static func render(with state: State) -> Render<Self>

}

public extension Program where View == Void {

    static func render(with state: State) -> Render<Self> {
        let view: View = Void()
        return .init(view: view)
    }

}

//
// MARK:
// MARK: Start
//

public struct Start<Program: Elm.Program> {

    public typealias State = Program.State
    public typealias Action = Program.Action
    public typealias Error = Program.Error

    let data: StartData<Program>

    public init(state: State) {
        data = .success(state: state, actions: [])
    }

    public init(state: State, actions: Action...) {
        data = .success(state: state, actions: actions)
    }

    public init(error: Error) {
        data = .error(error)
    }

}

enum StartData<Program: Elm.Program> {

    typealias State = Program.State
    typealias Action = Program.Action
    typealias Error = Program.Error

    case success(state: State, actions: [Action])
    case error(Error)

}

// MARK: Update

public struct Update<Program: Elm.Program> {

    typealias State = Program.State
    typealias Action = Program.Action
    typealias Error = Program.Error

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

}

enum UpdateData<Program: Elm.Program> {

    typealias State = Program.State
    typealias Action = Program.Action
    typealias Error = Program.Error

    case success(state: State?, actions: [Action])
    case error(Error)

}

//
// MARK:
// MARK: Render
//

public struct Render<Program: Elm.Program> {

    typealias View = Program.View
    typealias Error = Program.Error

    let data: RenderData<Program>

    init(view: View) {
        data = .success(view: view)
    }

    init(error: Error) {
        data = .error(error)
    }

}

enum RenderData<Program: Elm.Program> {

    typealias View = Program.View
    typealias Error = Program.Error

    case success(view: View)
    case error(Error)

}

//
// MARK:
// MARK: Store
//

public extension Program {

    static func makeStore<Delegate: StoreDelegate>(delegate: Delegate, seed: Seed) -> Store<Self> where Delegate.Program == Self {
        return Store<Self>(program: self, delegate: delegate, seed: seed)
    }

}

public extension Program where Seed == Void {

    static func makeStore<Delegate: StoreDelegate>(delegate: Delegate) -> Store<Self> where Delegate.Program == Self {
        return Store<Self>(program: self, delegate: delegate, seed: Void())
    }

}
