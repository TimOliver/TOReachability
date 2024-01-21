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
@property (nonatomic, assign, readwrite) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, assign, readwrite) BOOL wifiOnly;

- (TOReachabilityStatus)_fetchNewStatusWithFlags:(SCNetworkReachabilityFlags)flags;
- (void)_broadcastStatusChangeFromStatus:(TOReachabilityStatus)fromStatus;

@end

// -------------------------------------------------------------

static void TOReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    TOReachability *reachability = (__bridge TOReachability *)info;
    const TOReachabilityStatus fromStatus = reachability.status;
    reachability.status = [reachability _fetchNewStatusWithFlags:flags];
    [reachability _broadcastStatusChangeFromStatus:fromStatus];
}

// -------------------------------------------------------------

@implementation TOReachability {
    NSHashTable *_listeners;
}

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
    [_listeners removeAllObjects];
    if (_reachabilityRef != NULL) {
        CFRelease(_reachabilityRef);
    }
}

#pragma mark - Broadcast Status Handling -

- (void)addListener:(id<TOReachabilityDelegate>)listener {
    if (_listeners == nil) {
        _listeners = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    [_listeners addObject:listener];
}

- (void)removeListener:(id<TOReachabilityDelegate>)listener {
    [_listeners removeObject:listener];
}

- (void)_broadcastStatusChangeFromStatus:(TOReachabilityStatus)fromStatus {
    // Update the delegate with the status change
    [_delegate reachability:self didChangeStatusTo:_status];

    // Update any available listeners with the status change
    for (id<TOReachabilityDelegate> listener in _listeners) {
        [listener reachability:self didChangeStatusTo:_status];
    }

    // Call the block if one is available
    if (_statusChangedHandler) {
        _statusChangedHandler(self, _status, fromStatus);
    }

    // Since an app could potentially have many reachability objects active at once, only broadcast when
    // the object has been explicitly configured to do so
    if (_broadcastsStatusChangeNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TOReachabilityStatusChangedNotification object:self];
    }
}

#pragma mark - Reachability Lifecycle -

- (BOOL)start {
    if (_running) { return YES; }

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
    _running = YES;

    // For the initial start, check the current network state and broadcast that
    _status = [self _fetchNewStatusWithFlags:0];
    [self _broadcastStatusChangeFromStatus:TOReachabilityStatusNotAvailable];

    return result;
}

- (void)stop {
    if (!_running) { return; }
    SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    _running = NO;
}

#pragma mark - Reachability State Tracking -

- (TOReachabilityStatus)_reachabilityStatusForFlags:(SCNetworkReachabilityFlags)flags {
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

#if !TARGET_OS_OSX
    // ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        status = TOReachabilityStatusAvailableOnCellular;
    }
#endif

    return status;
}

- (TOReachabilityStatus)_fetchNewStatusWithFlags:(SCNetworkReachabilityFlags)flags {
    NSAssert(_reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");

    TOReachabilityStatus status = TOReachabilityStatusNotAvailable;

    // If provided flags were 0, try and refresh them
    if (flags == 0) {
        SCNetworkReachabilityGetFlags(_reachabilityRef, &flags);
    }

    // Convert the provided flags into a practical status value
    status = [self _reachabilityStatusForFlags:flags];

    // Override cellular to "Unavailable" when only a non-cellular connection is required.
    if (status == TOReachabilityStatusAvailableOnCellular && _wifiOnly) {
        status = TOReachabilityStatusNotAvailable;
    }

    return status;
}

#pragma mark - Public Accessors -

- (NSArray<id<TOReachabilityDelegate>> *)listeners {
    return _listeners.allObjects;
}

- (BOOL)hasInternetConnection {
    return _status == TOReachabilityStatusAvailable || _status == TOReachabilityStatusAvailableOnCellular;
}

- (BOOL)hasLocalNetworkConnection {
    return _status == TOReachabilityStatusAvailable;
}

- (BOOL)hasCellularConnection {
    return _status == TOReachabilityStatusAvailableOnCellular;
}

#pragma mark - Internal Testing -

- (void)_triggerCallbackWithCellular:(BOOL)cellular wifi:(BOOL)wifi {
    SCNetworkReachabilityFlags flags = kSCNetworkReachabilityFlagsReachable;
    if (wifi) {
        flags |= kSCNetworkReachabilityFlagsConnectionOnDemand;
    }
#if !TARGET_OS_OSX
    if (cellular) {
        flags |= kSCNetworkReachabilityFlagsIsWWAN;
    }
#endif
    TOReachabilityCallback(_reachabilityRef, flags, (__bridge void *)(self));
}

@end
