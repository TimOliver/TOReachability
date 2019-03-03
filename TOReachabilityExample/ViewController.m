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

@property (nonatomic, strong) UIImage *notAvailableOffImage;
@property (nonatomic, strong) UIImage *notAvailableOnImage;

@property (nonatomic, strong) UIImage *wifiOffImage;
@property (nonatomic, strong) UIImage *wifiOnImage;

@property (nonatomic, strong) UIImage *cellularOffImage;
@property (nonatomic, strong) UIImage *cellularOnImage;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];

    [self setUpImages];

    __weak typeof(self) weakSelf = self;

    self.reachability = [TOReachability reachabilityForInternetConnection];
    self.reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus, TOReachabilityStatus previousStatus) {
        [weakSelf updateCells];
    };
    [self.reachability start];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGRect bounds = self.collectionView.bounds;
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;

    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        UIEdgeInsets insets = (UIEdgeInsets){16.0f, 8.0f, 16.0f, 8.0f};
        layout.sectionInset = insets;
        layout.itemSize = (CGSize){bounds.size.width - (16.0f), 124.0f};

        self.navigationController.navigationBar.largeTitleTextAttributes = nil;
    }
    else {
        UIView *view = self.navigationController.view;
        CGFloat width = 650;
        CGFloat padding = (view.frame.size.width - (width)) * 0.5f;

        UIEdgeInsets insets = layout.sectionInset;
        insets.top = 10.0f;
        insets.left = padding;
        insets.right = padding;
        layout.sectionInset = insets;

        layout.itemSize = (CGSize){width, 124};

        // Inset navigation bar
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.alignment = NSTextAlignmentJustified;
        style.firstLineHeadIndent = padding - view.layoutMargins.left;
        self.navigationController.navigationBar.largeTitleTextAttributes = @{NSParagraphStyleAttributeName: style};
    }
}

- (void)setUpImages
{
    UIColor* topColor = [UIColor colorWithRed: 0.904 green: 0.904 blue: 0.904 alpha: 1];
    UIColor* bottomColor = [UIColor colorWithRed: 0.673 green: 0.673 blue: 0.673 alpha: 1];
    self.notAvailableOffImage = [[self class] backgroundImageWithTopColor:topColor bottomColor:bottomColor];

    topColor = [UIColor colorWithRed: 1 green: 0.271 blue: 0.271 alpha: 1];
    bottomColor = [UIColor colorWithRed: 0.556 green: 0 blue: 0 alpha: 1];
    self.notAvailableOnImage = [[self class] backgroundImageWithTopColor:topColor bottomColor:bottomColor];

    topColor = [UIColor colorWithRed: 0.904 green: 0.904 blue: 0.904 alpha: 1];
    bottomColor = [UIColor colorWithRed: 0.673 green: 0.673 blue: 0.673 alpha: 1];
    self.wifiOffImage = [[self class] backgroundImageWithTopColor:topColor bottomColor:bottomColor];

    topColor = [UIColor colorWithRed: 0.029 green: 0.948 blue: 0 alpha: 1];
    bottomColor = [UIColor colorWithRed: 0.008 green: 0.329 blue: 0 alpha: 1];
    self.wifiOnImage = [[self class] backgroundImageWithTopColor:topColor bottomColor:bottomColor];

    topColor = [UIColor colorWithRed: 0.904 green: 0.904 blue: 0.904 alpha: 1];
    bottomColor = [UIColor colorWithRed: 0.673 green: 0.673 blue: 0.673 alpha: 1];
    self.cellularOffImage = [[self class] backgroundImageWithTopColor:topColor bottomColor:bottomColor];

    topColor = [UIColor colorWithRed: 1 green: 0.926 blue: 0.271 alpha: 1];
    bottomColor = [UIColor colorWithRed: 0.556 green: 0.478 blue: 0 alpha: 1];
    self.cellularOnImage = [[self class] backgroundImageWithTopColor:topColor bottomColor:bottomColor];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];

    switch (indexPath.row) {
        case 0:
            cell.titleLabel.text = @"WiFi";
            cell.imageView.image = [UIImage imageNamed:@"WiFi"];
            cell.backgroundImageView.image = self.wifiOffImage;
            cell.highlightedImageView.image = self.wifiOnImage;
            cell.highlightedImageView.alpha = (self.reachability.status == TOReachabilityStatusWiFi) ? 1.0f : 0.0f;
            break;
        case 1:
            cell.titleLabel.text = @"Cellular";
            cell.imageView.image = [UIImage imageNamed:@"Bars"];
            cell.backgroundImageView.image = self.cellularOffImage;
            cell.highlightedImageView.image = self.cellularOnImage;
            cell.highlightedImageView.alpha = (self.reachability.status == TOReachabilityStatusCellular) ? 1.0f : 0.0f;
            break;
        case 2:
            cell.titleLabel.text = @"Offline";
            cell.imageView.image = [UIImage imageNamed:@"Disconnected"];
            cell.backgroundImageView.image = self.notAvailableOffImage;
            cell.highlightedImageView.image = self.notAvailableOnImage;
            cell.highlightedImageView.alpha = (self.reachability.status == TOReachabilityStatusNotAvailable) ? 1.0f : 0.0f;
            break;
        default:
            break;
    }

    return cell;
}

- (void)updateCells
{
    [UIView animateWithDuration:0.3f animations:^{
        for (NSInteger i = 0; i < 3; i++) {
            CollectionViewCell *cell = (CollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
            if (cell == nil) { continue; }

            BOOL highlighted = NO;
            switch (i) {
                case 0: highlighted = (self.reachability.status == TOReachabilityStatusWiFi); break;
                case 1: highlighted = (self.reachability.status == TOReachabilityStatusCellular); break;
                case 2: highlighted = (self.reachability.status == TOReachabilityStatusNotAvailable); break;
            }

            cell.highlightedImageView.alpha = highlighted ? 1.0f : 0.0f;
        }
    }];
}

+ (UIImage *)backgroundImageWithTopColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor
{
    UIImage *image = nil;

    UIGraphicsBeginImageContextWithOptions((CGSize){124,124}, YES, 0.0);
    {
        //// General Declarations
        CGContextRef context = UIGraphicsGetCurrentContext();

        //// Gradient Declarations
        CGFloat gradientLocations[] = {0, 1};
        CGGradientRef gradient = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)@[(id)topColor.CGColor, (id)bottomColor.CGColor], gradientLocations);

        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 124, 124)];
        CGContextSaveGState(context);
        [rectanglePath addClip];
        CGContextDrawLinearGradient(context, gradient, CGPointMake(62, -0), CGPointMake(62, 124), kNilOptions);
        CGContextRestoreGState(context);

        //// Cleanup
        CGGradientRelease(gradient);

        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();

    return image;
}

@end
