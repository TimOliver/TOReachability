//
//  TOReachability.m
//
//  Copyright 2019 Timothy Oliver. All rights reserved.
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

NSString *kTOReachabilityChangedNotification = @"TOReachabilityChangedNotification";

// -------------------------------------------------------------

@interface TOReachability ()

@property (nonatomic, assign, readwrite) BOOL running;
@property (nonatomic, assign, readwrite) TOReachabilityStatus currentStatus;
@property (nonatomic, assign) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, assign) BOOL wifiOnly;

- (TOReachabilityStatus)fetchNewStatus;

@end

// -------------------------------------------------------------

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    TOReachability *reachability = (__bridge TOReachability *)info;

    // Save the old status for the notification block and grab the new one
    TOReachabilityStatus previousStatus = reachability.currentStatus;
    reachability.currentStatus = [reachability fetchNewStatus];

    // Call the block if it was set
    if (reachability.statusChangedHandler) {
        reachability.statusChangedHandler(reachability.currentStatus, previousStatus);
    }

    // Since an app could potentially have many reachability objects active at once, only broadcast when
    // the object has been explicitly configured to do so
    if (reachability.broadcastStatusChangeNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTOReachabilityChangedNotification object:reachability];
    }
}

// -------------------------------------------------------------

@implementation TOReachability

#pragma mark - Object Creation -

+ (instancetype)reachabilityForInternetConnection
{
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

+ (instancetype)reachabilityForWifiConnection
{
    // Create a zero address reachability object and configure it to only care about wifi
    TOReachability *reachability = [[self class] reachabilityForInternetConnection];
    reachability.wifiOnly = YES;
    return reachability;
}

+ (instancetype)reachabilityWithHostName:(NSString *)hostName
{
    // Create a reachability object wuth the provided host name
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, hostName.UTF8String);
    if (reachabilityRef == NULL) { return nil; }

    TOReachability *reachability = [[TOReachability alloc] init];
    reachability.reachabilityRef = reachabilityRef;

    return reachability;
}

- (void)dealloc
{
    [self stop];
    if (_reachabilityRef != NULL) {
        CFRelease(_reachabilityRef);
    }
}

#pragma mark - Reachability Lifecycle -

- (BOOL)start
{
    if (self.running) { return YES; }

    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};

    BOOL result = NO;
    if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context)) {
        if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
            result = YES;
        }
    }

    // Escape if starting the run loop failed
    if (!result) { return NO; }

    // Ensure we don't start running again
    self.running = YES;

    // For the initial start, trigger the block to create an initial callback
    self.currentStatus = [self fetchNewStatus];
    if (self.statusChangedHandler) {
        self.statusChangedHandler(self.currentStatus, 0);
    }

    // Perform a broadcast of the current status if desired
    if (self.broadcastStatusChangeNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTOReachabilityChangedNotification object:self];
    }

    return result;
}

- (void)stop
{
    if (!self.running) { return; }
    SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    self.running = NO;
}

#pragma mark - Reachability State Tracking -

- (TOReachabilityStatus)reachabilityStatusForFlags:(SCNetworkReachabilityFlags)flags
{
    // Not reachable at all
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        return TOReachabilityStatusNotAvailable;
    }

    TOReachabilityStatus status = TOReachabilityStatusNotAvailable;

    // If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        status = TOReachabilityStatusAvailableViaWiFi;
    }

    // and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        //... and no [user] intervention is needed...
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            status = TOReachabilityStatusAvailableViaWiFi;
        }
    }

    // ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        status = TOReachabilityStatusAvailableViaWWAN;
    }

    return status;
}

- (TOReachabilityStatus)fetchNewStatus
{
    NSAssert(_reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");

    TOReachabilityStatus status = TOReachabilityStatusNotAvailable;

    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        status = [self reachabilityStatusForFlags:flags];
    }

    // Override WWAN to "Unavailable" when only a Wi-Fi signal is desired
    if (status == TOReachabilityStatusAvailableViaWWAN && self.wifiOnly) {
        status = TOReachabilityStatusNotAvailable;
    }

    return status;
}

@end
