//
//  TOSplitViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 3/14/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "TOSplitViewController.h"

@interface TOSplitViewController () {
    struct {
        BOOL collapseSecondaryToPrimary;
        BOOL collapseDetailToPrimary;
    } _delegateFlags;
}

@end

@implementation TOSplitViewController

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
{
    if (self = [super init]) {
        _viewControllers = [viewControllers copy];
        [self setUp];
    }

    return self;
}

- (void)setUp
{
    // Primary Column
    _primaryColumnMinimumWidth = 290.0f;
    _primaryColumnMaximumWidth = 400.0f;
    _preferredPrimaryColumnWidthFraction = 0.38f;

    // Secondary Column
    _secondaryColumnMinimumWidth = 320.0f;
    _secondaryColumnMaximumWidth = 400.0f;

    // Detail Column
    _detailColumnMinimumWidth = 414.0f;
}

#pragma mark - View Lifecylce -

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    //Add all of the view controllers
    for (UIViewController *controller in self.viewControllers) {
        [self addSplitViewControllerChildViewController:controller];
    }
}

- (void)viewDidLayoutSubviews
{
    CGSize size = self.view.bounds.size;
    BOOL compact = (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    [self updateViewControllersForBoundsSize:size compactSizeClass:compact];
    [self layoutViewControllersForBoundsSize:size];
}

#pragma mark - Column Setup & Management -

- (void)addSplitViewControllerChildViewController:(UIViewController *)controller
{
    [controller willMoveToParentViewController:self];
    [self addChildViewController:controller];
    [self.view addSubview:controller.view];
    [controller didMoveToParentViewController:self];
}

- (UIViewController *)removeSplitViewControllerChildViewController:(UIViewController *)controller
{
    [controller willMoveToParentViewController:nil];
    [controller removeFromParentViewController];
    [controller.view removeFromSuperview];
    [controller didMoveToParentViewController:nil];
    return controller;
}

- (void)layoutViewControllersForBoundsSize:(CGSize)boundsSize
{
    NSInteger numberOfColumns = [self possibleNumberOfColumnsForWidth:boundsSize.width];

    CGRect frame = CGRectZero;
    for (UIViewController *controller in self.viewControllers) {
        frame.size.width = self.primaryColumnMinimumWidth;
        frame.size.height = boundsSize.height;
        [controller.view setFrame:frame];
        frame.origin.x += 320;

        UITraitCollection *horizontal = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];
        [self setOverrideTraitCollection:horizontal forChildViewController:self.viewControllers[0]];
    }
}

/**
 *
 */
- (void)updateViewControllersForBoundsSize:(CGSize)size compactSizeClass:(BOOL)compact
{
    NSInteger numberOfColumns    = self.viewControllers.count;
    NSInteger newNumberOfColumns = [self possibleNumberOfColumnsForWidth:size.width];

    if (numberOfColumns == newNumberOfColumns) { return; }

    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.viewControllers];

    // Collapse columns down to the necessary number
    while (numberOfColumns > newNumberOfColumns && controllers.count > 1) {
        UIViewController *primaryViewController = controllers.firstObject;
        UIViewController *auxiliaryViewController = controllers[1]; // Either the secondary or detail controller

        // We're collapsing the secondary controller into the primary
        UIViewController *newPrimaryController = nil;
        if (numberOfColumns == 3) {
            if (_delegateFlags.collapseSecondaryToPrimary) {
                newPrimaryController = [self.delegate primaryViewControllerForCollapsingSplitViewController:self
                                                                                fromSecondaryViewController:auxiliaryViewController];
            }
        }
        else if (numberOfColumns == 2) { // We're collapsing the detail controller into the primary
            if (_delegateFlags.collapseDetailToPrimary) {
                newPrimaryController = [self.delegate primaryViewControllerForCollapsingSplitViewController:self
                                                                                fromDetailViewController:auxiliaryViewController];
            }
        }

        // If there was a delegate that provided a user-specified view controller, override and replace
        // the current primary controller
        if (newPrimaryController) {
            [self removeSplitViewControllerChildViewController:auxiliaryViewController];
            if ([self replacePrimaryControllerWithController:newPrimaryController]) {
                [controllers replaceObjectAtIndex:0 withObject:newPrimaryController];
            }
        }
        else { // otherwise default to a merge behaviour where the auxiliary controller will add its children to the primary nav controller
            [self removeSplitViewControllerChildViewController:auxiliaryViewController];
            [self mergeViewController:auxiliaryViewController intoViewController:primaryViewController];
        }

        // Remove the controller we just merged / replaced
        [controllers removeObjectAtIndex:1];
        _viewControllers = [NSArray arrayWithArray:controllers];

        numberOfColumns--;
    }

    // Expand columns to the necessary number
    while (numberOfColumns < newNumberOfColumns && controllers.count <= 3) {

    }
}

- (BOOL)replacePrimaryControllerWithController:(UIViewController *)viewController
{
    UIViewController *primaryViewController = self.viewControllers.firstObject;

    // Skip if the new primary controller is actually the original (ie a navigation controller)
    if (viewController == primaryViewController) { return NO; }

    // Remove the original view controller and add the new one
    [self removeSplitViewControllerChildViewController:primaryViewController];
    [self addSplitViewControllerChildViewController:viewController];

    return YES;
}

- (BOOL)mergeViewController:(UIViewController *)sourceViewController intoViewController:(UIViewController *)destViewController
{
    // If the dest is a navigation controller, we can push to it, else just let the source get destroyed
    if (![destViewController isKindOfClass:[UINavigationController class]]) { return NO; }

    UINavigationController *destNavigationController = (UINavigationController *)destViewController;

    //Copy all view controllers to the primary navigation controller
    if ([sourceViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *sourceNavigationController = (UINavigationController *)sourceViewController;

        NSArray *sourceViewControllers = sourceNavigationController.viewControllers;
        sourceNavigationController.viewControllers = [NSArray array]; //Remove all view controllers from old navigation controller

        for (UIViewController *controller in sourceViewControllers) {
            [destNavigationController pushViewController:controller animated:NO];
        }
    }
    else {
        [destNavigationController pushViewController:sourceViewController animated:NO];
    }

    return YES;
}

#pragma mark - Column State Checking -

- (NSInteger)possibleNumberOfColumnsForWidth:(CGFloat)width
{
    // Not enough view controllers to display
    if (self.viewControllers.count < 2) {
        return 1;
    }

    // Not a regular side class (eg, iPhone / iPad Split View)
    if (self.view.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular) {
        return 1;
    }

    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat totalDualWidth = self.primaryColumnMinimumWidth;
    totalDualWidth += self.detailColumnMinimumWidth;

    // Check if there's enough horizontal space for all 3 columns
    if (totalDualWidth + self.secondaryColumnMinimumWidth <= viewWidth + FLT_EPSILON) {
        return 3;
    }

    // Check if there's enough space for 2 columns
    if (totalDualWidth < viewWidth) {
        return 2;
    }

    // Default to 1 column
    return 1;
}

#pragma mark - Accessors -
- (void)setDelegate:(id<TOSplitViewControllerDelegate>)delegate
{
    if (delegate == _delegate) { return; }
    _delegate = delegate;

    _delegateFlags.collapseSecondaryToPrimary = [_delegate respondsToSelector:@selector(primaryViewControllerForCollapsingSplitViewController:
                                                                                        fromSecondaryViewController:)];
    _delegateFlags.collapseDetailToPrimary = [_delegate respondsToSelector:@selector(primaryViewControllerForCollapsingSplitViewController:
                                                                                     fromDetailViewController:)];
}

@end
