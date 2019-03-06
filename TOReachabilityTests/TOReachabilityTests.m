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

    reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus,
                                          TOReachabilityStatus previousStatus)
    {
        [expection fulfill];
    };
    [reachability start];

    [self waitForExpectations:@[expection] timeout:1.0f];

    XCTAssertTrue(reachability.running);
}

- (void)testNotificationBroadcast
{
    TOReachability *reachability = [TOReachability reachabilityForInternetConnection];
    reachability.broadcastStatusChangeNotifications = YES;
    XCTAssertNotNil(reachability);

    // Because `waitForExpectations:` blocks the main thread, we can't simply set up the observer and call
    // `start` afterwards
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [reachability start];
    });

    XCTNSNotificationExpectation *expectation = [[XCTNSNotificationExpectation alloc] initWithName:TOReachabilityStatusChangedNotification object:reachability];
    [self waitForExpectations:@[expectation] timeout:10.0f];
}



@end
