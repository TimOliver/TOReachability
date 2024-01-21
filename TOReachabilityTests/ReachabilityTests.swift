//
//  ReachabilityTests.swift
//  TOReachabilityExampleTests
//
//  Created by Tim Oliver on 6/3/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

import XCTest
@testable import TOReachability

enum ReachabilityError: Error, Equatable {
    case objectWasNil
}

class ReachabilityTests: XCTestCase {

    func testSwiftSetupAndRun() throws {
        let expectation = XCTestExpectation(description: "Set up and run")
        guard let reachability = Reachability() else {
            throw ReachabilityError.objectWasNil
        }

        reachability.statusChangedHandler = { _, _, _ in
            expectation.fulfill()
        }
        reachability.startListening()

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(reachability.isRunning)
    }

    func testNotificationBroadcast() throws {
        guard let reachability = Reachability() else {
            throw ReachabilityError.objectWasNil
        }

        reachability.broadcastsNotifications = true
        XCTAssertNotNil(reachability)

        let expectation = XCTNSNotificationExpectation(name: NSNotification.Name(rawValue: Reachability.StatusChangedNotification), object: reachability)
        reachability.startListening()

        wait(for: [expectation], timeout: 1.0)
    }
}
