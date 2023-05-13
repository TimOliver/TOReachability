//
//  ViewController.m
//  TOReachabilityExample
//
//  Created by Tim Oliver on 23/2/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TOReachability.h"
#import "CollectionViewCell.h"

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

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
    self.reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus) {
        [weakSelf updateCellsAnimated:YES];
    };
    [self.reachability start];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect bounds = self.collectionView.bounds;
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;

    // On compact size classes (eg iPhone), have the cells stretch edge-to-edge
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        UIEdgeInsets insets = (UIEdgeInsets) {
            5.0f, 8.0f, 16.0f, 8.0f
        };
        layout.sectionInset = insets;
        layout.itemSize = (CGSize) {
            bounds.size.width - (16.0f), 124.0f
        };

        if (@available(iOS 11.0, *)) {
            self.navigationController.navigationBar.largeTitleTextAttributes = nil;
        }
    } else { // On iPad, center the cells in the middle of the screen
        UIView *view = self.navigationController.view;
        CGFloat width = 650;
        CGFloat padding = (view.frame.size.width - (width)) * 0.5f;

        UIEdgeInsets insets = layout.sectionInset;
        insets.top = 10.0f;
        insets.left = padding;
        insets.right = padding;
        layout.sectionInset = insets;

        layout.itemSize = (CGSize) {
            width, 124
        };

        // Inset the navigation bar so the large title also aligns with the cells
        insets = self.navigationController.navigationBar.layoutMargins;
        insets.left = padding;
        insets.right = padding;
        self.navigationController.navigationBar.layoutMargins = insets;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateCellsAnimated:NO];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];

    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightBold];

    BOOL highlighted = NO;

    switch (indexPath.row) {
        case 0:
            highlighted = (self.reachability.status == TOReachabilityStatusWiFi);
            cell.titleLabel.text = @"WiFi";
            cell.imageView.image = [UIImage systemImageNamed:@"wifi" withConfiguration:configuration];
            cell.highlightedView.alpha = highlighted ? 1.0f : 0.0f;
            cell.highlightedView.backgroundColor = UIColor.systemGreenColor;
            break;

        case 1:
            highlighted = (self.reachability.status == TOReachabilityStatusCellular);
            cell.titleLabel.text = @"Cellular";
            cell.imageView.image = [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right" withConfiguration:configuration];
            cell.highlightedView.alpha = highlighted ? 1.0f : 0.0f;
            cell.highlightedView.backgroundColor = UIColor.systemYellowColor;
            break;

        case 2:
            highlighted = (self.reachability.status == TOReachabilityStatusNotAvailable);
            cell.titleLabel.text = @"Offline";
            cell.imageView.image = [UIImage systemImageNamed:@"icloud.slash" withConfiguration:configuration];
            cell.highlightedView.alpha = highlighted ? 1.0f : 0.0f;
            cell.highlightedView.backgroundColor = UIColor.systemRedColor;
            break;

        default:
            break;
    }

    [self updateTintingWithCell:cell highlighted:highlighted];

    return cell;
}

- (void)updateTintingWithCell:(CollectionViewCell *)cell highlighted:(BOOL)highlighted {
    BOOL isDarkMode = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    UIColor *unhilightedColor = isDarkMode ? UIColor.whiteColor : UIColor.blackColor;

    cell.titleLabel.textColor = highlighted ? UIColor.whiteColor : unhilightedColor;
    cell.imageView.tintColor = highlighted ? UIColor.whiteColor : unhilightedColor;
}

- (void)updateCellsAnimated:(BOOL)animated
{
    void (^animationBlock)(void) = ^{
        for (NSInteger i = 0; i < 3; i++) {
            CollectionViewCell *cell = (CollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];

            if (cell == nil) {
                continue;
            }

            BOOL highlighted = NO;
            switch (i) {
                case 0: highlighted = (self.reachability.status == TOReachabilityStatusWiFi); break;

                case 1: highlighted = (self.reachability.status == TOReachabilityStatusCellular); break;

                case 2: highlighted = (self.reachability.status == TOReachabilityStatusNotAvailable); break;
            }

            cell.highlightedView.alpha = highlighted ? 1.0f : 0.0f;
            [self updateTintingWithCell:cell highlighted:highlighted];
        }
    };

    if (!animated) {
        animationBlock();
        return;
    }

    [UIView animateWithDuration:0.3f animations:animationBlock];
}

@end
