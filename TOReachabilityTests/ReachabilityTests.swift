//
//  ReachabilityTests.swift
//  TOReachabilityExampleTests
//
//  Created by Tim Oliver on 6/3/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

import XCTest
@testable import TOReachability


class ReachabilityTests: XCTestCase {

    func testSwiftSetupAndRun() throws {
        let expectation = XCTestExpectation(description: "Set up and run")
        let reachability = Reachability()

        reachability.statusChangedHandler = { _, _, _ in
            expectation.fulfill()
        }
        reachability.start()

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(reachability.isRunning)
    }

    func testNotificationBroadcast() throws {
        let reachability = Reachability()

        reachability.broadcastsNotifications = true
        XCTAssertNotNil(reachability)

        let expectation = XCTNSNotificationExpectation(name: NSNotification.Name(rawValue: Reachability.StatusChangedNotification), object: reachability)
        reachability.start()

        wait(for: [expectation], timeout: 1.0)
    }
}
