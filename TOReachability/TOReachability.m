//
//  TOReachability.m
//
//  Copyright 2019-2024 Timothy Oliver. All rights reserved.
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
#import <os/lock.h>

#import "TOReachability.h"

#define TO_REACHABILITY_OBJC_DIRECT __attribute__((objc_direct))

// -------------------------------------------------------------

NSString *TOReachabilityStatusChangedNotification = @"TOReachabilityStatusChangedNotification";

// -------------------------------------------------------------

@interface TOReachability ()
- (void)_flagsDidChange:(SCNetworkReachabilityFlags)flags TO_REACHABILITY_OBJC_DIRECT;
@end

// -------------------------------------------------------------

static void TOReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    TOReachability *reachability = (__bridge TOReachability *)info;
    [reachability _flagsDidChange:flags];
}

// -------------------------------------------------------------

@implementation TOReachability {
    BOOL _running;
    TOReachabilityStatus _status;
    NSHashTable *_listeners;
    SCNetworkReachabilityRef _reachabilityRef;
    os_unfair_lock _lock;
}

#pragma mark - Object Creation -

+ (instancetype)defaultReachability {
    static dispatch_once_t onceToken;
    static TOReachability *_defaultReachabilty;
    dispatch_once(&onceToken, ^{
        _defaultReachabilty = [TOReachability reachabilityForInternetConnection];
        _defaultReachabilty.broadcastsNotifications = YES;
    });
    return _defaultReachabilty;
}

+ (instancetype)reachabilityForInternetConnection {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    // Create a new reachability reference using a zero address
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault,
                                                                                      (const struct sockaddr *)&zeroAddress);
    if (reachabilityRef == NULL) { return nil; }

    TOReachability *reachability = [[TOReachability alloc] initWithReachabilityRef:reachabilityRef];
    CFRelease(reachabilityRef);
    return reachability;
}

+ (instancetype)reachabilityWithHostName:(NSString *)hostName {
    // Create a reachability object wuth the provided host name
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, hostName.UTF8String);
    if (reachabilityRef == NULL) { return nil; }

    TOReachability *reachability = [[TOReachability alloc] initWithReachabilityRef:reachabilityRef];
    CFRelease(reachabilityRef);
    return reachability;
}

- (instancetype)initWithReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef {
    if (self = [super init]) {
        _lock = OS_UNFAIR_LOCK_INIT;
        _reachabilityRef = reachabilityRef;
        _running = NO;
        _status = TOReachabilityStatusNotAvailable;;
    }
    return self;
}

- (void)dealloc {
    [self stopListening];
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

#pragma mark - Reachability Lifecycle -

- (BOOL)startListening {
    return [self startListeningOnQueue:dispatch_get_main_queue()];
}

- (BOOL)startListeningOnQueue:(dispatch_queue_t)queue {
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
    _status = TOReachabilityStatusNotAvailable;

    return result;
}

- (void)stopListening {
    if (!_running) { return; }
    SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    _running = NO;
}

#pragma mark - Reachability State Tracking -

- (TOReachabilityStatus)_reachabilityStatusForFlags:(SCNetworkReachabilityFlags)flags TO_REACHABILITY_OBJC_DIRECT {
    // Parse the current flags to determine our current connectivity state
    // This is the same logic from Apple's Reachability example, but derived from Alamofire's
    // reachability manager object which condenses it down to a much more succinct check.
    // https://github.com/Alamofire/Alamofire/blob/master/Source/NetworkReachabilityManager.swift
    const BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
    const BOOL isConnectionRequired = (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0;
    const BOOL canConnectAutomatically = (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0 ||
                                         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0;
    const BOOL canConnectWithoutUserInteraction = canConnectAutomatically &&
                                                    (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0;
    const BOOL isActuallyReachable = isReachable && (!isConnectionRequired || canConnectWithoutUserInteraction);

    // Only bother with the WWAN check on devices with embedded celluar modems (ie iPhone and iPad)
#if (TARGET_OS_OSX || TARGET_OS_MACCATALYST || TARGET_OS_TV || TARGET_OS_VISION)
    const BOOL isWWAN = NO;
#else
    const BOOL isWWAN = (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0;
#endif

    // Check if we're properly reachable, or if we're on WWAN, but we require a local connection
    if (!isActuallyReachable || (isWWAN && _requiresLocalNetworkConnection)) {
        return TOReachabilityStatusNotAvailable;
    }

    return isWWAN ? TOReachabilityStatusAvailableOnCellular : TOReachabilityStatusAvailable;
}

- (void)_flagsDidChange:(SCNetworkReachabilityFlags)flags TO_REACHABILITY_OBJC_DIRECT {
    NSAssert(_reachabilityRef != NULL, @"flags change called with NULL SCNetworkReachabilityRef");

    // If provided flags were 0, try and refresh them
    if (flags == 0) {
        SCNetworkReachabilityGetFlags(_reachabilityRef, &flags);
    }

    TOReachabilityStatus fromStatus = _status;
    _status = [self _reachabilityStatusForFlags:flags];

    // Update the delegate with the status change
    [_delegate reachability:self didChangeStatusTo:_status fromStatus:fromStatus];

    // Update any available listeners with the status change
    for (id<TOReachabilityDelegate> listener in _listeners) {
        [listener reachability:self didChangeStatusTo:_status fromStatus:fromStatus];
    }

    // Call the block if one is available
    if (_statusChangedHandler) {
        _statusChangedHandler(self, _status, fromStatus);
    }

    // Broadcast a notification if configured to do so
    if (_broadcastsNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TOReachabilityStatusChangedNotification object:self];
    }
}

#pragma mark - Public Accessors -

- (NSArray<id<TOReachabilityDelegate>> *)listeners {
    return _listeners.allObjects;
}

- (BOOL)reachable {
    return (_status == TOReachabilityStatusAvailable ||
            _status == TOReachabilityStatusAvailableOnCellular);
}

- (BOOL)hasLocalNetworkConnection {
    return _status == TOReachabilityStatusAvailable;
}

- (BOOL)hasCellularConnection {
    return _status == TOReachabilityStatusAvailableOnCellular;
}

#pragma mark - Thread Safety -

- (void)_performWithLock:(void (^)(__weak TOReachability *weakSelf))block TO_REACHABILITY_OBJC_DIRECT {
    os_unfair_lock_lock(&_lock);
    __weak __typeof(self) weakSelf = self;
    block(weakSelf);
    os_unfair_lock_unlock(&_lock);
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
