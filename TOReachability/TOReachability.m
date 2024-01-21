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
@property (nonatomic, readonly) SCNetworkReachabilityFlags flags;
- (void)_flagsDidChange:(SCNetworkReachabilityFlags)flags TO_REACHABILITY_OBJC_DIRECT;
@end

// -------------------------------------------------------------

static void TOReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    TOReachability *const reachability = (__bridge TOReachability *)info;
    [reachability _flagsDidChange:flags];
}

// -------------------------------------------------------------

@implementation TOReachability {
    BOOL _running;
    TOReachabilityStatus _status;
    NSHashTable *_listeners;
    SCNetworkReachabilityRef _reachabilityRef;
    os_unfair_lock _lock;
    dispatch_queue_t _queue;
}

#pragma mark - Object Creation -

+ (instancetype)sharedReachability {
    static dispatch_once_t onceToken;
    static TOReachability *_sharedReachabilty;
    dispatch_once(&onceToken, ^{
        _sharedReachabilty = [TOReachability new];
        _sharedReachabilty.broadcastsNotifications = YES;
    });
    return _sharedReachabilty;
}

- (nullable instancetype)init {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    // Create a new reachability reference using a zero address
    const SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault,
                                                                                      (const struct sockaddr *)&zeroAddress);
    if (reachabilityRef == NULL) { return nil; }
    if (self = [self initWithReachabilityRef:reachabilityRef]) { }
    CFRelease(reachabilityRef);
    return self;
}

- (nullable instancetype)initWithHostName:(NSString *)hostName {
    // Create a reachability object wuth the provided host name
    const SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, hostName.UTF8String);
    if (reachabilityRef == NULL) { return nil; }
    if (self = [self initWithReachabilityRef:reachabilityRef]) { }
    CFRelease(reachabilityRef);
    return self;
}

- (instancetype)initWithReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef {
    if (self = [super init]) {
        _lock = OS_UNFAIR_LOCK_INIT;
        _reachabilityRef = reachabilityRef;
        _running = NO;
        _status = TOReachabilityStatusNotAvailable;
        CFRetain(_reachabilityRef);
    }
    return self;
}

- (void)dealloc {
    SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
    SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, NULL);
    [_listeners removeAllObjects];
    if (_reachabilityRef != NULL) {
        CFRelease(_reachabilityRef);
    }
}

#pragma mark - Broadcast Status Handling -

- (void)addListener:(id<TOReachabilityDelegate>)listener {
    [self _performWithLock:^(TOReachability *strongSelf) {
        if (strongSelf->_listeners == nil) {
            strongSelf->_listeners = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        }
        [strongSelf->_listeners addObject:listener];
    }];
}

- (void)removeListener:(id<TOReachabilityDelegate>)listener {
    [self _performWithLock:^(TOReachability *strongSelf) {
        [strongSelf->_listeners removeObject:listener];
    }];
}

#pragma mark - Reachability Lifecycle -

- (BOOL)startListening {
    return [self startListeningOnQueue:dispatch_get_main_queue()];
}

- (BOOL)startListeningOnQueue:(dispatch_queue_t)queue {
    [self stopListening];

    SCNetworkReachabilityContext context = {
        0, (__bridge void *)(self), NULL, NULL, NULL
    };

    // Start the queue running
    const BOOL callbackWasSet = SCNetworkReachabilitySetCallback(_reachabilityRef, TOReachabilityCallback, &context);
    const BOOL queueWasSet = SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, queue);
    if (!callbackWasSet || !queueWasSet) {
        return NO;
    }

    // Update our internal state that we're running
    [self _performWithLock:^(TOReachability *strongSelf) {
        strongSelf->_running = YES;
        strongSelf->_queue = queue;

        // Perform an initial update in case one isn't called automatically
        dispatch_async(strongSelf->_queue, ^{
            SCNetworkReachabilityFlags flags = 0;
            SCNetworkReachabilityGetFlags(strongSelf->_reachabilityRef, &flags);
            [strongSelf _flagsDidChange:flags];
        });
    }];

    return YES;
}

- (void)stopListening {
    SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
    SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, NULL);
    [self _performWithLock:^(TOReachability *strongSelf) {
        strongSelf->_running = NO;
        strongSelf->_queue = NULL;
        strongSelf->_status = TOReachabilityStatusNotAvailable;
    }];
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
    // If provided flags were 0, try and refresh them
    if (flags == 0) {
        SCNetworkReachabilityGetFlags(_reachabilityRef, &flags);
    }

    // Update our internal status state
    __block TOReachabilityStatus fromStatus = 0;
    __block TOReachabilityStatus toStatus = 0;
    [self _performWithLock:^(TOReachability *strongSelf) {
        fromStatus = strongSelf->_status;
        toStatus = [self _reachabilityStatusForFlags:flags];
        strongSelf->_status = toStatus;
    }];

    // Update the delegate with the status change
    [_delegate reachability:self didChangeStatusTo:toStatus fromStatus:fromStatus];

    // Update any available listeners with the status change
    for (id<TOReachabilityDelegate> listener in _listeners) {
        [listener reachability:self didChangeStatusTo:toStatus fromStatus:fromStatus];
    }

    // Call the block if one is available
    if (_statusChangedHandler) {
        _statusChangedHandler(self, toStatus, fromStatus);
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

- (TOReachabilityStatus)status {
    __block TOReachabilityStatus status = 0;
    [self _performWithLock:^(TOReachability *strongSelf) {
        status = strongSelf->_status;
    }];
    return status;
}

- (BOOL)reachable {
    const TOReachabilityStatus status = self.status;
    return (status == TOReachabilityStatusAvailable ||
            status == TOReachabilityStatusAvailableOnCellular);
}

- (BOOL)reachableOnLocalNetwork {
    const TOReachabilityStatus status = self.status;
    return status == TOReachabilityStatusAvailable;
}

- (BOOL)reachableOnCellular {
    const TOReachabilityStatus status = self.status;
    return status == TOReachabilityStatusAvailableOnCellular;
}

#pragma mark - Thread Safety -

- (void)_performWithLock:(void (^)(TOReachability *strongSelf))block TO_REACHABILITY_OBJC_DIRECT {
    os_unfair_lock_lock(&_lock);
    __weak __typeof(self) weakSelf = self;
    void (^selfBlock)(void) = ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) { return; }
        block(strongSelf);
    };
    selfBlock();
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
