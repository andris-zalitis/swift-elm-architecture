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
        return .view(view)
    }

}

// MARK: - Start

public struct Start<Program: Elm.Program> {

    typealias Event = Program.Event
    typealias State = Program.State
    typealias Action = Program.Action
    typealias Error = Program.Error

    typealias Data = StartData<Program>
    let data: Data

    public static func next(state: State, actions: [Action] = [], event: Event? = nil) -> Start {
        let data: Data = .next(state: state, actions: actions, event: event)
        return .init(data: data)
    }

    public static func error(_ error: Error) -> Start {
        let data: Data = .error(error)
        return .init(data: data)
    }

}

enum StartData<Program: Elm.Program> {

    typealias Event = Program.Event
    typealias State = Program.State
    typealias Action = Program.Action
    typealias Error = Program.Error

    case next(state: State, actions: [Action], event: Event?)
    case error(Error)

}

// MARK: Update

public struct Update<Program: Elm.Program> {

    typealias Event = Program.Event
    typealias State = Program.State
    typealias Action = Program.Action
    typealias Error = Program.Error

    typealias Data = UpdateData<Program>
    let data: Data

    public static func next(state: State? = nil, actions: [Action] = [], event: Event? = nil) -> Update {
        let data: Data = .next(state: state, actions: actions, event: event)
        return .init(data: data)
    }

    public static func error(_ error: Error) -> Update {
        let data: Data = .error(error)
        return .init(data: data)
    }

}

enum UpdateData<Program: Elm.Program> {

    typealias Event = Program.Event
    typealias State = Program.State
    typealias Action = Program.Action
    typealias Error = Program.Error

    case next(state: State?, actions: [Action], event: Event?)
    case error(Error)

}

// MARK: - Render

public struct Render<Program: Elm.Program> {

    typealias View = Program.View
    typealias Error = Program.Error

    typealias Data = RenderData<Program>
    let data: Data

    public static func view(_ view: View) -> Render {
        let data: Data = .view(view)
        return .init(data: data)
    }

    public static func error(_ error: Error) -> Render {
        let data: Data = .error(error)
        return .init(data: data)
    }

}

enum RenderData<Program: Elm.Program> {

    typealias View = Program.View
    typealias Error = Program.Error

    case view(View)
    case error(Error)

}

// MARK: - Store

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
