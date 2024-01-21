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

@property (nonatomic, strong) TOReachability *reachability;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up an configure a new reachability instance
    __weak typeof(self) weakSelf = self;
    self.reachability = [[TOReachability alloc] init];
    self.reachability.statusChangedHandler = ^(TOReachability *reachability, 
                                               TOReachabilityStatus newStatus,
                                               TOReachabilityStatus oldStatus) {
        [weakSelf _updateCellsAnimated:YES];
    };
    [self.reachability startListening];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.collectionView.layoutMargins = UIEdgeInsetsZero;

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

#if TARGET_OS_IOS
        if (@available(iOS 11.0, *)) {
            self.navigationController.navigationBar.largeTitleTextAttributes = nil;
            self.navigationController.navigationBar.layoutMargins = self.navigationController.view.layoutMargins;
        }
#endif
    } else { // On iPad/tvOS, center the cells in the middle of the screen
        BOOL isTV = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomTV;
        UIView *view = self.view;
        CGFloat width = isTV ? 1000 : 650;
        CGFloat padding = (view.frame.size.width - (width)) * 0.5f;

        UIEdgeInsets insets = layout.sectionInset;
        insets.top = 10.0f;
        if (isTV) {
            insets.top = ((view.frame.size.height) - ((250 * 3.0f) + (layout.minimumLineSpacing * 2.0f))) * 0.5f;
        }
        insets.left = padding;
        insets.right = padding;
        layout.sectionInset = insets;

        layout.itemSize = (CGSize) {
            width, (isTV ? 250 : 125)
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
    [self _updateCellsAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

#if TARGET_OS_MACCATALYST
    // Hide the toolbar on Mac Catalyst
    UIWindowScene *scene = self.view.window.windowScene;
    scene.titlebar.titleVisibility = UITitlebarTitleVisibilityHidden;
    scene.titlebar.toolbar = nil;
#endif
}

#pragma mark - UICollectionViewDataSource -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];

    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightBold];

    BOOL highlighted = NO;

    switch (indexPath.row) {
        case 0:
            highlighted = (self.reachability.status == TOReachabilityStatusAvailable);
#if (TARGET_OS_MACCATALYST || TARGET_OS_TV)
            cell.titleLabel.text = @"Online";
#else
            cell.titleLabel.text = @"WiFi";
#endif
            cell.imageView.image = [UIImage systemImageNamed:@"wifi" withConfiguration:configuration];
            cell.highlightedView.alpha = highlighted ? 1.0f : 0.0f;
            cell.highlightedView.backgroundColor = UIColor.systemGreenColor;
            break;

        case 1:
            highlighted = (self.reachability.status == TOReachabilityStatusAvailableOnCellular);
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

    [self _updateTintingWithCell:cell highlighted:highlighted];

    return cell;
}

#pragma - Private Methods -

- (void)_updateTintingWithCell:(CollectionViewCell *)cell highlighted:(BOOL)highlighted {
    BOOL isDarkMode = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    UIColor *unhilightedColor = isDarkMode ? UIColor.whiteColor : UIColor.blackColor;

    cell.titleLabel.textColor = highlighted ? UIColor.whiteColor : unhilightedColor;
    cell.imageView.tintColor = highlighted ? UIColor.whiteColor : unhilightedColor;
}

- (void)_updateCellsAnimated:(BOOL)animated {
    void (^animationBlock)(void) = ^{
        for (NSInteger i = 0; i < 3; i++) {
            CollectionViewCell *cell = (CollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];

            if (cell == nil) {
                continue;
            }

            BOOL highlighted = NO;
            switch (i) {
                case 0: highlighted = (self.reachability.status == TOReachabilityStatusAvailable); break;
                case 1: highlighted = (self.reachability.status == TOReachabilityStatusAvailableOnCellular); break;
                case 2: highlighted = (self.reachability.status == TOReachabilityStatusNotAvailable); break;
            }

            cell.highlightedView.alpha = highlighted ? 1.0f : 0.0f;
            [self _updateTintingWithCell:cell highlighted:highlighted];
        }
    };

    if (!animated) {
        animationBlock();
        return;
    }

    [UIView animateWithDuration:0.3f animations:animationBlock];
}

@end
