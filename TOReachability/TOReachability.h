//
//  TOReachability.h
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

#import <Foundation/Foundation.h>

/** The current status of the device reachability */
typedef NS_ENUM(NSInteger, TOReachabilityStatus) {
    TOReachabilityStatusNotAvailable = 0,
    TOReachabilityStatusAvailableViaWiFi,
    TOReachabilityStatusAvailableViaWWAN
} NS_SWIFT_NAME(Reachability.Status);

// An NSNotification that will broadcast network status changes
extern NSString *kTOReachabilityChangedNotification;

@class TOReachability;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Reachability)
@interface TOReachability : NSObject

/** Indiciates when the reacability class has been started and is currently running. */
@property (nonatomic, readonly) BOOL running NS_SWIFT_NAME(isRunning);

/** When YES, will broadcast whenever the network status changes via Notification Center (Default is NO) */
@property (nonatomic, assign) BOOL broadcastStatusChangeNotifications;

/** The current status of network reachability */
@property (nonatomic, readonly) TOReachabilityStatus currentStatus;

/** WWAN on cellular, or WiFi on VPN on demand may be available, but first a connection must be attempted. */
@property (nonatomic, readonly) BOOL connectionRequired;

/** A block that is called each time the network status changes */
@property (nonatomic, copy, nullable) void (^statusChangedHandler)(TOReachabilityStatus newStatus,
                                                                    TOReachabilityStatus previousStatus);

/**
 Creates a new instance of the reachability class, that can be used
 to check the status of a specific hostname.
 
 @return A new instance of the reachability object
 */
+ (instancetype)reachabilityForInternetConnection;

/**
 Creates a new instance of the reachability class, that can be used
 to check only when on Wifi or not (Status will be `notAvailable` otherwise)
 
 @return A new instance of the reachability object
 */
+ (instancetype)reachabilityForWifiConnection;

/**
 Creates a new instance of the reachability class, that can be used
 to check the status of a specific hostname.

 @param hostName The hostname to monitor
 @return A new instance of the reachability object
 */
+ (instancetype)reachabilityWithHostName:(NSString *)hostName;

/** Start watching for reachability changes */
- (BOOL)start;

/** Stop watching for reachability changes */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
