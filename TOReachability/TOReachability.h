//
//  TOReachability.h
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

#import <Foundation/Foundation.h>

/// The current status of the device's reachability
typedef NS_ENUM(NSInteger, TOReachabilityStatus) {
    /// There is presently no network connection.
    TOReachabilityStatusNotAvailable = 0,
    /// The device is connected to a cellular service, but not WiFi or Ethernet.
    TOReachabilityStatusAvailableOnCellular,
    /// The device is online and connected to a network, regardless of WiFi, Ethernet or cellular.
    TOReachabilityStatusAvailable
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
   didChangeStatusTo:(TOReachabilityStatus)status
          fromStatus:(TOReachabilityStatus)fromStatus NS_SWIFT_NAME(reachability(_:didChangeTo:from:));

@end

NS_SWIFT_NAME(Reachability)
@interface TOReachability : NSObject

/// Indicates that the reachability object has been started and is currently running.
@property (nonatomic, readonly) BOOL running NS_SWIFT_NAME(isRunning);

/// The current network reachability status of the device, whether offline, online, or online only with cellular.
@property (nonatomic, readonly) TOReachabilityStatus status;

/// A convenience property for checking there is an active internet connection (regardless of cellular or local connectivity)
@property (nonatomic, readonly) BOOL reachable NS_SWIFT_NAME(isReachable);

/// A convenience property for checking there is an active local connection (ie, only a WiFi or Ethernet connection)
@property (nonatomic, readonly) BOOL reachableOnLocalNetwork NS_SWIFT_NAME(isReachableOnLocalNetowrk);

/// A convenience property for checking there is an active cellular connection, but isn't on Ethernet or WiFi.
@property (nonatomic, readonly) BOOL reachableOnCellular NS_SWIFT_NAME(isReachableOnCellular);

/// A delegate object that will be called whenever the reachability status changes.
@property (nonatomic, weak) id<TOReachabilityDelegate> delegate;

/// As an alternative to the delegate, a block that will be called whenever the reachability status changes.
@property (nonatomic, copy, nullable) void (^statusChangedHandler)(TOReachability *reachability, 
                                                                   TOReachabilityStatus status,
                                                                   TOReachabilityStatus fromStatus);

/// An array of all of the listener objects currently subscribed to this reachability object.
@property (nonatomic, readonly) NSArray<id<TOReachabilityDelegate>> *listeners;

/// When YES, will broadcast an NSNotification whenever the status changes.
/// (By default, this is YES for the singleton instance, but NO for every other instance)
@property (nonatomic, assign) BOOL broadcastsNotifications;

/// For cases where local network access is exclusively required, setting this to YES will ignore
/// all cellular-related status changes. (Default is NO)
@property (nonatomic, assign, readwrite) BOOL requiresLocalNetworkConnection;

/// A singleton reachability object configured to detect whenever an active internet connection is present.
/// This object will last for the entire app session, and can be used a central source for broadcast notifications.
+ (nullable instancetype)sharedReachability NS_SWIFT_NAME(shared());

/// Creates a new reachability object configured to detect whenever an active internet connection is present.
/// (Whether on a cellular service, or on a local WiFi network)
- (nullable instancetype)init;

/// Creates a new reachability object configured to detect that there is an active internet connection to an online host name.
/// - Parameter hostName: The host name to target (must not include the scheme, eg 'https')
- (nullable instancetype)initWithHostName:(NSString *)hostName NS_SWIFT_NAME(init(hostName:));

/// Subscribes another object as a listener for reachability changes. Useful for multiple objects instead of a single delegate.
/// Listener objects are weakly held, and do not need to be manually removed.
- (void)addListener:(id<TOReachabilityDelegate>)listener;

/// Removes an object from being a listener of reachability changes.
- (void)removeListener:(id<TOReachabilityDelegate>)listener;

/// Start listening for reachability changes on the main queue.
- (BOOL)startListening;

/// Start listening for reachability changes on the specified dispatch queue.
- (BOOL)startListeningOnQueue:(dispatch_queue_t)queue;

/// Stop listening for reachability changes.
- (void)stopListening;

@end

NS_ASSUME_NONNULL_END

//! Project version number for TOReachability.	
FOUNDATION_EXPORT double TOReachabilityVersionNumber;	

//! Project version string for TOReachability.	
FOUNDATION_EXPORT const unsigned char TOReachabilityVersionString[];	
