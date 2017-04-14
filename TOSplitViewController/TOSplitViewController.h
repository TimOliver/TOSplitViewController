//
//  TOSplitViewController.h
//
//  Copyright 2017 Timothy Oliver. All rights reserved.
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TOSplitViewController;

//NSNotificationName const TOSplitViewControllerShowDetailTargetDidChangeNotification;

typedef NS_ENUM(NSInteger, TOSplitViewControllerType) {
    TOSplitViewControllerTypePrimary,  // The main view controller. Only this one is visible in compact-width views.
    TOSplitViewControllerTypeDetail,   // The widest controller, always shown in regular-width views, along the right hand side
    TOSplitViewControllerTypeSecondary // The most optional controller. Only shown in between the primary and detail controllers when there's enough horizontal space.
};

/**
 * A category for `UIViewController` that exposes the functionality of `TOSplitViewController` to
 * its child view controllers.
 */

@interface UIViewController (TOSplitViewController)

@property (nonatomic, nullable, readonly) TOSplitViewController *to_splitViewController;

- (void)collapseAuxiliaryViewController:(UIViewController *)auxiliaryViewController
                                 ofType:(TOSplitViewControllerType)type
                 forSplitViewController:(TOSplitViewController *)splitViewController
                          shouldAnimate:(BOOL)animate;

- (nullable UIViewController *)separateAuxiliaryViewController:(UIViewController *)auxiliaryViewController
                                                        ofType:(TOSplitViewControllerType)type
                                        forSplitViewController:(TOSplitViewController *)splitViewController
                                                 shouldAnimate:(BOOL)animate;

/*
 Finds the first view controller in the hierarchy that can handle this (usually a navigation controller),
 and then calls it to present the new controller.
 */
- (void)to_showViewController:(nullable UIViewController *)viewController sender:(nullable id)sender;

/*
 Presents `viewController` as the new secondary view controller. If another secondary view controller was
 already set, this will completely remove that view controller from the stack. If the secondary controller
 is currently collapsed into the primary controller, this will then collapse the secondary controller into the primary.
 */
- (void)to_showSecondaryViewController:(nullable UIViewController *)viewController sender:(nullable id)sender;

/*
 Presents `secondaryViewController` as the new secondary view controller, just like `showSecondaryController:sender`.
 It will also replace the current detail view controller with the one specified, but will not transition to it.
 This is so full-screen presentations can display a 'default' view controller in the detail column before the user
 has started focussing on it.
 */
- (void)to_showSecondaryViewController:(nullable UIViewController *)secondaryViewController
              withDetailViewController:(nullable UIViewController *)detailViewController
                                sender:(nullable id)sender;

/*
 Presents `viewController` as the new detail view controller. If another secondary view controller was
 already set, this will completely remove that view controller from the stack. If the secondary controller
 is currently collapsed into the primary controller, this will then collapse the secondary controller into the primary.
 */
- (void)to_showDetailViewController:(nullable UIViewController *)viewController sender:(nullable id)sender;

@end

/**
 * A delegate protocol to allow an object to custom handle the transition and presentation of 
 * the child view controllers.
 */

@protocol TOSplitViewControllerDelegate <NSObject>

@optional

- (BOOL)splitViewController:(TOSplitViewController *)splitViewController
showSecondaryViewController:(UIViewController *)vc
                     sender:(nullable id)sender;

- (BOOL)splitViewController:(TOSplitViewController *)splitViewController
   showDetailViewController:(UIViewController *)vc
                     sender:(nullable id)sender;

- (BOOL)splitViewController:(TOSplitViewController *)splitViewController
     collapseViewController:(UIViewController *)auxiliaryViewController
                     ofType:(TOSplitViewControllerType)controllerType
  ontoPrimaryViewController:(UIViewController *)primaryViewController
              shouldAnimate:(BOOL)animate;

- (nullable UIViewController *)splitViewController:(TOSplitViewController *)splitViewController
                      separateViewControllerOfType:(TOSplitViewControllerType)type
                         fromPrimaryViewController:(UIViewController *)primaryViewController;

- (nullable UIViewController *)splitViewController:(TOSplitViewController *)splitViewController
        primaryViewControllerForCollapsingFromType:(TOSplitViewControllerType)type;

- (nullable UIViewController *)splitViewController:(TOSplitViewController *)splitViewController
           primaryViewControllerForExpandingToType:(TOSplitViewControllerType)type;

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
 * The view controllers currently managed as children of this split view controller.
 * This array will not change, even if its children are collapsed during a transition.
 * Once set, it is recommended to use the `showViewController` methods to update the UI
 * instead of further modifying it.
 */
@property (nonatomic, copy) NSArray<UIViewController *> *viewControllers;

/**
 * The view controllers currently visible on screen. This property will update after
 * each size transition has occurred and is most useful for checking the current state of the
 * split view controller.
 */
@property (nonatomic, readonly) NSArray<UIViewController *> *visibleViewControllers;

/**
 * The child controller designated as the primary view controller. This one is
 * on the far left of the screen, and is always visible in all configurations.
 */
@property (nonatomic, nullable, readonly) UIViewController *primaryViewController;

/**
 * The secondary view controller is the middle view controller, when all 3
 * child controllers are visible. It is `nil` in every other case.
 */
@property (nonatomic, nullable, readonly) UIViewController *secondaryViewController;

/**
 * The largest of the view controllers; located on the far right and the only one
 * to have a regular horizontal size class. This property will be valid when there are
 * 2 or 3 controllers visible, and `nil` if only one is visible.
 */
@property (nonatomic, nullable, readonly) UIViewController *detailViewController;

/**
 * The maximum number of columns this controller is allowed to show.
 * Default value is 3, and can only be decreased to 1.
 */
@property (nonatomic, assign) NSInteger maximumNumberOfColumns;

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
