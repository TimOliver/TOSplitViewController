//
//  UIViewController+TOSplitViewController.h
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 4/5/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TOSplitViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (TOSplitViewController)

@property (nonatomic, nullable, readonly) TOSplitViewController *to_splitViewController;

- (void)collapseAuxiliaryViewController:(UIViewController *)secondaryViewController
                                 ofType:(TOSplitViewControllerType)type
                 forSplitViewController:(TOSplitViewController *)splitViewController;

- (nullable UIViewController *)separateAuxiliaryViewControllerOfType:(TOSplitViewControllerType)type
                                              ForSplitViewController:(TOSplitViewController *)splitViewController;

@end

NS_ASSUME_NONNULL_END
