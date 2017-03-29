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
        BOOL showSecondController;
        BOOL collapseSecondaryToPrimary;
        BOOL collapseDetailToPrimary;
        BOOL expandPrimaryToDetail;
        BOOL expandPrimaryToSecondary;
    } _delegateFlags;
}

// The separator lines between view controllers
@property (nonatomic, strong) NSArray<UIView *> *separatorViews;

// The three view controllers, returning nil if not presently visible
@property (nonatomic, readonly) UIViewController *primaryViewController;
@property (nonatomic, readonly) UIViewController *secondaryViewController;
@property (nonatomic, readonly) UIViewController *detailViewController;

// Manually track the horizontal size class that we will use to determine layouts
@property (nonatomic, assign) UIUserInterfaceSizeClass horizontalSizeClass;

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
    _primaryColumnMinimumWidth = 274.0f;
    _primaryColumnMaximumWidth = 400.0f;
    _preferredPrimaryColumnWidthFraction = 0.38f;

    // Secondary Column
    _secondaryColumnMinimumWidth = 290.0f;
    _secondaryColumnMaximumWidth = 400.0f;

    // Detail Column
    _detailColumnMinimumWidth = 440.0f;

    // State data
    _maximumNumberOfColumns = 3;

    _separatorStrokeColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
}

#pragma mark - View Lifecylce -

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    self.horizontalSizeClass = self.view.traitCollection.horizontalSizeClass;

    //Add all of the view controllers
    for (UIViewController *controller in self.viewControllers) {
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

    CGSize size = self.view.bounds.size;
    BOOL compact = (self.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    [self updateViewControllersForBoundsSize:size compactSizeClass:compact];
    [self layoutViewControllersForBoundsSize:size];
    [self layoutSeparatorViewsForViewControllers];
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

    NSInteger newNumberOfColumns = [self possibleNumberOfColumnsForWidth:size.width];

    // If we can't simply resize the columns, perform a 'collapse' or 'expand' animation
    if (newNumberOfColumns != self.viewControllers.count) {
        if (newNumberOfColumns < self.viewControllers.count) {
            [self transitionToCollapsedViewControllerCount:newNumberOfColumns withSize:size withTransitionCoordinator:coordinator];
        }
        else {
            [self transitionToExpandedViewControllerCount:newNumberOfColumns withSize:size withTransitionCoordinator:coordinator];
        }

        return;
    }

    // Animate the view controllers resizing
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self layoutViewControllersForBoundsSize:size];
    } completion:nil];
}

- (void)transitionToCollapsedViewControllerCount:(NSInteger)newCount withSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
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
    [self.view addSubview:primarySnapshot];

    // If we're going to collapse the secondary into the primary, generate a snapshot for it
    if (collapsingSecondary) {
        UIViewController *secondaryViewController = self.secondaryViewController;
        secondarySnapshot = [secondaryViewController.view snapshotViewAfterScreenUpdates:NO];
        secondarySnapshot.frame = secondaryViewController.view.frame;
        [self.view addSubview:secondarySnapshot];
    }
    else if (collapsingDetail) { // Generate a snapshot of the detail controller if we're collapshing to 1
        UIViewController *detailViewController = self.detailViewController;
        detailSnapshot = [detailViewController.view snapshotViewAfterScreenUpdates:NO];
        detailSnapshot.frame = detailViewController.view.frame;
        [self.view addSubview:detailSnapshot];
    }

    // Perform the collapse of all of the controllers. This will remove a view controller, but
    // not perform the layout yet
    BOOL compact = (self.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    [self updateViewControllersForBoundsSize:size compactSizeClass:compact];
    [self layoutViewControllersForBoundsSize:size];

    // Save the newly calculated frames so we can apply them in an animation
    CGRect newPrimaryFrame = self.primaryViewController.view.frame;
    CGRect newDetailFrame = self.detailViewController.view.frame;

    // Restore the controllers back to their previous state so we can animate them
    if (collapsingSecondary) {
        self.primaryViewController.view.frame = secondaryFrame;
        self.detailViewController.view.frame = detailFrame;
    }
    else if (collapsingDetail) {
        self.primaryViewController.view.frame = detailFrame;
    }

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

        // Capture the views in which the separators should track
        NSArray *views = nil;

        // Cross fade the secondary snapshot over the new primary
        if (collapsingSecondary) {
            // animate the snapshot
            secondarySnapshot.frame = newPrimaryFrame;
            secondarySnapshot.alpha = 0.0f;

            // animate the detail view controller
            detailViewController.view.frame = newDetailFrame;

            // This is a huge hack, but for some reason, an implicit animation is being
            // added to the primary view controller that overrides what we're doing here.
            // To undo it, we kill every animation already applied to the view controller,
            // and reapply from scratch
            [primaryViewController.view.layer removeAllAnimations];

            primaryViewController.view.frame = secondaryFrame;
            [UIView animateWithDuration:context.transitionDuration
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{ primaryViewController.view.frame = newPrimaryFrame; }
                             completion:nil];

            views = @[primarySnapshot, secondarySnapshot, detailViewController.view];
        }
        else if (collapsingDetail) {
            CGRect toFrame = (CGRect){CGPointZero, size};
            primaryViewController.view.frame = toFrame;

            // Animate the detail view crossfading to the new one
            detailSnapshot.frame = toFrame;
            detailSnapshot.alpha = 0.0f;

            views = @[primarySnapshot, primaryViewController.view];
        }

        [self layoutSeparatorViewsForViews:views];
    };

    id completionBlock = ^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [detailSnapshot removeFromSuperview];
        [secondarySnapshot removeFromSuperview];
        [primarySnapshot removeFromSuperview];

        [self removeSeparatorViewsForViewControllers];
    };

    [coordinator animateAlongsideTransition:transitionBlock completion:completionBlock];
}

- (void)transitionToExpandedViewControllerCount:(NSInteger)newCount withSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    BOOL expandingSecondary = (newCount == 3); //Expanding 2 to 3
    BOOL expandingPrimary = (newCount == 2);   //Expanding 1 to 2

    UIView *primarySnapshot = nil;
    UIView *detailSnapshot = nil; // Only needed if size class is changing

    UIViewController *primaryController = self.primaryViewController;
    UIViewController *detailController = self.detailViewController;

    CGRect primaryFrame = primaryController.view.frame;
    CGRect detailFrame = detailController.view.frame;

    UIView *snapshotView = [primaryController.view snapshotViewAfterScreenUpdates:NO];
    if (expandingPrimary) {
        detailSnapshot = snapshotView;
    }
    else if (expandingSecondary) {
        primarySnapshot = snapshotView;
    }
    [self.view addSubview:snapshotView];

    BOOL compact = (self.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    [self updateViewControllersForBoundsSize:size compactSizeClass:compact];
    [self layoutViewControllersForBoundsSize:size];

    UIViewController *newPrimary = self.primaryViewController;
    UIViewController *newSecondary = self.secondaryViewController;
    UIViewController *newDetail = self.detailViewController;

    // Capture the final frames of each controller
    CGRect newPrimaryFrame = newPrimary.view.frame;
    CGRect newSecondaryFrame = newSecondary.view.frame;
    CGRect newDetailFrame = newDetail.view.frame;

    // Set them back to where they should be, pre-animation
    if (expandingSecondary) {
        [self.view bringSubviewToFront:primarySnapshot];
        newDetail.view.frame = detailFrame;
    }
    else if (expandingPrimary) {
        newDetail.view.frame = primaryFrame;
        [self.view bringSubviewToFront:detailSnapshot];
    }

    id transitionBlock = ^(id<UIViewControllerTransitionCoordinatorContext> context) {
        newPrimary.view.frame = newPrimaryFrame;
        newDetail.view.frame = newDetailFrame;

        detailSnapshot.alpha = 0.0f;
        primarySnapshot.alpha = 0.0f;

        if (expandingSecondary) {
            primarySnapshot.frame = newSecondaryFrame;
        }

        // Perform the silly Core Animation hack on both the primary
        // and secondary controllers
        [newPrimary.view.layer removeAllAnimations];
        [newSecondary.view.layer removeAllAnimations];

        newSecondary.view.frame = primaryFrame;

        // Set the real primary off to the side so it can slide into view
        CGRect frame = newPrimaryFrame;
        frame.origin.x = -CGRectGetWidth(frame);
        frame.size.height = primaryFrame.size.height;
        newPrimary.view.frame = frame;

        [UIView animateWithDuration:context.transitionDuration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             newPrimary.view.frame = newPrimaryFrame;
                             newSecondary.view.frame = newSecondaryFrame;
                         }
                         completion:nil];

        [self layoutSeparatorViewsForViewControllers];
    };

    id completionBlock = ^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self removeSeparatorViewsForViewControllers];
    };
    [coordinator animateAlongsideTransition:transitionBlock completion:completionBlock];
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

- (void)layoutViewControllersForBoundsSize:(CGSize)size
{
    NSInteger numberOfColumns = self.viewControllers.count;
    if (numberOfColumns == 0) {
        return;
    }

    CGRect frame = CGRectZero;

    // The columns to layout
    UIViewController *primaryController = self.primaryViewController;
    UIViewController *secondaryController = self.secondaryViewController;
    UIViewController *detailController = self.detailViewController;

    if (numberOfColumns == 3) {
        CGFloat idealPrimaryWidth = self.primaryColumnMinimumWidth;
        CGFloat idealSecondaryWidth = self.secondaryColumnMinimumWidth;
        CGFloat idealDetailWidth = self.detailColumnMinimumWidth;

        CGFloat padding = 0.0f;
        CGFloat delta = size.width - (idealPrimaryWidth + idealSecondaryWidth + idealDetailWidth);
        if (delta > FLT_EPSILON) {
            padding = floorf(delta / 3.0f);
        }

        frame.size = size;
        frame.size.width = idealPrimaryWidth + padding;
        primaryController.view.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame);
        frame.size.width = idealSecondaryWidth + padding;
        secondaryController.view.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame);
        frame.size.width = size.width - frame.origin.x;
        detailController.view.frame = frame;
    }
    else if (numberOfColumns == 2) {
        CGFloat idealPrimaryWidth = (size.width * self.preferredPrimaryColumnWidthFraction);
        idealPrimaryWidth = MAX(self.primaryColumnMinimumWidth, idealPrimaryWidth);
        idealPrimaryWidth = MIN(self.primaryColumnMaximumWidth, idealPrimaryWidth);

        frame.size = size;
        frame.size.width = floorf(idealPrimaryWidth);
        primaryController.view.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame);
        frame.size.width = size.width - frame.origin.x;
        detailController.view.frame = frame;
    }
    else {
        frame.size = size;
        primaryController.view.frame = frame;
    }
}

- (void)layoutSeparatorViewsForViewControllers
{
    NSMutableArray *views = [NSMutableArray array];
    for (UIViewController *controller in self.viewControllers) {
        [views addObject:controller.view];
    }

    [self layoutSeparatorViewsForViews:views];
}

- (void)layoutSeparatorViewsForViews:(NSArray<UIView *> *)views
{
    NSInteger i = 0;
    CGFloat width = 1.0f / [[UIScreen mainScreen] scale];
    for (UIView *view in views) {
        if (view.superview) { [self.view bringSubviewToFront:view]; }
        if (i >= views.count - 1 || i >= self.separatorViews.count) {
            break;
        }

        CGFloat height = view.frame.size.height;
        CGRect frame = CGRectMake(0.0f, 0.0f, width, height);
        UIView *separator = self.separatorViews[i++];
        frame.origin.x = CGRectGetMaxX(view.frame) - width;
        separator.frame = frame;

        [self.view addSubview:separator];
    }
}

- (void)removeSeparatorViewsForViewControllers
{
    NSInteger numberOfVisibleSeparators = 0;
    for (UIView *separatorView in self.separatorViews) {
        if (separatorView.superview) { numberOfVisibleSeparators++; }
    }

    // The number of visible separators should always be (viewControllers.count - 1)
    if (numberOfVisibleSeparators < self.viewControllers.count) {
        return;
    }

    NSInteger i = 0;
    while (numberOfVisibleSeparators >= self.viewControllers.count) {
        if (i >= self.separatorViews.count) { break; }
        UIView *separatorView = self.separatorViews[i++];
        [separatorView removeFromSuperview];
        numberOfVisibleSeparators--;
    }
}

- (void)updateViewControllersForBoundsSize:(CGSize)size compactSizeClass:(BOOL)compact
{
    NSInteger numberOfColumns    = self.viewControllers.count;
    NSInteger newNumberOfColumns = [self possibleNumberOfColumnsForWidth:size.width];

    if (numberOfColumns == newNumberOfColumns) { return; }

    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.viewControllers];

    // Collapse columns down to the necessary number
    while (numberOfColumns > newNumberOfColumns && controllers.count > 1) {
        UIViewController *primaryViewController = self.primaryViewController;
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
    while (numberOfColumns < newNumberOfColumns && controllers.count < 3) {
        UIViewController *sourceViewController = controllers.firstObject;
        UIViewController *expandedViewController = nil;

        // If we're expanding the primary out into a detail
        if (numberOfColumns == 1) {
            if (_delegateFlags.expandPrimaryToDetail) {
                expandedViewController = [_delegate splitViewController:self expandDetailViewControllerFromPrimaryViewController:sourceViewController];
            }
        }
        else if (numberOfColumns == 2) {
            if (_delegateFlags.expandPrimaryToSecondary) {
                expandedViewController = [_delegate splitViewController:self expandSecondaryViewControllerFromPrimaryViewController:sourceViewController];
            }

        }

        // If the delegates failed, try to manually expand the controller if it's a navigation controller
        if (expandedViewController == nil) {
            expandedViewController = [self expandedViewControllerFromSourceViewController:sourceViewController];
        }

        if (expandedViewController) {
            [controllers insertObject:expandedViewController atIndex:1];
            [self addSplitViewControllerChildViewController:expandedViewController];
        }

        numberOfColumns++;
        _viewControllers = [NSArray arrayWithArray:controllers];
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

- (UIViewController *)expandedViewControllerFromSourceViewController:(UIViewController *)sourceViewController
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

    _delegateFlags.showSecondController = [_delegate respondsToSelector:@selector(splitViewControllerShouldShowSecondaryColumn:)];
    _delegateFlags.collapseSecondaryToPrimary = [_delegate respondsToSelector:@selector(primaryViewControllerForCollapsingSplitViewController:
                                                                                        fromSecondaryViewController:)];
    _delegateFlags.collapseDetailToPrimary = [_delegate respondsToSelector:@selector(primaryViewControllerForCollapsingSplitViewController:
                                                                                     fromDetailViewController:)];
    _delegateFlags.expandPrimaryToDetail = [_delegate respondsToSelector:@selector(splitViewController:expandDetailViewControllerFromPrimaryViewController:)];
    _delegateFlags.expandPrimaryToSecondary = [_delegate respondsToSelector:@selector(splitViewController:expandSecondaryViewControllerFromPrimaryViewController:)];
}

#pragma mark - Internal Accessors -
- (UIViewController *)primaryViewController
{
    return self.viewControllers.firstObject;
}

- (UIViewController *)secondaryViewController
{
    if (self.viewControllers.count <= 2) { return nil; }
    return self.viewControllers[1];
}

- (UIViewController *)detailViewController
{
    if (self.viewControllers.count == 3) {
        return self.viewControllers[2];
    }
    else if (self.viewControllers.count == 2) {
        return self.viewControllers[1];
    }

    return nil;
}

@end
