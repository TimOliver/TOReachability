//
//  TOReachabilityExampleTests.m
//  TOReachabilityExampleTests
//
//  Created by Tim Oliver on 23/2/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TOReachability.h"

@interface TOReachabilityTests : XCTestCase <TOReachabilityDelegate>

@property (nonatomic, strong) XCTestExpectation *delegateExpectation;

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

    XCTNSNotificationExpectation *expectation = [[XCTNSNotificationExpectation alloc] initWithName:TOReachabilityStatusChangedNotification object:reachability];
    [reachability start];

    [self waitForExpectations:@[expectation] timeout:1.0f];
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

- (void)testDelegate
{
    TOReachability *reachability = [TOReachability reachabilityForWifiConnection];
    XCTAssertNotNil(reachability);

    self.delegateExpectation = [[XCTestExpectation alloc] initWithDescription:@"Delegate successfully called"];

    reachability.delegate = self;
    [reachability start];

    [self waitForExpectations:@[self.delegateExpectation] timeout:1.0f];
}

- (void)reachability:(TOReachability *)reachability didChangeStatusTo:(TOReachabilityStatus)newStatus
{
    [self.delegateExpectation fulfill];
}

@end
