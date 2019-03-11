//
//  TOReachabilityExampleTests.m
//  TOReachabilityExampleTests
//
//  Created by Tim Oliver on 23/2/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TOReachability.h"

@interface TOReachabilityTests : XCTestCase

@end

@implementation TOReachabilityTests

- (void)testSwiftSetupAndRun
{
    XCTestExpectation *expection = [[XCTestExpectation alloc] initWithDescription:@"Set up and run"];

    TOReachability *reachability = [TOReachability reachabilityForInternetConnection];
    XCTAssertNotNil(reachability);

    reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus) {
        [expection fulfill];
    };
    [reachability start];

    [self waitForExpectations:@[expection] timeout:1.0f];

    XCTAssertTrue(reachability.running);
}

- (void)testNotificationBroadcast
{
    TOReachability *reachability = [TOReachability reachabilityForInternetConnection];
    reachability.broadcastsStatusChangeNotifications = YES;
    XCTAssertNotNil(reachability);

    // Because `waitForExpectations:` blocks the main thread, we can't simply set up the observer and call
    // `start` afterwards
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [reachability start];
    });

    XCTNSNotificationExpectation *expectation = [[XCTNSNotificationExpectation alloc] initWithName:TOReachabilityStatusChangedNotification object:reachability];
    [self waitForExpectations:@[expectation] timeout:10.0f];
}

- (void)testCellularConnection
{
    TOReachability *reachability = [TOReachability reachabilityForInternetConnection];
    XCTAssertNotNil(reachability);

    XCTestExpectation *expection = [[XCTestExpectation alloc] initWithDescription:@"Reachability Dedicated Stable Cellular"];

    reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus) {
        if (newStatus == TOReachabilityStatusCellular) { [expection fulfill]; }
    };
    [reachability start];

    // Force trigger the internal callback method, simulating cellular
    [reachability performSelector:NSSelectorFromString(@"_triggerCellularCallback") withObject:nil afterDelay:0];

    [self waitForExpectations:@[expection] timeout:1.0f];
}

- (void)testWiFiOnlyConnection
{
    TOReachability *reachability = [TOReachability reachabilityForWifiConnection];
    XCTAssertNotNil(reachability);

    // This test will be a failure if triggering a simulated cellular signal changes the status to cellular
    XCTestExpectation *expection = [[XCTestExpectation alloc] initWithDescription:@"Reachability Dedicated Only Cellular"];
    expection.inverted = YES;

    reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus) {
        if (newStatus == TOReachabilityStatusCellular) { [expection fulfill]; }
    };
    [reachability start];

    // Force trigger the internal callback method, simulating cellular
    [reachability performSelector:NSSelectorFromString(@"_triggerCellularCallback") withObject:nil afterDelay:0];

    [self waitForExpectations:@[expection] timeout:1.0f];
}

@end
