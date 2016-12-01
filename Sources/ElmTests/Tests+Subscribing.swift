// The MIT License (MIT)
//
// Copyright (c) 2016 Rudolf Adamkovič
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

extension Tests {

    //
    // MARK: -
    // MARK: Add subscribers
    //

    func testAddSubscriber1() {

        // Arrange
        let recorder = Recorder()
        let counter = Counter.makeProgram()

        // Act
        counter.subscribe(recorder)

        // Assert
        XCTAssertEqual(counter.subscribers.count, 1)
        XCTAssertTrue(counter.subscribers[0] === recorder)

    }

    func testAddSubscriber2() {

        // Arrange
        let subscriber1 = Recorder()
        let subscriber2 = Recorder()
        let counter = Counter.makeProgram()

        // Act
        counter.subscribe(subscriber1)
        counter.subscribe(subscriber2)

        // Assert
        XCTAssertEqual(counter.subscribers.count, 2)
        XCTAssertTrue(counter.subscribers.contains { $0 === subscriber1 })
        XCTAssertTrue(counter.subscribers.contains { $0 === subscriber2 })

    }

    func testAddSubscriberOnce() {

        // Arrange
        let recorder = Recorder()
        let counter = Counter.makeProgram()

        // Act
        counter.subscribe(recorder)
        counter.subscribe(recorder)

        // Assert
        XCTAssertEqual(counter.subscribers.count, 1)

    }

    //
    // MARK: -
    // MARK: Remove subscribers
    //

    func testRemoveSubscriber() {

        // Arrange
        var recorder: Recorder? = Recorder()
        let counter = Counter.makeProgram()
        counter.subscribe(recorder!)

        // Act
        recorder = nil
        
        // Assert
        XCTAssertTrue(counter.subscribers.isEmpty)
        
    }

    //
    // MARK: -
    // MARK: Initialize subscribers
    //

    func testInitializeSubscriber1() {

        // Arrange
        let recorder = Recorder()
        let counter = Counter.makeProgram()

        // Act
        counter.subscribe(recorder)

        // Assert
        let expectedView = View(counterText: "0")
        XCTAssertEqual(recorder.capturedViews, [expectedView])

    }

    func testInitializeSubscriber2() {

        // Arrange
        let recorder1 = Recorder()
        let recorder2 = Recorder()
        let counter = Counter.makeProgram()

        // Act
        counter.subscribe(recorder1)
        counter.subscribe(recorder2)

        // Assert
        let expectedView = View(counterText: "0")
        XCTAssertEqual(recorder1.capturedViews, [expectedView])
        XCTAssertEqual(recorder2.capturedViews, [expectedView])

    }

    func testInitializeSubscriberOnce() {

        // Arrange
        let recorder = Recorder()
        let counter = Counter.makeProgram()

        // Act
        counter.subscribe(recorder)
        counter.subscribe(recorder)

        // Assert
        let expectedView = View(counterText: "0")
        XCTAssertEqual(recorder.capturedViews, [expectedView])
        
    }

}
