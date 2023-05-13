//
//  TOReachability.h
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

#import <Foundation/Foundation.h>

/** The current status of the device reachability */
typedef NS_ENUM(NSInteger, TOReachabilityStatus) {
    TOReachabilityStatusNotAvailable = 0,
    TOReachabilityStatusWiFi,
    TOReachabilityStatusCellular
} NS_SWIFT_NAME(Reachability.Status);

NS_ASSUME_NONNULL_BEGIN

// An NSNotification that will broadcast network status changes
extern NSString *TOReachabilityStatusChangedNotification NS_SWIFT_NAME(Reachability.StatusChangedNotification);

@class TOReachability;

@protocol TOReachabilityDelegate <NSObject>

- (void)reachability:(TOReachability *)reachability didChangeStatusTo:(TOReachabilityStatus)newStatus NS_SWIFT_NAME(reachability(_:didChangeTo:));

@end

NS_SWIFT_NAME(Reachability)
@interface TOReachability : NSObject

/** Indiciates when the reachability class has been started and is currently running. */
@property (nonatomic, readonly) BOOL running NS_SWIFT_NAME(isRunning);

/** When YES, will broadcast an NSNotification whenever the status changes. Useful for an app-wide global object. (Defualt is NO) */
@property (nonatomic, assign) BOOL broadcastsStatusChangeNotifications;

/** The current status of network reachability */
@property (nonatomic, readonly) TOReachabilityStatus status;

/** A delegate object that will be informed of status changes. */
@property (nonatomic, weak) id<TOReachabilityDelegate> delegate;

/** A block that is called each time the network status changes */
@property (nonatomic, copy, nullable) void (^statusChangedHandler)(TOReachabilityStatus newStatus);

/**
 Creates a new instance of the reachability class, that can be used
 to check the status of a specific hostname.
 
 @return A new instance of the reachability object
 */
+ (instancetype)reachabilityForInternetConnection NS_SWIFT_NAME(forInternetConnection());

/**
 Creates a new instance of the reachability class, that can be used
 to check only when on Wifi or not (Status will be `notAvailable` otherwise)
 
 @return A new instance of the reachability object
 */
+ (instancetype)reachabilityForWifiConnection NS_SWIFT_NAME(forWifiConnection());

/**
 Creates a new instance of the reachability class, that can be used
 to check the status of a specific hostname.

 @param hostName The hostname to monitor
 @return A new instance of the reachability object
 */
+ (instancetype)reachabilityWithHostName:(NSString *)hostName NS_SWIFT_NAME(init(hostName:));

/** Start watching for reachability changes */
- (BOOL)start;

/** Stop watching for reachability changes */
- (void)stop;

@end

NS_ASSUME_NONNULL_END

//! Project version number for TOReachability.	
FOUNDATION_EXPORT double TOReachabilityVersionNumber;	

//! Project version string for TOReachability.	
FOUNDATION_EXPORT const unsigned char TOReachabilityVersionString[];	
