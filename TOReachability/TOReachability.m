//
//  TOReachability.m
//
//  Copyright 2019-2023 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <arpa/inet.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreFoundation/CoreFoundation.h>

#import "TOReachability.h"

// -------------------------------------------------------------

NSString *TOReachabilityStatusChangedNotification = @"TOReachabilityStatusChangedNotification";

// -------------------------------------------------------------

@interface TOReachability ()

@property (nonatomic, assign, readwrite) BOOL running;
@property (nonatomic, assign, readwrite) TOReachabilityStatus status;
@property (nonatomic, assign) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, assign) BOOL wifiOnly;

- (TOReachabilityStatus)fetchNewStatusWithFlags:(SCNetworkReachabilityFlags)flags;
- (void)broadcastStatusChange;

@end

// -------------------------------------------------------------

static void TOReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    TOReachability *reachability = (__bridge TOReachability *)info;
    reachability.status = [reachability fetchNewStatusWithFlags:flags];
    [reachability broadcastStatusChange];
}

// -------------------------------------------------------------

@implementation TOReachability

#pragma mark - Object Creation -

+ (instancetype)reachabilityForInternetConnection {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    // Create a new reachability reference using a zero address
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault,
                                                                                      (const struct sockaddr *)&zeroAddress);
    if (reachabilityRef == NULL) { return nil; }

    TOReachability *reachability = [[TOReachability alloc] init];
    reachability.reachabilityRef = reachabilityRef;
    return reachability;
}

+ (instancetype)reachabilityForLocalNetworkConnection {
    // Create a zero address reachability object and configure it to only care about wifi
    TOReachability *reachability = [[self class] reachabilityForInternetConnection];

    reachability.wifiOnly = YES;
    return reachability;
}

+ (instancetype)reachabilityWithHostName:(NSString *)hostName {
    // Create a reachability object wuth the provided host name
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, hostName.UTF8String);
    if (reachabilityRef == NULL) { return nil; }

    TOReachability *reachability = [[TOReachability alloc] init];
    reachability.reachabilityRef = reachabilityRef;
    return reachability;
}

- (void)dealloc {
    [self stop];

    if (_reachabilityRef != NULL) {
        CFRelease(_reachabilityRef);
    }
}

#pragma mark - Broadcast Status Updates -

- (void)broadcastStatusChange {
    // Call the delegate if one is available
    if ([self.delegate respondsToSelector:@selector(reachability:didChangeStatusTo:)]) {
        [self.delegate reachability:self didChangeStatusTo:self.status];
    }

    // Call the block if one is available
    if (self.statusChangedHandler) {
        self.statusChangedHandler(self.status);
    }

    // Since an app could potentially have many reachability objects active at once, only broadcast when
    // the object has been explicitly configured to do so
    if (self.broadcastsStatusChangeNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TOReachabilityStatusChangedNotification object:self];
    }
}

#pragma mark - Reachability Lifecycle -

- (BOOL)start {
    if (self.running) { return YES; }

    SCNetworkReachabilityContext context = {
        0, (__bridge void *)(self), NULL, NULL, NULL
    };

    BOOL result = NO;

    if (SCNetworkReachabilitySetCallback(_reachabilityRef, TOReachabilityCallback, &context)) {
        if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
            result = YES;
        }
    }

    // Escape if starting the run loop failed
    if (!result) { return NO; }

    // Ensure we don't start running again
    self.running = YES;

    // For the initial start, check the current network state and broadcast that
    self.status = [self fetchNewStatusWithFlags:0];
    [self broadcastStatusChange];

    return result;
}

- (void)stop {
    if (!self.running) { return; }

    SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    self.running = NO;
}

#pragma mark - Reachability State Tracking -

- (TOReachabilityStatus)reachabilityStatusForFlags:(SCNetworkReachabilityFlags)flags {
    // Not reachable at all
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        return TOReachabilityStatusNotAvailable;
    }

    TOReachabilityStatus status = TOReachabilityStatusNotAvailable;

    // If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        status = TOReachabilityStatusAvailable;
    }

    // and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        //... and no [user] intervention is needed...
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            status = TOReachabilityStatusAvailable;
        }
    }

    // ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        status = TOReachabilityStatusAvailableOnCellular;
    }

    return status;
}

- (TOReachabilityStatus)fetchNewStatusWithFlags:(SCNetworkReachabilityFlags)flags {
    NSAssert(_reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");

    TOReachabilityStatus status = TOReachabilityStatusNotAvailable;

    // If provided flags were 0, try and refresh them
    if (flags == 0) {
        SCNetworkReachabilityGetFlags(_reachabilityRef, &flags);
    }

    // Convert the provided flags into a practical status value
    status = [self reachabilityStatusForFlags:flags];

    // Override cellular to "Unavailable" when only a non-cellular connection is required.
    if (status == TOReachabilityStatusAvailableOnCellular && self.wifiOnly) {
        status = TOReachabilityStatusNotAvailable;
    }

    return status;
}

#pragma mark - Internal Testing -

- (void)_triggerCellularCallback {
    SCNetworkReachabilityFlags flags = kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsIsWWAN;

    TOReachabilityCallback(_reachabilityRef, flags, (__bridge void *)(self));
}

@end
