//
//  TOReachabilityExampleTests.m
//  TOReachabilityExampleTests
//
//  Created by Tim Oliver on 23/2/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "TOReachability.h"

@interface TOReachability (Tests)

- (TOReachabilityStatus)_reachabilityStatusForFlags:(SCNetworkReachabilityFlags)flags;
- (void)_triggerCellularCallback;

@end

@interface TOReachabilityTests : XCTestCase <TOReachabilityDelegate>

@property (nonatomic, strong) XCTestExpectation *delegateExpectation;

@end

@implementation TOReachabilityTests

- (void)testSetupAndRun
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
        if (newStatus == TOReachabilityStatusAvailableOnCellular) {
            [expection fulfill];
        }
    };
    [reachability start];

    // Force trigger the internal callback method, simulating cellular
    [reachability _triggerCellularCallback];

    [self waitForExpectations:@[expection] timeout:1.0f];
}

- (void)testWiFiOnlyConnection
{
    TOReachability *reachability = [TOReachability reachabilityForLocalNetworkConnection];

    XCTAssertNotNil(reachability);

    // This test will be a failure if triggering a simulated cellular signal changes the status to cellular
    XCTestExpectation *expection = [[XCTestExpectation alloc] initWithDescription:@"Reachability WiFi Only"];
    expection.inverted = YES;

    reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus) {
        if (newStatus == TOReachabilityStatusAvailableOnCellular) {
            [expection fulfill];
        }
    };
    [reachability start];

    // Force trigger the internal callback method, simulating cellular
    [reachability _triggerCellularCallback];

    [self waitForExpectations:@[expection] timeout:1.0f];
}

- (void)testHostNameConnection
{
    TOReachability *reachability = [TOReachability reachabilityWithHostName:@"www.timoliver.co"];

    XCTAssertNotNil(reachability);

    // This test will be a failure if triggering a simulated cellular signal changes the status to cellular
    XCTestExpectation *expection = [[XCTestExpectation alloc] initWithDescription:@"Reachability Host Name Only"];

    reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus) {
        if (newStatus == TOReachabilityStatusAvailableOnCellular) {
            [expection fulfill];
        }
    };
    [reachability start];

    // Force trigger the internal callback method, simulating cellular
    [reachability performSelector:NSSelectorFromString(@"_triggerCellularCallback") withObject:nil afterDelay:0];

    [self waitForExpectations:@[expection] timeout:1.0f];
}

- (void)testDelegate
{
    TOReachability *reachability = [TOReachability reachabilityForLocalNetworkConnection];

    XCTAssertNotNil(reachability);

    self.delegateExpectation = [[XCTestExpectation alloc] initWithDescription:@"Delegate successfully called"];

    reachability.delegate = self;
    [reachability start];

    [self waitForExpectations:@[self.delegateExpectation] timeout:1.0f];
}

- (void)testListeners
{
    TOReachability *reachability = [TOReachability reachabilityForLocalNetworkConnection];

    XCTAssertNotNil(reachability);

    self.delegateExpectation = [[XCTestExpectation alloc] initWithDescription:@"Listener successfully called"];

    [reachability addListener:self];
    XCTAssertEqual(reachability.listeners.count, 1);

    [reachability removeListener:self];
    XCTAssertEqual(reachability.listeners.count, 0);

    [reachability addListener:self];
    XCTAssertEqual(reachability.listeners.count, 1);

    [reachability start];

    [self waitForExpectations:@[self.delegateExpectation] timeout:1.0f];
}

- (void)reachability:(TOReachability *)reachability didChangeStatusTo:(TOReachabilityStatus)newStatus
{
    [self.delegateExpectation fulfill];
}

- (void)testReachabilityStatusForFlags {
    TOReachability *reachability = [TOReachability reachabilityForInternetConnection];

    XCTAssertNotNil(reachability);

    XCTAssertEqual([reachability _reachabilityStatusForFlags:0], TOReachabilityStatusNotAvailable);

    SCNetworkReachabilityFlags reachableFlags = kSCNetworkReachabilityFlagsReachable;
    XCTAssertEqual([reachability _reachabilityStatusForFlags:reachableFlags], TOReachabilityStatusAvailable);

    SCNetworkReachabilityFlags reachableAndOnDemandFlags = kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsConnectionOnDemand;
    XCTAssertEqual([reachability _reachabilityStatusForFlags:reachableAndOnDemandFlags], TOReachabilityStatusAvailable);

    SCNetworkReachabilityFlags reachableAndOnCellularFlags = kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsIsWWAN;
    XCTAssertEqual([reachability _reachabilityStatusForFlags:reachableAndOnCellularFlags], TOReachabilityStatusAvailableOnCellular);
}

@end
