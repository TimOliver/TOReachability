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

/// The current status of the device's reachability
typedef NS_ENUM(NSInteger, TOReachabilityStatus) {
    TOReachabilityStatusNotAvailable = 0,   /// There is presently no network connection.
    TOReachabilityStatusAvailable,          /// The device is online and connected to a network, either through WiFi or Ethernet.
    TOReachabilityStatusAvailableOnCellular /// The device is connected to a cellular service, but not WiFi or Ethernet.
} NS_SWIFT_NAME(Reachability.Status);

NS_ASSUME_NONNULL_BEGIN

/// An NSNotification that will broadcast network status changes
extern NSString *TOReachabilityStatusChangedNotification NS_SWIFT_NAME(Reachability.StatusChangedNotification);

@class TOReachability;

@protocol TOReachabilityDelegate <NSObject>

/// Called whenever the reachability status of the device changes.
/// - Parameters:
///   - reachability: The reachability object that detected the change.
///   - newStatus: The new netwotk status that the device changed to.
- (void)reachability:(TOReachability *)reachability
   didChangeStatusTo:(TOReachabilityStatus)newStatus NS_SWIFT_NAME(reachability(_:didChangeTo:));

@end

NS_SWIFT_NAME(Reachability)
@interface TOReachability : NSObject

/// Indiciates that the reachability object has been started and is currently running.
@property (nonatomic, readonly) BOOL running NS_SWIFT_NAME(isRunning);

/// The current network reachability status of the device, whether offline, online, or online with cellular.
@property (nonatomic, readonly) TOReachabilityStatus status;

/// A convenience property for checking there is an active internet connection (regardless of cellular or local connectivity)
@property (nonatomic, readonly) BOOL hasInternetConnection;

/// A convenience property for checking there is an active local connection (ie, only a WiFi or Ethernet connection)
@property (nonatomic, readonly) BOOL hasLocalNetworkConnection;

/// A convenience property for checking there is an active cellular connection, but isn't on Ethernet or WiFi.
@property (nonatomic, readonly) BOOL hasCellularConnection;

/// A delegate object that will be called whenever the reachability status changes.
@property (nonatomic, weak) id<TOReachabilityDelegate> delegate;

/// As an alternative to the delegate, a block that will be called whenever the reachability status changes.
@property (nonatomic, copy, nullable) void (^statusChangedHandler)(TOReachabilityStatus newStatus);

/// An array of all of the listener objects currently subscribed to this reachability object.
@property (nonatomic, readonly) NSArray<id<TOReachabilityDelegate>> *listeners;

/// When YES, will broadcast an NSNotification whenever the status changes. Useful for an app-wide global object. (Defualt is NO)
@property (nonatomic, assign) BOOL broadcastsStatusChangeNotifications;

/// Creates a new reachability object configured to detect whenever an active internet connection is present
/// (Whether on a cellular service, or on a local WiFi network)
+ (nullable instancetype)reachabilityForInternetConnection NS_SWIFT_NAME(forInternetConnection());

/// Creates a new reachability object configured to detect when connected to a local network (via WiFi or Ethernet) and will disregard cellular status.
/// Use this configuration for Bonjour, or other operations that require communication between two devices on the same network.
+ (nullable instancetype)reachabilityForLocalNetworkConnection NS_SWIFT_NAME(forLocalNetworkConnection());

/// Creates a new reachability object configured to detect that there is an active internet connection to an online host name.
/// - Parameter hostName: The host name to target
+ (nullable instancetype)reachabilityWithHostName:(NSString *)hostName NS_SWIFT_NAME(init(hostName:));

/// Subscribes another object as a listener for reachability changes. Useful for multiple objects instead of a single delegate.
/// Listener objects are weakly held, and do not need to be manually removed.
- (void)addListener:(id<TOReachabilityDelegate>)listener;

/// Removes an object from being a listener of reachability changes.
- (void)removeListener:(id<TOReachabilityDelegate>)listener;

/// Start watching for reachability changes.
- (BOOL)start;

/// Stop watching for reachability changes.
- (void)stop;

@end

NS_ASSUME_NONNULL_END

//! Project version number for TOReachability.	
FOUNDATION_EXPORT double TOReachabilityVersionNumber;	

//! Project version string for TOReachability.	
FOUNDATION_EXPORT const unsigned char TOReachabilityVersionString[];	
