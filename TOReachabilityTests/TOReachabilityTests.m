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
- (void)_triggerCallbackWithCellular:(BOOL)cellular wifi:(BOOL)wifi;

@end

@interface TOReachabilityTests : XCTestCase <TOReachabilityDelegate>

@property (nonatomic, strong) XCTestExpectation *delegateExpectation;

@end

@implementation TOReachabilityTests

- (void)testSetupAndRun
{
    XCTestExpectation *expection = [[XCTestExpectation alloc] initWithDescription:@"Set up and run"];

    TOReachability *reachability = [TOReachability new];

    XCTAssertNotNil(reachability);

    reachability.statusChangedHandler = ^(TOReachability *reachability,
                                          TOReachabilityStatus newStatus,
                                          TOReachabilityStatus oldStatus) {
        [expection fulfill];
    };
    [reachability startListening];

    [self waitForExpectations:@[expection] timeout:1.0f];

    XCTAssertTrue(reachability.running);
}

- (void)testNotificationBroadcast
{
    TOReachability *reachability = [TOReachability new];

    reachability.broadcastsNotifications = YES;
    XCTAssertNotNil(reachability);

    XCTNSNotificationExpectation *expectation = [[XCTNSNotificationExpectation alloc] initWithName:TOReachabilityStatusChangedNotification object:reachability];
    [reachability startListening];

    [self waitForExpectations:@[expectation] timeout:1.0f];
}

- (void)testCellularConnection
{
    TOReachability *reachability = [TOReachability new];
    XCTAssertNotNil(reachability);

    XCTestExpectation *expection = [[XCTestExpectation alloc] initWithDescription:@"Reachability Dedicated Stable Cellular"];

    reachability.statusChangedHandler = ^(TOReachability *reachability,
                                          TOReachabilityStatus newStatus,
                                          TOReachabilityStatus oldStatus) {
        [expection fulfill];
    };
    [reachability startListening];

    // Force trigger the internal callback method, simulating cellular
    [reachability _triggerCallbackWithCellular:YES wifi:NO];

    [self waitForExpectations:@[expection] timeout:1.0f];
}

- (void)testWiFiOnlyConnection
{
    TOReachability *reachability = [TOReachability new];
    reachability.requiresLocalNetworkConnection = YES;
    XCTAssertNotNil(reachability);

    // This test will be a failure if triggering a simulated cellular signal changes the status to cellular
    XCTestExpectation *expection = [[XCTestExpectation alloc] initWithDescription:@"Reachability WiFi Only"];

    reachability.statusChangedHandler = ^(TOReachability *reachability,
                                          TOReachabilityStatus newStatus,
                                          TOReachabilityStatus oldStatus) {
        if (newStatus == TOReachabilityStatusNotAvailable) {
            [expection fulfill];
        }
    };
    [reachability startListening];

    // Force trigger the internal callback method, simulating cellular
    [reachability _triggerCallbackWithCellular:YES wifi:NO];

    [self waitForExpectations:@[expection] timeout:1.0f];
}

- (void)testHostNameConnection
{
    TOReachability *reachability = [[TOReachability alloc] initWithHostName:@"www.tim.dev"];
    XCTAssertNotNil(reachability);

    // This test will be a failure if triggering a simulated cellular signal changes the status to cellular
    XCTestExpectation *expection = [[XCTestExpectation alloc] initWithDescription:@"Reachability Host Name Only"];

    reachability.statusChangedHandler = ^(TOReachability *reachability,
                                          TOReachabilityStatus newStatus,
                                          TOReachabilityStatus oldStatus) {
        if (newStatus == TOReachabilityStatusAvailableOnCellular) {
            [expection fulfill];
        }
    };
    [reachability startListening];

    // Force trigger the internal callback method, simulating cellular
    [reachability _triggerCallbackWithCellular:YES wifi:NO];

    [self waitForExpectations:@[expection] timeout:1.0f];
}

- (void)testConvenienceProperties {
    TOReachability *reachability = [TOReachability new];
    XCTAssertNotNil(reachability);

    [reachability _triggerCallbackWithCellular:YES wifi:NO];
    XCTAssertTrue(reachability.reachableOnCellular);

    [reachability _triggerCallbackWithCellular:NO wifi:YES];
    XCTAssertTrue(reachability.reachableOnLocalNetwork);

    [reachability _triggerCallbackWithCellular:YES wifi:YES];
    XCTAssertTrue(reachability.reachable);
}

- (void)testDelegate
{
    TOReachability *reachability = [[TOReachability alloc] init];
    reachability.requiresLocalNetworkConnection = YES;

    XCTAssertNotNil(reachability);

    self.delegateExpectation = [[XCTestExpectation alloc] initWithDescription:@"Delegate successfully called"];

    reachability.delegate = self;
    [reachability startListening];

    [self waitForExpectations:@[self.delegateExpectation] timeout:1.0f];
}

- (void)testListeners
{
    TOReachability *reachability = [[TOReachability alloc] init];
    reachability.requiresLocalNetworkConnection = YES;

    XCTAssertNotNil(reachability);

    self.delegateExpectation = [[XCTestExpectation alloc] initWithDescription:@"Listener successfully called"];

    [reachability addListener:self];
    XCTAssertEqual(reachability.listeners.count, 1);

    [reachability removeListener:self];
    XCTAssertEqual(reachability.listeners.count, 0);

    [reachability addListener:self];
    XCTAssertEqual(reachability.listeners.count, 1);

    [reachability startListening];

    [self waitForExpectations:@[self.delegateExpectation] timeout:1.0f];
}

- (void)reachability:(TOReachability *)reachability didChangeStatusTo:(TOReachabilityStatus)status fromStatus:(TOReachabilityStatus)fromStatus
{
    [self.delegateExpectation fulfill];
}

@end
