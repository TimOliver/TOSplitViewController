//
//  TOSplitViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 3/14/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "TOSplitViewController.h"
#import "UINavigationController+TOSplitViewController.h"

@interface TOSplitViewController () {
    struct {
        BOOL showSecondaryViewController;
        BOOL showDetailViewController;
        BOOL collapseAuxiliaryToPrimary;
        BOOL separateFromPrimary;
        BOOL primaryForCollapsing;
        BOOL expandPrimaryToSecondary;
    } _delegateFlags;
}

// Child view controllers managed by the split view controller
@property (nonatomic, strong) NSMutableArray *visibleViewControllers;

// The separator lines between view controllers
@property (nonatomic, strong) NSArray<UIView *> *separatorViews;

// Manually track the horizontal size class that we will use to determine layouts
@property (nonatomic, assign) UIUserInterfaceSizeClass horizontalSizeClass;

@end

@implementation TOSplitViewController

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
{
    if (self = [super init]) {
        _viewControllers = viewControllers;
        [self setUp];
    }

    return self;
}

- (void)setUp
{
    // Primary Column
    _primaryColumnMinimumWidth = 264.0f;
    _primaryColumnMaximumWidth = 400.0f;
    _preferredPrimaryColumnWidthFraction = 0.38f;

    // Secondary Column
    _secondaryColumnMinimumWidth = 290.0f;
    _secondaryColumnMaximumWidth = 400.0f;

    // Detail Column
    _detailColumnMinimumWidth = 430.0f;

    // State data
    _maximumNumberOfColumns = 3;

    _separatorStrokeColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
}

#pragma mark - View Lifecylce -

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    self.horizontalSizeClass = self.view.traitCollection.horizontalSizeClass;
    self.visibleViewControllers = [NSMutableArray arrayWithArray:self.viewControllers];

    //Add all of the view controllers
    for (UIViewController *controller in self.visibleViewControllers) {
        [self addSplitViewControllerChildViewController:controller];
    }

    // Create separators
    NSMutableArray *separators = [NSMutableArray array];
    for (NSInteger i = 0; i < 2; i++) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = self.separatorStrokeColor;
        [separators addObject:view];
    }
    self.separatorViews = [NSArray arrayWithArray:separators];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self layoutSplitViewControllerContentForSize:self.view.bounds.size];
}

- (void)layoutSplitViewControllerContentForSize:(CGSize)size
{
    BOOL compact = (self.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    [self updateViewControllersForBoundsSize:size compactSizeClass:compact];
    [self layoutViewControllersForBoundsSize:size];
    [self resetSeparatorViewsForViewControllers];
    [self layoutSeparatorViewsForViewControllersWithHeight:size.height];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    self.horizontalSizeClass = newCollection.horizontalSizeClass;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    self.horizontalSizeClass = self.view.traitCollection.horizontalSizeClass;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // When the view isn't animated (eg, split screen resizes), just force a complete manual layout
    if (coordinator.isAnimated == NO) {
        [self layoutSplitViewControllerContentForSize:size];
        return;
    }

    // Get the number of columns this new size can theoretically fit
    NSInteger newNumberOfColumns = [self possibleNumberOfColumnsForWidth:size.width];

    // If the column numbers don't match, do an expand/collapse animation.
    // But since there's a possibility the delegate indicates there aren't enough view controllers
    // to do this, account for the fact these operations 'may' fail, and default to the screen resize in that case
    if (newNumberOfColumns != self.visibleViewControllers.count) {
        BOOL success = NO;
        @autoreleasepool {
            if (newNumberOfColumns < self.visibleViewControllers.count) {
                success = [self transitionToCollapsedViewControllerCount:newNumberOfColumns withSize:size withTransitionCoordinator:coordinator];
            }
            else {
                success = [self transitionToExpandedViewControllerCount:newNumberOfColumns withSize:size withTransitionCoordinator:coordinator];
            }
        }

        if (success) { return; }
    }

    // If it's not possible to do an expand/collapse animation, just animate the current controllers resizing
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self layoutViewControllersForBoundsSize:size];
        [self layoutSeparatorViewsForViewControllersWithHeight:size.height];
    } completion:nil];
}

- (BOOL)transitionToCollapsedViewControllerCount:(NSInteger)newCount withSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    NSInteger numberOfColumns = self.visibleViewControllers.count;
    BOOL collapsingSecondary = (newCount == 2); //Collapsing 3 to 2
    BOOL collapsingDetail = (newCount == 1);    //Collapsing 2 to 1

    // Snapshots of the various columns in their 'before' state
    UIView *detailSnapshot = nil;
    UIView *secondarySnapshot = nil;
    UIView *primarySnapshot = nil;

    // The 'before' state of each view controller
    CGRect detailFrame = self.detailViewController.view.frame;
    CGRect secondaryFrame = self.secondaryViewController.view.frame;

    // Generate a snapshot view of the primary view controller
    UIViewController *primaryViewController = self.primaryViewController;
    primarySnapshot = [primaryViewController.view snapshotViewAfterScreenUpdates:NO];

    //FIXME - Make this a better check
    if (primarySnapshot == nil) { return NO; }

    // If we're going to collapse the secondary into the primary, generate a snapshot for it
    if (collapsingSecondary) {
        UIViewController *secondaryViewController = self.secondaryViewController;
        secondarySnapshot = [secondaryViewController.view snapshotViewAfterScreenUpdates:NO];
        secondarySnapshot.frame = secondaryViewController.view.frame;
    }
    else if (collapsingDetail) { // Generate a snapshot of the detail controller if we're collapshing to 1
        UIViewController *detailViewController = self.detailViewController;
        detailSnapshot = [detailViewController.view snapshotViewAfterScreenUpdates:NO];
        detailSnapshot.frame = detailViewController.view.frame;
    }

    [self resetSeparatorViewsForViewControllers];

    // Perform the collapse of all of the controllers. This will remove a view controller, but
    // not perform the layout yet
    BOOL compact = (self.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    [self updateViewControllersForBoundsSize:size compactSizeClass:compact];
    if (self.visibleViewControllers.count == numberOfColumns) {
        return NO;
    }

    [self layoutViewControllersForBoundsSize:size];

    // Save the newly calculated frames so we can apply them in an animation
    CGRect newPrimaryFrame = self.primaryViewController.view.frame;
    CGRect newDetailFrame = self.detailViewController.view.frame;

    // Insert the primary view
    [self.view insertSubview:primarySnapshot atIndex:0];

    NSArray *viewsForSeparators = nil;

    // Restore the controllers back to their previous state so we can animate them
    if (collapsingSecondary) {
        self.primaryViewController.view.frame = secondaryFrame;
        self.detailViewController.view.frame = detailFrame;
        [self.view insertSubview:secondarySnapshot aboveSubview:self.primaryViewController.view];

        viewsForSeparators = @[primarySnapshot, self.primaryViewController.view, self.detailViewController.view];
    }
    else if (collapsingDetail) {
        self.primaryViewController.view.frame = detailFrame;
        [self.view insertSubview:detailSnapshot aboveSubview:self.primaryViewController.view];
        [self.view insertSubview:primarySnapshot aboveSubview:detailSnapshot];

        viewsForSeparators = @[primarySnapshot, self.primaryViewController.view];
    }
    [self layoutSeparatorViewsForViews:viewsForSeparators height:self.view.bounds.size.height];

    // Capture the current screen orientation
    UIInterfaceOrientation beforeOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    id transitionBlock = ^(id<UIViewControllerTransitionCoordinatorContext> context) {

        // To ensure the primary key stays on screen longer, slide it downwards when the rotation
        // animation is happening clockwise.
        UIInterfaceOrientation afterOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        BOOL clockwiseRotation = (beforeOrientation == UIInterfaceOrientationLandscapeLeft && afterOrientation == UIInterfaceOrientationPortrait) ||
                                    (beforeOrientation == UIInterfaceOrientationLandscapeRight && afterOrientation == UIInterfaceOrientationPortraitUpsideDown);

        // Slide the primary view out to the side
        CGRect frame = primarySnapshot.frame;
        frame.origin.x = -(frame.size.width);
        frame.origin.y = clockwiseRotation ? size.height - frame.size.height : 0.0f;
        primarySnapshot.frame = frame;

        // Capture the two and from states needed for the new primary controller
        UIViewController *primaryViewController = self.primaryViewController;
        UIViewController *detailViewController = self.detailViewController;

        // Cross fade the secondary snapshot over the new primary
        // animate the snapshot
        secondarySnapshot.frame = newPrimaryFrame;
        secondarySnapshot.alpha = 0.0f;

        detailSnapshot.alpha = 0.0f;

        // This is a huge hack, but for some reason, an implicit animation is being
        // added to the primary view controller that overrides what we're doing here.
        // To undo it, we kill every animation already applied to the view controller,
        // and reapply from scratch
        [primaryViewController.view.layer removeAllAnimations];
        [detailViewController.view.layer removeAllAnimations];

        if (collapsingSecondary) {
            primaryViewController.view.frame = secondaryFrame;
            detailViewController.view.frame = detailFrame;
            detailSnapshot.frame = newDetailFrame;
        }
        else if (collapsingDetail) {
            primaryViewController.view.frame = detailFrame;
            detailSnapshot.frame = newPrimaryFrame;
        }

        [UIView animateWithDuration:context.transitionDuration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             primaryViewController.view.frame = newPrimaryFrame;
                             detailViewController.view.frame = newDetailFrame;
                         }
                         completion:nil];
//        else if (collapsingDetail) {
//            CGRect toFrame = (CGRect){CGPointZero, size};
//            primaryViewController.view.frame = toFrame;
//
//            // Animate the detail view crossfading to the new one
//            detailSnapshot.frame = toFrame;
//            detailSnapshot.alpha = 0.0f;
//        }

        [self layoutSeparatorViewsForViews:viewsForSeparators height:size.height];
    };

    id completionBlock = ^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [detailSnapshot removeFromSuperview];
        [secondarySnapshot removeFromSuperview];
        [primarySnapshot removeFromSuperview];

        [self resetSeparatorViewsForViewControllers];
    };

    [coordinator animateAlongsideTransition:transitionBlock completion:completionBlock];

    return YES;
}

- (BOOL)transitionToExpandedViewControllerCount:(NSInteger)newCount withSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    NSInteger numberOfColumns = self.visibleViewControllers.count;

    BOOL expandingSecondary = (newCount == 3); //Expanding 2 to 3
    BOOL expandingPrimary = (newCount == 2);   //Expanding 1 to 2

    // The 'before' snapshots we can capture before the rotation
    UIView *primarySnapshot = nil;
    UIView *detailSnapshot = nil;

    // The currently visible view controllers (detail is nil if single column)
    UIViewController *primaryController = self.primaryViewController;
    UIViewController *detailController = self.detailViewController;

    // The current frames for the 1 or 2 controllers
    CGRect primaryFrame = primaryController.view.frame;
    CGRect detailFrame = detailController.view.frame;

    // If expanding to 3 column, take a snapshot of the current primary to crossfade out of
    if (expandingSecondary) {
        primarySnapshot = [primaryController.view snapshotViewAfterScreenUpdates:NO];
    }
    else if (expandingPrimary) { //If expanding the single controller, take a screenshot of the full screen
        detailSnapshot = [primaryController.view snapshotViewAfterScreenUpdates:NO];
    }

    [self resetSeparatorViewsForViewControllers];

    // Update the number of view controllers in the stack
    BOOL compact = (self.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    [self updateViewControllersForBoundsSize:size compactSizeClass:compact];
    if (numberOfColumns == self.visibleViewControllers.count) {
        return NO;
    }

    // Reposition them to their new frames
    [self layoutViewControllersForBoundsSize:size];

    // Capture the new view controllers
    UIViewController *newPrimary = self.primaryViewController;
    UIViewController *newSecondary = self.secondaryViewController;
    UIViewController *newDetail = self.detailViewController;

    // Capture the destination frames of each controller
    CGRect newPrimaryFrame = newPrimary.view.frame;
    CGRect newSecondaryFrame = newSecondary.view.frame;
    CGRect newDetailFrame = newDetail.view.frame;

    // Create a version of the primary frame that's offscreen
    CGRect primaryOffFrame = newPrimaryFrame;
    primaryOffFrame.origin.x = -(primaryOffFrame.size.width);
    primaryOffFrame.size.height = primaryFrame.size.height;
    newPrimary.view.frame = primaryOffFrame;

    NSArray *viewsForSeparators = nil;

    // Set them back to where they should be, pre-animation
    if (expandingSecondary) {
        [self.view insertSubview:primarySnapshot aboveSubview:newSecondary.view];
        newDetail.view.frame = detailFrame;
        newSecondary.view.frame = primaryFrame;
        viewsForSeparators = @[newPrimary.view, newSecondary.view, newDetail.view];
    }
    else if (expandingPrimary) {
        newDetail.view.frame = primaryFrame;
        detailSnapshot.frame = primaryFrame;
        [self.view insertSubview:detailSnapshot aboveSubview:newDetail.view];
        viewsForSeparators = @[newPrimary.view, newDetail.view];
    }
    [self layoutSeparatorViewsForViews:viewsForSeparators height:self.view.bounds.size.height];

    id transitionBlock = ^(id<UIViewControllerTransitionCoordinatorContext> context) {

        primarySnapshot.frame = newSecondaryFrame;
        primarySnapshot.alpha = 0.0f;

        detailSnapshot.frame = newDetailFrame;
        detailSnapshot.alpha = 0.0f;

        [newPrimary.view.layer removeAllAnimations];
        [newSecondary.view.layer removeAllAnimations];
        [newDetail.view.layer removeAllAnimations];

        newPrimary.view.frame = primaryOffFrame;
        newSecondary.view.frame = primaryFrame;
        [UIView animateWithDuration:context.transitionDuration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             newPrimary.view.frame = newPrimaryFrame;
                             newSecondary.view.frame = newSecondaryFrame;
                             newDetail.view.frame = newDetailFrame;
                             [self layoutSeparatorViewsForViews:viewsForSeparators height:size.height];
                         }
                         completion:^(BOOL completion) {
                             [self.view sendSubviewToBack:newPrimary.view];
                         }];

        newDetail.view.frame = newDetailFrame;
    };

    id completionBlock = ^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [primarySnapshot removeFromSuperview];
        [detailSnapshot removeFromSuperview];
        [self resetSeparatorViewsForViewControllers];
        [detailSnapshot removeFromSuperview];
    };
    [coordinator animateAlongsideTransition:transitionBlock completion:completionBlock];

    return YES;
}

#pragma mark - Column Setup & Management -

- (void)addSplitViewControllerChildViewController:(UIViewController *)controller
{
    [controller willMoveToParentViewController:self];
    [self addChildViewController:controller];
    [self.view insertSubview:controller.view atIndex:0];
    controller.view.clipsToBounds = YES; // Make sure no content will bleed out
    controller.view.autoresizingMask = UIViewAutoresizingNone; // Disable auto resize mask because it otherwise breaks some animationsO
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

- (void)layoutViewControllersForBoundsSize:(CGSize)size
{
    NSInteger numberOfColumns = self.visibleViewControllers.count;
    if (numberOfColumns == 0) {
        return;
    }

    CGRect frame = CGRectZero;

    // The columns to layout
    UIViewController *primaryController = self.primaryViewController;
    UIViewController *secondaryController = self.secondaryViewController;
    UIViewController *detailController = self.detailViewController;

    // Laying out three columns
    if (numberOfColumns == 3) {
        CGFloat idealPrimaryWidth = self.primaryColumnMinimumWidth;
        CGFloat idealSecondaryWidth = self.secondaryColumnMinimumWidth;
        CGFloat idealDetailWidth = self.detailColumnMinimumWidth;

        CGFloat padding = 0.0f;
        CGFloat delta = size.width - (idealPrimaryWidth + idealSecondaryWidth + idealDetailWidth);
        if (delta > FLT_EPSILON) {
            padding = floorf(delta / 3.0f);
        }

        // Update the frames for each controller
        frame.size = size;
        frame.size.width = idealPrimaryWidth + padding;
        primaryController.view.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame);
        frame.size.width = idealSecondaryWidth + padding;
        secondaryController.view.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame);
        frame.size.width = size.width - frame.origin.x;
        detailController.view.frame = frame;

        // Set the size classes for each controller
        UITraitCollection *horizontalSizeClassCompact = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];

        UITraitCollection *primaryTraitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:@[primaryController.traitCollection, horizontalSizeClassCompact]];
        [self setOverrideTraitCollection:primaryTraitCollection forChildViewController:primaryController];

        UITraitCollection *secondaryTraitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:@[secondaryController.traitCollection, horizontalSizeClassCompact]];
        [self setOverrideTraitCollection:secondaryTraitCollection forChildViewController:secondaryController];

        // Update the layout
        [primaryController.view layoutIfNeeded];
        [secondaryController.view layoutIfNeeded];
        [detailController.view layoutIfNeeded];
    }
    else if (numberOfColumns == 2) { // Laying out two columns
        CGFloat idealPrimaryWidth = (size.width * self.preferredPrimaryColumnWidthFraction);
        idealPrimaryWidth = MAX(self.primaryColumnMinimumWidth, idealPrimaryWidth);
        idealPrimaryWidth = MIN(self.primaryColumnMaximumWidth, idealPrimaryWidth);

        frame.size = size;
        frame.size.width = floorf(idealPrimaryWidth);
        primaryController.view.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame);
        frame.size.width = size.width - frame.origin.x;
        detailController.view.frame = frame;

        UITraitCollection *horizontalSizeClassCompact = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];

        UITraitCollection *primaryTraitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:@[primaryController.traitCollection, horizontalSizeClassCompact]];
        [self setOverrideTraitCollection:primaryTraitCollection forChildViewController:primaryController];

        [primaryController.view layoutIfNeeded];
        [detailController.view layoutIfNeeded];
    }
    else {
        frame.size = size;
        primaryController.view.frame = frame;

        [primaryController.view layoutIfNeeded];
    }

    // Make sure the views from right-to-left stack on each other
    [self.view sendSubviewToBack:detailController.view];
    [self.view sendSubviewToBack:secondaryController.view];
    [self.view sendSubviewToBack:primaryController.view];
}

- (void)layoutSeparatorViewsForViewControllersWithHeight:(CGFloat)height
{
    NSMutableArray *views = [NSMutableArray array];
    for (UIViewController *controller in self.visibleViewControllers) {
        [views addObject:controller.view];
    }

    [self layoutSeparatorViewsForViews:views height:height];
}

- (void)layoutSeparatorViewsForViews:(NSArray<UIView *> *)views height:(CGFloat)height
{
    NSInteger i = 0;
    CGFloat width = 1.0f / [[UIScreen mainScreen] scale];
    for (UIView *view in views) {
        if (i >= views.count - 1 || i >= self.separatorViews.count) {
            break;
        }

        CGRect frame = CGRectMake(0.0f, 0.0f, width, height);
        UIView *separator = self.separatorViews[i++];
        frame.origin.x = CGRectGetMaxX(view.frame) - width;
        separator.frame = frame;

        if (separator.superview == nil) {
            [self.view addSubview:separator];
        }
    }
}

- (void)resetSeparatorViewsForViewControllers
{
    for (UIView *separatorView in self.separatorViews) {
        [separatorView removeFromSuperview];
    }

    [self layoutSeparatorViewsForViewControllersWithHeight:self.view.bounds.size.height];
}

- (void)updateViewControllersForBoundsSize:(CGSize)size compactSizeClass:(BOOL)compact
{
    NSInteger numberOfColumns    = self.visibleViewControllers.count;
    NSInteger newNumberOfColumns = [self possibleNumberOfColumnsForWidth:size.width];

    if (numberOfColumns == newNumberOfColumns) { return; }

    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.visibleViewControllers];

    // Collapse columns down to the necessary number
    while (numberOfColumns > newNumberOfColumns && controllers.count > 1) {
        UIViewController *primaryViewController = self.primaryViewController;
        UIViewController *auxiliaryViewController = controllers[1]; // Either the secondary or detail controller

        // We're collapsing the secondary controller into the primary
        UIViewController *newPrimaryController = nil;
//        if (numberOfColumns == 3) {
//            if (_delegateFlags.collapseSecondaryToPrimary) {
//                newPrimaryController = [self.delegate primaryViewControllerForCollapsingSplitViewController:self
//                                                                                fromSecondaryViewController:auxiliaryViewController];
//            }
//        }
//        else if (numberOfColumns == 2) { // We're collapsing the detail controller into the primary
//            if (_delegateFlags.collapseDetailToPrimary) {
//                newPrimaryController = [self.delegate primaryViewControllerForCollapsingSplitViewController:self
//                                                                                fromDetailViewController:auxiliaryViewController];
//            }
//        }

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
        _visibleViewControllers = controllers;

        numberOfColumns--;
    }

    // Expand columns to the necessary number
    while (numberOfColumns < newNumberOfColumns && controllers.count < 3) {
        UIViewController *sourceViewController = controllers.firstObject;
        UIViewController *expandedViewController = nil;

        // If we're expanding the primary out into a detail
        if (numberOfColumns == 1) {
            if (self.viewControllers.count > 1) {
                expandedViewController = self.viewControllers.lastObject;
            }

            //if (_delegateFlags.expandPrimaryToDetail) {
            //    expandedViewController = [_delegate splitViewController:self expandDetailViewControllerFromPrimaryViewController:sourceViewController];
            //}
        }
        else if (numberOfColumns == 2) {
            if (self.viewControllers.count > 2) {
                expandedViewController = self.viewControllers[1];
            }

            //if (_delegateFlags.expandPrimaryToSecondary) {
            //    expandedViewController = [_delegate splitViewController:self expandSecondaryViewControllerFromPrimaryViewController:sourceViewController];
            //}
        }

        // If the delegates failed, try to manually expand the controller if it's a navigation controller
        //expandedViewController = [self expandedViewControllerFromSourceViewController:sourceViewController toDestinationController:expandedViewController];
        [(UINavigationController *)expandedViewController toSplitViewController_restoreViewControllers];

        if (expandedViewController) {
            [controllers insertObject:expandedViewController atIndex:1];
            [self addSplitViewControllerChildViewController:expandedViewController];
        }

        numberOfColumns++;
        _visibleViewControllers = controllers;
    }
}

- (BOOL)replacePrimaryControllerWithController:(UIViewController *)viewController
{
    UIViewController *primaryViewController = self.primaryViewController;

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
        [(UINavigationController *)sourceViewController toSplitViewController_moveViewControllersToNavigationController:destNavigationController];
    }
    else {
        [destNavigationController pushViewController:sourceViewController animated:NO];
    }

    return YES;
}

- (UIViewController *)expandedViewControllerFromSourceViewController:(UIViewController *)sourceViewController toDestinationController:(UIViewController *)destinationController
{
    // If a navigation controller, extract the last view controller from it and return it in a new navigation controller
    if ([sourceViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)sourceViewController;
        if (navigationController.viewControllers.count < 2) {
            return nil;
        }

        UIViewController *lastViewController = [(UINavigationController *)sourceViewController popViewControllerAnimated:NO];
        return [[UINavigationController alloc] initWithRootViewController:lastViewController];
    }

    return nil;
}

#pragma mark - Column State Checking -

- (NSInteger)possibleNumberOfColumnsForWidth:(CGFloat)width
{
    // Not a regular side class (eg, iPhone / iPad Split View)
    if (self.horizontalSizeClass != UIUserInterfaceSizeClassRegular) {
        return 1;
    }

    CGFloat totalDualWidth = self.primaryColumnMinimumWidth;
    totalDualWidth += self.detailColumnMinimumWidth;

    //Default to 1 column
    NSInteger numberOfColumns = 1;

    // Check if there's enough horizontal space for all 3 columns
    if (totalDualWidth + self.secondaryColumnMinimumWidth <= width + FLT_EPSILON) {
        numberOfColumns = 3;
    }
    else if (totalDualWidth <= width + FLT_EPSILON) { // Check if there's enough space for 2 columns
        numberOfColumns = 2;
    }

    // Default to 1 column
    return MIN(self.maximumNumberOfColumns, numberOfColumns);
}

#pragma mark - Accessors -
- (void)setDelegate:(id<TOSplitViewControllerDelegate>)delegate
{
    if (delegate == _delegate) { return; }
    _delegate = delegate;

    _delegateFlags.showSecondaryViewController = [_delegate respondsToSelector:@selector(splitViewController:showSecondaryViewController:sender:)];
    _delegateFlags.showDetailViewController = [_delegate respondsToSelector:@selector(splitViewController:showDetailViewController:sender:)];
    _delegateFlags.collapseAuxiliaryToPrimary = [_delegate respondsToSelector:@selector(splitViewController:collapseViewController:ofType:ontoPrimaryViewController:)];
    _delegateFlags.separateFromPrimary = [_delegate respondsToSelector:@selector(splitViewController:separateViewControllerOfType:fromPrimaryViewController:)];
    _delegateFlags.primaryForCollapsing = [_delegate respondsToSelector:@selector(splitViewController:primaryViewControllerForCollapsingFromType:)];
    _delegateFlags.expandPrimaryToSecondary = [_delegate respondsToSelector:@selector(splitViewController:primaryViewControllerForExpandingToType:)];
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers
{
    if ([_viewControllers isEqual:viewControllers]) { return; }
    _viewControllers = [viewControllers copy];
    [self layoutSplitViewControllerContentForSize:self.view.bounds.size];
}

#pragma mark - Internal Accessors -
- (UIViewController *)primaryViewController
{
    return self.visibleViewControllers.firstObject;
}

- (UIViewController *)secondaryViewController
{
    if (self.visibleViewControllers.count <= 2) { return nil; }
    return self.visibleViewControllers[1];
}

- (UIViewController *)detailViewController
{
    if (self.visibleViewControllers.count == 3) {
        return self.visibleViewControllers[2];
    }
    else if (self.visibleViewControllers.count == 2) {
        return self.visibleViewControllers[1];
    }

    return nil;
}

@end

// ----------------------------------------------------------------------

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation UIViewController (TOSplitViewController)

- (TOSplitViewController *)to_splitViewController
{
    UIViewController *parent = self;
    while ((parent = parent.parentViewController) != nil) {
        if ([parent isKindOfClass:[TOSplitViewController class]]) {
            return (TOSplitViewController *)parent;
        }
    }

    return nil;
}

@end

#pragma clang diagnostic pop

