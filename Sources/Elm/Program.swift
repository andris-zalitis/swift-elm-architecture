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

    static func start(with seed: Seed, perform: (Action) -> Void) -> Result<State, Failure>
    static func update(for event: Event, state: inout State, perform: (Action) -> Void) -> Result<Success, Failure>
    static func view(for state: State) -> Result<View, Failure>

}

public extension Program {

    static func makeStore<Delegate: StoreDelegate>(delegate: Delegate, seed: Seed) -> Store<Self> where Delegate.Program == Self {
        return Store<Self>(program: self, delegate: delegate, seed: seed)
    }

}
