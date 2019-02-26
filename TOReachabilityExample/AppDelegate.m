//
//  AppDelegate.m
//  TOReachabilityExample
//
//  Created by Tim Oliver on 23/2/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "AppDelegate.h"
#import "TOReachability.h"

@interface AppDelegate ()

@property (nonatomic, strong) TOReachability *reachability;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.reachability = [TOReachability reachabilityForInternetConnection];
    self.reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus, TOReachabilityStatus previousStatus) {
        NSLog(@"New: %ld Old %ld", (long)newStatus, (long)previousStatus);
    };
    [self.reachability start];

    return YES;
}

@end
