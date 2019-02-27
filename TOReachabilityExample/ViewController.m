//
//  ViewController.m
//  TOReachabilityExample
//
//  Created by Tim Oliver on 23/2/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TOReachability.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *wifiView;
@property (weak, nonatomic) IBOutlet UIImageView *barsView;
@property (weak, nonatomic) IBOutlet UIImageView *disconnectedView;

@property (weak, nonatomic) IBOutlet UILabel *wifiLabel;
@property (weak, nonatomic) IBOutlet UILabel *barsLabel;
@property (weak, nonatomic) IBOutlet UILabel *disconnectedLabel;

@property (nonatomic, strong) TOReachability *reachability;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;

    self.reachability = [TOReachability reachabilityForInternetConnection];
    self.reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus, TOReachabilityStatus previousStatus) {
        [weakSelf updateLabelsForStatus];
    };
    [self.reachability start];
}

- (void)updateLabelsForStatus
{
    TOReachabilityStatus status = self.reachability.currentStatus;

    if (status == TOReachabilityStatusAvailableViaWiFi) {
        self.wifiView.tintColor = [UIColor greenColor];
        self.wifiLabel.textColor = [UIColor greenColor];
    }
    else {
        self.wifiView.tintColor = [UIColor blackColor];
        self.wifiLabel.textColor = [UIColor blackColor];
    }

    if (status == TOReachabilityStatusAvailableViaWWAN) {
        self.barsView.tintColor = [UIColor yellowColor];
        self.barsLabel.textColor = [UIColor yellowColor];
    }
    else {
        self.barsView.tintColor = [UIColor blackColor];
        self.barsLabel.textColor = [UIColor blackColor];
    }

    if (status == TOReachabilityStatusNotAvailable) {
        self.disconnectedView.tintColor = [UIColor redColor];
        self.disconnectedLabel.textColor = [UIColor redColor];
    }
    else {
        self.disconnectedView.tintColor = [UIColor blackColor];
        self.disconnectedLabel.textColor = [UIColor blackColor];
    }
}

@end
