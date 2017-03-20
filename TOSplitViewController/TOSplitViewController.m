//
//  TOSplitViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 3/14/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "TOSplitViewController.h"

@interface TOSplitViewController ()

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

    CGSize size = self.view.bounds.size;
    BOOL compact = (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    [self updateViewControllersForBoundsSize:size compactSizeClass:compact];
    [self layoutViewControllersForBoundsSize:size];
}

- (void)viewDidLayoutSubviews
{
    [self layoutViewControllersForBoundsSize:self.view.bounds.size];
}

#pragma mark - Column Setup & Management -

- (void)addSplitViewControllerChildViewController:(UIViewController *)controller
{
    [controller willMoveToParentViewController:self];
    [self addChildViewController:controller];
    [self.view addSubview:controller.view];
    [controller didMoveToParentViewController:self];
}

- (UIViewController *)removeSplitViewContorllerChildViewController:(UIViewController *)controller
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

- (void)updateViewControllersForBoundsSize:(CGSize)size compactSizeClass:(BOOL)compact
{
    NSInteger numberOfColumns    = self.viewControllers.count;
    NSInteger newNumberOfColumns = [self possibleNumberOfColumnsForWidth:size.width];

    if (numberOfColumns == newNumberOfColumns) { return; }

    // Collapse from three columns to two
    if (numberOfColumns == 3 && newNumberOfColumns < 3 && [self collapseSecondaryControllerIntoPrimaryController]) {
        numberOfColumns--;
    }

    // Collapse from two to one
    if (numberOfColumns == 2 && newNumberOfColumns < 2) {
        numberOfColumns--;
    }
}

- (BOOL)collapseSecondaryControllerIntoPrimaryController
{
    if (self.viewControllers.count <= 2) { return NO; }

    UIViewController *primaryViewController = self.viewControllers[0];
    UIViewController *secondaryViewController = self.viewControllers[1];

    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.viewControllers];

    // Let the delegate configure the new primary controller
    if ([self.delegate respondsToSelector:@selector(primaryViewControllerForCollapsingSplitViewController:fromSecondaryViewController:)]) {
        UIViewController *newPrimaryController = [self.delegate primaryViewControllerForCollapsingSplitViewController:self fromSecondaryViewController:secondaryViewController];
        if (newPrimaryController != primaryViewController) {
            [controllers removeObject:primaryViewController];
            [self removeSplitViewContorllerChildViewController:primaryViewController];
            [self addSplitViewControllerChildViewController:newPrimaryController];
            [controllers insertObject:newPrimaryController atIndex:0];
        }
    }
    else {
        // Default bahaviour is to assume primary is navigation controller and push to it
        if ([primaryViewController isKindOfClass:[UINavigationController class]]) {

            UINavigationController *primaryNavigationController = (UINavigationController *)primaryViewController;

            //Copy all view controllers to the primary navigation controller
            if ([secondaryViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *secondaryNavigationController = (UINavigationController *)secondaryViewController;

                NSArray *secondaryViewControllers = secondaryNavigationController.viewControllers;
                NSArray *primaryViewControllers = primaryNavigationController.viewControllers;
                secondaryNavigationController.viewControllers = [NSArray array];

                primaryNavigationController.viewControllers = [primaryViewControllers arrayByAddingObjectsFromArray:secondaryViewControllers];
            }
            else {
                [primaryNavigationController pushViewController:secondaryViewController animated:NO];
            }
        }
    }

    [self removeSplitViewContorllerChildViewController:secondaryViewController];
    [controllers removeObject:secondaryViewController];

    self.viewControllers = [NSArray arrayWithArray:controllers];

    return YES;
}

- (BOOL)collapseTertiaryControllerIntoPrimaryController
{
    if (self.viewControllers.count <= 1) { return NO; }

    UIViewController *primaryViewController = self.viewControllers[0];
    UIViewController *tertiaryViewController = self.viewControllers[1];

    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.viewControllers];

    // Let the delegate configure the new primary controller
    if ([self.delegate respondsToSelector:@selector(primaryViewControllerForCollapsingSplitViewController:fromTertiaryViewController:)]) {
        UIViewController *newPrimaryController = [self.delegate primaryViewControllerForCollapsingSplitViewController:self fromTertiaryViewController:tertiaryViewController];
        if (newPrimaryController != primaryViewController) {
            [controllers removeObject:primaryViewController];
            [self removeSplitViewContorllerChildViewController:primaryViewController];
            [self addSplitViewControllerChildViewController:newPrimaryController];
            [controllers insertObject:newPrimaryController atIndex:0];
        }
    }
    else {
        // Default bahaviour is to assume primary is navigation controller and push to it
        if ([primaryViewController isKindOfClass:[UINavigationController class]]) {

            UINavigationController *primaryNavigationController = (UINavigationController *)primaryViewController;

            //Copy all view controllers to the primary navigation controller
            if ([tertiaryViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *tertiaryNavigationController = (UINavigationController *)tertiaryViewController;

                NSArray *tertiaryViewControllers = tertiaryNavigationController.viewControllers;
                NSArray *primaryViewControllers = primaryNavigationController.viewControllers;
                tertiaryNavigationController.viewControllers = [NSArray array];

                primaryNavigationController.viewControllers = [primaryViewControllers arrayByAddingObjectsFromArray:tertiaryViewControllers];
            }
            else {
                [primaryNavigationController pushViewController:tertiaryViewController animated:NO];
            }
        }
    }

    [self removeSplitViewContorllerChildViewController:tertiaryViewController];
    [controllers removeObject:tertiaryViewController];

    self.viewControllers = [NSArray arrayWithArray:controllers];
    
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


@end
