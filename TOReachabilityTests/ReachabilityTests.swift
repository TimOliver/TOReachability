//
//  ReachabilityTests.swift
//  TOReachabilityExampleTests
//
//  Created by Tim Oliver on 6/3/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

import XCTest

class ReachabilityTests: XCTestCase {

    func testSwiftSetupAndRun() {
        let expectation = XCTestExpectation(description: "Set up and run")

        let reachability = Reachability.forInternetConnection()
        XCTAssertNotNil(reachability)

        reachability.statusChangedHandler = {newStatus in
            expectation.fulfill()
        }
        reachability.start()

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(reachability.isRunning)
    }

    func testNotificationBroadcast() {
        let reachability = Reachability.forInternetConnection()
        reachability.broadcastStatusChangeNotifications = true
        XCTAssertNotNil(reachability)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            reachability.start()
        }

        // Because `waitForExpectations:` blocks the main thread, we can't simply set up the observer and call
        // `start` afterwards
        let expectation = XCTNSNotificationExpectation(name: NSNotification.Name(rawValue: Reachability.StatusChangedNotification), object: reachability)
        wait(for: [expectation], timeout: 10.0)
    }
}
