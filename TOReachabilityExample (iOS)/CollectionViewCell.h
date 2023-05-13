//
//  CollectionViewCell.h
//  TOReachabilityExample
//
//  Created by Tim Oliver on 3/3/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *unhighlightedView;
@property (weak, nonatomic) IBOutlet UIView *highlightedView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

NS_ASSUME_NONNULL_END
