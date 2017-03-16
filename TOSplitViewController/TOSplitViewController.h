//
//  TOSplitViewController.h
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 3/14/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TOSplitViewController;

@protocol TOSplitViewControllerDelegate <NSObject>

@end

/**
 * A container view controller that may display up to 3 view controller in columns along a horizontal layout.
 *
 * The three controllers are described as such:
 * Primary View Controller: The narrower view controller on the far left.
 * Secondary View Controller: The next narrow view controller next to the primary one.
 * Detail View Controller: The larger view controller that takes up all remaining space.
 *
 * Depending on the amount of horizontal space available, the primary and secondary view controllers
 * are collapsed, followed by the detail view controller being collapsed.
*/

@interface TOSplitViewController : UIViewController

/**
 * The view controllers currently visible on-screen, from left-to-right
 */
@property (nonatomic, copy) NSArray<UIViewController *> *viewControllers;

/**
 * The minimum width to which the primary view controller may shrink before the controller
 * considers collapsing it into the secondary container. Default value is 320.0
 */
@property (nonatomic, assign) CGFloat primaryColumnMinimumWidth;

/**
 * Space permitting, the width fraction of the primary column that the controller could ideally extend to.
 * (Default is 0.4)
 */
@property (nonatomic, assign) CGFloat primaryColumnMaximumWidthFraction;

/**
 * The minimum width to which the secondary view controller may shrink before the controller
 * considers collapsing it into the primary container. Default value is 320.0
 */
@property (nonatomic, assign) CGFloat secondaryColumnMinimumWidth;

/**
 * Space permitting, the width fraction of the secondary column that the controller could ideally extend to.
 * (Default is 0.3)
 */
@property (nonatomic, assign) CGFloat secondaryColumnMaximumWidthFraction;

/**
 * The minimum width to which the detail view controller may shrink before the controller
 * considers collapsing it into a single view controller. Default value is 384.0
 */
@property (nonatomic, assign) CGFloat detailColumnMinimumWidth;

/**
 * Space permitting, the width fraction of the primary column that the controller could ideally extend to.
 * (Default is 0.6)
 */
@property (nonatomic, assign) CGFloat detailColumnMaximumWidthFraction;

/**
 * The color of the line strokes separating each view controller (Default is dark grey)
 */
@property (nonatomic, strong) UIColor *separatorStrokeColor UI_APPEARANCE_SELECTOR;

/**
 * If the status bar is visible, the amount of horizontal space where any line separators that would be under the time will be clipped. (Default is 55)
 */
@property (nonatomic, assign) CGFloat separatorStatusBarClipWidth;

@end

NS_ASSUME_NONNULL_END
