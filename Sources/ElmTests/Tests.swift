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

import XCTest

@testable import Elm

final class Tests: XCTestCase {

    // MARK: - View

    func testViewAfterStart1() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 1)
        XCTAssertEqual(store.view, "1")
    }

    func testViewAfterStart2() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 2)
        XCTAssertEqual(store.view, "2")
    }

    func testViewAfterDispatch1() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 1)
        store.dispatch(.increment)
        XCTAssertEqual(store.view, "2")
    }

    func testViewAfterDispatch2() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 1)
        store.dispatch(.increment)
        store.dispatch(.decrement)
        XCTAssertEqual(store.view, "1")
    }

    func testViewAfterDispatchIncrementTwice() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 0)
        store.dispatch(.incrementTwice)
        XCTAssertEqual(store.view, "2")
    }

    func testViewsAfterStart1() {
        let recorder = DataRecorder()
        _ = Counter.makeStore(delegate: recorder, seed: 1)
        XCTAssertEqual(recorder.views, ["1"])
    }

    func testViewsAfterStart2() {
        let recorder = DataRecorder()
        _ = Counter.makeStore(delegate: recorder, seed: 2)
        XCTAssertEqual(recorder.views, ["2"])
    }

    func testViewsAfterDispatch1() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 1)
        store.dispatch(.increment)
        XCTAssertEqual(recorder.views, ["1", "2"])
    }

    func testViewsAfterDispatch2() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 1)
        store.dispatch(.increment)
        store.dispatch(.decrement)
        XCTAssertEqual(recorder.views, ["1", "2", "1"])
    }

    func testViewsAfterDispatchIncrementTwice() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 0)
        store.dispatch(.incrementTwice)
        XCTAssertEqual(recorder.views, ["0", "1", "2"])
    }

    func testViewUpdatesBeforeActions1() {
        let recorder = TimeRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 1)
        store.dispatch(.increment)
        let didUpdateViewAt = recorder.didUpdateViewAt[0]
        let didRequestActionAt = recorder.didRequestActionAt[0]
        XCTAssertLessThan(didUpdateViewAt, didRequestActionAt)
    }

    func testViewUpdatesBeforeActions2() {
        let recorder = TimeRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 2)
        store.dispatch(.increment)
        store.dispatch(.decrement)
        let didUpdateViewAt = recorder.didUpdateViewAt[1]
        let didRequestActionAt = recorder.didRequestActionAt[1]
        XCTAssertLessThan(didUpdateViewAt, didRequestActionAt)
    }

    // MARK: - Actions

    func testActionsAfterStart() {
        let recorder = DataRecorder()
        _ = Counter.makeStore(delegate: recorder, seed: 1)
        XCTAssertEqual(recorder.actions, [.log("Did call start")])
    }

    func testActionsAfterDispatch1() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 1)
        store.dispatch(.increment)
        XCTAssertEqual(recorder.actions, [
            .log("Did call start"),
            .log("Did call increment")
            ]
        )
    }

    func testActionsAfterDispatch2() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 1)
        store.dispatch(.increment)
        store.dispatch(.decrement)
        XCTAssertEqual(recorder.actions, [
            .log("Did call start"),
            .log("Did call increment"),
            .log("Did call decrement")
            ]
        )
    }

    func testActionsAfterDispatchIncrementTwice() {
        let recorder = DataRecorder()
        let store = Counter.makeStore(delegate: recorder, seed: 0)
        store.dispatch(.incrementTwice)
        XCTAssertEqual(recorder.actions, [
            .log("Did call start"),
            .log("Did call increment twice"),
            .log("Did call increment")
            ]
        )
    }

    // MARK: - Delegate

    func testWeakDelegate() {
        var recorder: DataRecorder? = DataRecorder()
        _ = Counter.makeStore(delegate: recorder!, seed: 0)
        weak var weakRecorder: DataRecorder? = recorder
        recorder = nil
        XCTAssertNil(weakRecorder)
    }

}
