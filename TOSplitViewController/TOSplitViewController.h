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

@optional

- (BOOL)splitViewControllerShouldShowSecondaryColumn:(TOSplitViewController *)splitViewController;

- (nullable UIViewController *)primaryViewControllerForCollapsingSplitViewController:(TOSplitViewController *)splitViewController
                                                         fromSecondaryViewController:(UIViewController *)secondaryViewController;

- (nullable UIViewController *)primaryViewControllerForCollapsingSplitViewController:(TOSplitViewController *)splitViewController
                                                         fromDetailViewController:(UIViewController *)detailViewController;

- (nullable UIViewController *)splitViewController:(TOSplitViewController *)splitViewController
        expandSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController;

- (nullable UIViewController *)splitViewController:(TOSplitViewController *)splitViewController
        expandDetailViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController;

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
 * The delegate object receiving events from this view controller
 */
@property (nonatomic, weak) id<TOSplitViewControllerDelegate> delegate;

/**
 * The view controllers currently visible on-screen, from left-to-right
 */
@property (nonatomic, copy) NSArray<UIViewController *> *viewControllers;

/**
 * The minimum width to which the primary view controller may shrink before the controller
 * will collapse it into the secondary container. Default value is 280.0
 */
@property (nonatomic, assign) CGFloat primaryColumnMinimumWidth;

/**
 * The absolute maximum width to which the primary view controller may expand. Default value is 390.
 */
@property (nonatomic, assign) CGFloat primaryColumnMaximumWidth;

/**
 * When the secondary controller is collapsed, the preferred fractional width of the primary column.
 * Default value is 0.38
 */
@property (nonatomic, assign) CGFloat preferredPrimaryColumnWidthFraction;

/**
 * The minimum width to which the secondary view controller may shrink before the controller
 * considers collapsing it into the primary container. Default value is 320.0
 */
@property (nonatomic, assign) CGFloat secondaryColumnMinimumWidth;

/**
 * Space permitting, the width fraction of the secondary column that the controller could ideally extend to.
 * (Default is 0.3)
 */
@property (nonatomic, assign) CGFloat secondaryColumnMaximumWidth;

/**
 * The preferred fractional width of the secondary column.
 * Default value is 0.38
 */
@property (nonatomic, assign) CGFloat preferredSecondaryColumnWidthFraction;

/**
 * The minimum size the detail view controller is allowed to be before the controller considers
 * collapsing the secondary column. (Default is 430)
 */
@property (nonatomic, assign) CGFloat detailColumnMinimumWidth;

/**
 * The color of the line strokes separating each view controller (Default is dark grey)
 */
@property (nonatomic, strong) UIColor *separatorStrokeColor UI_APPEARANCE_SELECTOR;

/**
 * If the status bar is visible, the amount of horizontal space where any line separators that would be under the time will be clipped. (Default is 55)
 */
@property (nonatomic, assign) CGFloat separatorStatusBarClipWidth;

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers;

@end

NS_ASSUME_NONNULL_END
