//
//  TOSplitViewController.m
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

#import "TOSplitViewController.h"
#import "UINavigationController+TOSplitViewController.h"

NSNotificationName const TOSplitViewControllerShowTargetDidChangeNotification
                            = @"TOSplitViewControllerShowDetailTargetDidChangeNotification";

NSString * const TOSplitViewControllerNotificationSplitViewControllerKey =
                                @"TOSplitViewControllerNotificationSplitViewControllerKey";

@interface TOSplitViewController () {
    struct {
        BOOL showSecondaryViewController;
        BOOL showDetailViewController;
        BOOL collapseAuxiliaryToPrimary;
        BOOL separateFromPrimary;
        BOOL primaryForCollapsing;
        BOOL expandPrimaryToSecondary;
    } _delegateFlags;

    NSMutableArray *_viewControllers;
}

// Child view controllers managed by the split view controller
@property (nonatomic, strong, readwrite) NSMutableArray *visibleViewControllers;

// The separator lines between view controllers
@property (nonatomic, strong) NSArray<UIView *> *separatorViews;

// Manually track the horizontal size class that we will use to determine layouts
@property (nonatomic, assign) UIUserInterfaceSizeClass horizontalSizeClass;

@end

@implementation TOSplitViewController

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
{
    if (self = [super init]) {
        _viewControllers = [viewControllers mutableCopy];
        [self _setUp];
    }

    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self _setUp];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self _setUp];
    }

    return self;
}

- (void)_setUp
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
    self.horizontalSizeClass = self.view.traitCollection.horizontalSizeClass;
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
        newPrimary.view.frame = primaryOffFrame;
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

        [self removeAllAnimationsInLayer:newPrimary.view.layer];
        [self removeAllAnimationsInLayer:newSecondary.view.layer];

        newPrimary.view.frame = primaryOffFrame;
        newSecondary.view.frame = primaryFrame;

        if (expandingPrimary) {
            [self removeAllAnimationsInLayer:newDetail.view.layer];
            [self layoutAllSubViewsInView:newDetail.view];
            newDetail.view.frame = primaryFrame;
        }

        [self layoutAllSubViewsInView:newPrimary.view];
        [self layoutAllSubViewsInView:newSecondary.view];

        [UIView animateWithDuration:context.transitionDuration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             newPrimary.view.frame = newPrimaryFrame;
                             newSecondary.view.frame = newSecondaryFrame;

                             [self layoutAllSubViewsInView:newPrimary.view];
                             [self layoutAllSubViewsInView:newSecondary.view];

                             if (expandingPrimary) {
                                 newDetail.view.frame = newDetailFrame;
                                 [self layoutAllSubViewsInView:newDetail.view];
                             }

                             [self layoutSeparatorViewsForViews:viewsForSeparators height:size.height];
                         }
                         completion:^(BOOL completion) {
                             [self.view sendSubviewToBack:newPrimary.view];
                         }];

        // When expanding from 2-3, the detail controller doesn't need to do any special animations
        if (!expandingPrimary) {
            newDetail.view.frame = newDetailFrame;
        }
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

- (void)removeAllAnimationsInLayer:(CALayer *)layer
{
    [layer removeAllAnimations];

    for (CALayer *sublayer in layer.sublayers) {
        [self removeAllAnimationsInLayer:sublayer];
    }
}

- (void)layoutAllSubViewsInView:(UIView *)view
{
    [view setNeedsLayout];
    [view layoutIfNeeded];

    for (UIView *subview in view.subviews) {
        [self layoutAllSubViewsInView:subview];
    }
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.visibleViewControllers.lastObject;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.visibleViewControllers.lastObject;
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

        // Work out the percentage width of each element
        CGFloat totalWidth = idealPrimaryWidth + idealSecondaryWidth + idealDetailWidth;

        // Update the frames for each controller
        frame.size = size;
        frame.size.width = ceilf((idealPrimaryWidth / totalWidth) * size.width);
        primaryController.view.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame);
        frame.size.width = ceilf((idealSecondaryWidth / totalWidth) * size.width);
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
    BOOL columnCountChanged = NO;
    NSInteger numberOfColumns    = self.visibleViewControllers.count;
    NSInteger newNumberOfColumns = [self possibleNumberOfColumnsForWidth:size.width];
    newNumberOfColumns = MIN(newNumberOfColumns, self.viewControllers.count);

    if (numberOfColumns == newNumberOfColumns) { return; }

    // Collapse columns down to the necessary number
    while (numberOfColumns > newNumberOfColumns && _visibleViewControllers.count > 1) {
        UIViewController *primaryViewController = self.primaryViewController;
        UIViewController *auxiliaryViewController = _visibleViewControllers[1]; // Either the secondary or detail controller

        TOSplitViewControllerType type = (numberOfColumns == 3) ? TOSplitViewControllerTypeSecondary : TOSplitViewControllerTypeDetail;

        // First, test if there is a delegate method to perform any custom collapsing operations
        BOOL result = NO;
        if (_delegateFlags.collapseAuxiliaryToPrimary) {
            result = [self.delegate splitViewController:self
                                 collapseViewController:auxiliaryViewController
                                                 ofType:type
                              ontoPrimaryViewController:primaryViewController
                      shouldAnimate:NO];
        }

        // If there weren't, try and use the view controller's own collapse logic
        if (result == NO && [primaryViewController respondsToSelector:@selector(collapseAuxiliaryViewController:ofType:forSplitViewController:shouldAnimate:)]) {
            [primaryViewController collapseAuxiliaryViewController:auxiliaryViewController ofType:type forSplitViewController:self shouldAnimate:NO];
        }

        // Give the user a chance
        if (_delegateFlags.primaryForCollapsing) {
            UIViewController *newPrimaryController = [self.delegate splitViewController:self primaryViewControllerForCollapsingFromType:type];
            [self replaceChildViewController:primaryViewController withController:newPrimaryController];
        }

        // Finally, remove the collapsed controller from the stack
        [self removeSplitViewControllerChildViewController:auxiliaryViewController];

        // Remove the controller we just merged / replaced
        [_visibleViewControllers removeObjectAtIndex:1];

        numberOfColumns--;

        // Take note that a column count change occurred
        columnCountChanged = YES;
    }

    // Expand columns to the necessary number
    while (numberOfColumns < newNumberOfColumns && _visibleViewControllers.count < 3) {
        TOSplitViewControllerType type = (numberOfColumns == 2) ? TOSplitViewControllerTypeSecondary : TOSplitViewControllerTypeDetail;
        UIViewController *primaryViewController = _visibleViewControllers.firstObject;

        // Work out if there is a previous controller in this split controller that may get replaced
        UIViewController *originalController = nil;
        if (type == TOSplitViewControllerTypeDetail) {
            originalController = _viewControllers.lastObject;
        }
        else {
            originalController = _viewControllers[1];
        }

        // Restore the original controller for now
        [_visibleViewControllers insertObject:originalController atIndex:1];

        // Check if the user has provided custom expansion callbacks
        __block UIViewController *expandedViewController = nil;
        if (_delegateFlags.separateFromPrimary) {
            expandedViewController = [self.delegate splitViewController:self
                                           separateViewControllerOfType:type
                                              fromPrimaryViewController:primaryViewController];
        }

        // If not, default back the view controller logic
        if (expandedViewController == nil && [primaryViewController respondsToSelector:@selector(separateAuxiliaryViewController:ofType:forSplitViewController:shouldAnimate:)]) {
            expandedViewController = [primaryViewController separateAuxiliaryViewController:originalController ofType:type forSplitViewController:self shouldAnimate:NO];
        }

        // Add the original controller in
        [self addSplitViewControllerChildViewController:originalController];

        // If we did get a new controller, replace/merge the original controller with it
        if (expandedViewController) {
            [self replaceChildViewController:originalController withController:expandedViewController];
        }

        // Finally, customize the primary controller if needed
        if (_delegateFlags.expandPrimaryToSecondary) {
            UIViewController *newPrimary = [self.delegate splitViewController:self primaryViewControllerForExpandingToType:type];
            [self replaceChildViewController:primaryViewController withController:newPrimary];
        }

        numberOfColumns++;

        // Take note that a column count change happened
        columnCountChanged = YES;
    }

    // If a merge/collapse occurred, trigger a notification for any interested objects watching
    if (columnCountChanged) {
        [self postShowNewViewControllerNotification];
    }
}

- (BOOL)replaceChildViewController:(UIViewController *)originalController withController:(UIViewController *)newController
{
    // Skip if the new primary controller is actually the original (ie a navigation controller)
    if (originalController == newController) { return NO; }
    if (newController == nil) { return NO; }

    // Remove the original view controller and add the new one
    [self removeSplitViewControllerChildViewController:originalController];
    [self addSplitViewControllerChildViewController:newController];

    NSUInteger index = [_visibleViewControllers indexOfObject:originalController];
    if (index != NSNotFound) {
        [_visibleViewControllers replaceObjectAtIndex:index withObject:newController];
    }

    index = [_viewControllers indexOfObject:originalController];
    if (index != NSNotFound) {
        [_viewControllers replaceObjectAtIndex:index withObject:newController];
    }

    return YES;
}

- (NSInteger)possibleNumberOfColumnsForWidth:(CGFloat)width
{
    // Not a regular side class (eg, iPhone / iPad Split View)
    if (self.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
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

#pragma mark - View Controller Presentation/Navigation -
- (void)postShowNewViewControllerNotification
{
    NSDictionary *userInfo = @{TOSplitViewControllerNotificationSplitViewControllerKey : self};
    [[NSNotificationCenter defaultCenter] postNotificationName:TOSplitViewControllerShowTargetDidChangeNotification object:self userInfo:userInfo];
}

- (void)to_showViewController:(nullable UIViewController *)viewController sender:(nullable id)sender
{
    [self showViewController:viewController sender:sender];
}

- (void)to_showSecondaryViewController:(nullable UIViewController *)viewController sender:(nullable id)sender
{
    // Let the delegate completely override this
    if (_delegateFlags.showSecondaryViewController) {
        if ([self.delegate splitViewController:self showSecondaryViewController:viewController sender:sender]) {
            [_viewControllers insertObject:viewController atIndex:1];
            return;
        }
    }

    NSInteger numberOfVisibleColumns = self.visibleViewControllers.count;
    // Check if we already have a secondary controller that needs to be extracted
    if (self.viewControllers.count == 3) {
        UIViewController *secondaryController = self.viewControllers[1];

        // Cancel out if we're already showing this controller
        if ([secondaryController isEqual:viewController]) {
            return;
        }

        [self extractFromPrimaryAuxiliaryViewController:secondaryController ofType:TOSplitViewControllerTypeSecondary];
    }

    // If we set an empty value, cancel out here
    if (viewController == nil) {
        if (_visibleViewControllers.count != numberOfVisibleColumns) {
            [self layoutSplitViewControllerContentForSize:self.view.bounds.size];
        }
        return;
    }

    // Insert the new controller
    [_viewControllers insertObject:viewController atIndex:1];

    // Check if we have enough space to display it
    NSInteger possibleColumnsCount = [self possibleNumberOfColumnsForWidth:self.view.bounds.size.width];
    if (possibleColumnsCount > self.visibleViewControllers.count) {
        [_visibleViewControllers insertObject:viewController atIndex:1];
        [self addSplitViewControllerChildViewController:viewController];
        [self layoutSplitViewControllerContentForSize:self.view.bounds.size];
        return;
    }

    // Otherwise perform the logic to collapse these controllers into the primary
    [self mergeWithPrimaryAuxiliaryViewController:viewController ofType:TOSplitViewControllerTypeSecondary];
}

- (void)to_showDetailViewController:(nullable UIViewController *)viewController sender:(nullable id)sender
{
    [self showDetailViewController:viewController collapse:YES sender:sender];
}

- (void)to_setDetailViewController:(UIViewController *)viewController sender:(id)sender
{
    [self showDetailViewController:viewController collapse:NO sender:sender];
}

- (void)showDetailViewController:(nullable UIViewController *)viewController collapse:(BOOL)collapse sender:(nullable id)sender
{
    // Let the delegate completely override this
    if (_delegateFlags.showDetailViewController) {
        if ([self.delegate splitViewController:self showDetailViewController:viewController sender:sender]) {
            [_viewControllers addObject:viewController];
            return;
        }
    }

    NSInteger numberOfVisibleColumns = self.visibleViewControllers.count;

    // Check if we already have a detail controller that needs to be extracted
    if (self.viewControllers.count > 1) {
        UIViewController *detailController = self.viewControllers.lastObject;
        [self extractFromPrimaryAuxiliaryViewController:detailController ofType:TOSplitViewControllerTypeDetail];
    }

    // If we set an empty value, cancel out here
    if (viewController == nil) {
        if (_visibleViewControllers.count != numberOfVisibleColumns) {
            [self layoutSplitViewControllerContentForSize:self.view.bounds.size];
        }
        return;
    }

    // Insert the new controller
    [_viewControllers addObject:viewController];

    // Check if we have enough space to display it
    NSInteger possibleColumnsCount = [self possibleNumberOfColumnsForWidth:self.view.bounds.size.width];
    if (possibleColumnsCount > self.visibleViewControllers.count) {
        [_visibleViewControllers addObject:viewController];
        [self addSplitViewControllerChildViewController:viewController];
        [self layoutSplitViewControllerContentForSize:self.view.bounds.size];
        return;
    }

    // Otherwise perform the logic to collapse these controllers into the primary
    if (collapse) {
        [self mergeWithPrimaryAuxiliaryViewController:viewController ofType:TOSplitViewControllerTypeDetail];
    }
}

- (void)to_showSecondaryViewController:(nullable UIViewController *)secondaryViewController
               setDetailViewController:(nullable UIViewController *)detailViewController
                                sender:(nullable id)sender
{
    [self to_showSecondaryViewController:secondaryViewController sender:sender];
    [self showDetailViewController:detailViewController collapse:NO sender:sender];
}

- (void)mergeWithPrimaryAuxiliaryViewController:(UIViewController *)viewController ofType:(TOSplitViewControllerType)type
{
    BOOL success = NO;
    if (!success && [self.primaryViewController respondsToSelector:@selector(collapseAuxiliaryViewController:ofType:forSplitViewController:shouldAnimate:)]) {
        [self.primaryViewController collapseAuxiliaryViewController:viewController ofType:type forSplitViewController:self shouldAnimate:YES];
    }
}

- (void)extractFromPrimaryAuxiliaryViewController:(UIViewController *)viewController ofType:(TOSplitViewControllerType)type
{
    // If it's not visible, it's collapsed with the primary. Separate it from the primary first
    if ([self.visibleViewControllers indexOfObject:viewController] == NSNotFound) {
        UIViewController *controller = nil;
        if (_delegateFlags.separateFromPrimary) {
            controller = [self.delegate splitViewController:self separateViewControllerOfType:type fromPrimaryViewController:self.primaryViewController];
        }

        if (controller == nil) {
            if ([self.primaryViewController respondsToSelector:@selector(separateAuxiliaryViewController:ofType:forSplitViewController:shouldAnimate:)]) {
                controller = [self.primaryViewController separateAuxiliaryViewController:viewController ofType:type forSplitViewController:self shouldAnimate:YES];
            }
        }

        viewController = controller;
    }

    // Strip it out of the split view controller
    [self removeSplitViewControllerChildViewController:viewController];
    [_visibleViewControllers removeObject:viewController];
    [_viewControllers removeObject:viewController];
}

#pragma mark - Accessors -
- (void)setDelegate:(id<TOSplitViewControllerDelegate>)delegate
{
    if (delegate == _delegate) { return; }
    _delegate = delegate;

    _delegateFlags.showSecondaryViewController = [_delegate respondsToSelector:@selector(splitViewController:showSecondaryViewController:sender:)];
    _delegateFlags.showDetailViewController = [_delegate respondsToSelector:@selector(splitViewController:showDetailViewController:sender:)];
    _delegateFlags.collapseAuxiliaryToPrimary = [_delegate respondsToSelector:@selector(splitViewController:collapseViewController:ofType:ontoPrimaryViewController:shouldAnimate:)];
    _delegateFlags.separateFromPrimary = [_delegate respondsToSelector:@selector(splitViewController:separateViewControllerOfType:fromPrimaryViewController:)];
    _delegateFlags.primaryForCollapsing = [_delegate respondsToSelector:@selector(splitViewController:primaryViewControllerForCollapsingFromType:)];
    _delegateFlags.expandPrimaryToSecondary = [_delegate respondsToSelector:@selector(splitViewController:primaryViewControllerForExpandingToType:)];
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers
{
    if ([_viewControllers isEqual:viewControllers]) { return; }

    _viewControllers = [viewControllers mutableCopy];
    _visibleViewControllers = [viewControllers mutableCopy];

    if (self.isBeingPresented) {
        [self layoutSplitViewControllerContentForSize:self.view.bounds.size];
    }
}

- (NSArray<UIViewController *> *)viewControllers
{
    return [NSArray arrayWithArray:_viewControllers];
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

#pragma mark - UViewController Category -

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

- (void)to_showViewController:(nullable UIViewController *)viewController sender:(nullable id)sender
{
    UIViewController *targetViewController = [self targetViewControllerForAction:@selector(to_showViewController:sender:) sender:sender];
    if (targetViewController) {
        [targetViewController to_showViewController:viewController sender:sender];
    }
}


- (void)to_showSecondaryViewController:(nullable UIViewController *)viewController sender:(nullable id)sender
{
    UIViewController *targetViewController = [self targetViewControllerForAction:@selector(to_showSecondaryViewController:sender:) sender:sender];
    if (targetViewController) {
        [targetViewController to_showSecondaryViewController:viewController sender:sender];
    }
}


- (void)to_showSecondaryViewController:(nullable UIViewController *)secondaryViewController
       setDetailViewController:(nullable UIViewController *)detailViewController
                                sender:(nullable id)sender
{
    UIViewController *targetViewController = [self targetViewControllerForAction:@selector(to_showSecondaryViewController:setDetailViewController:sender:) sender:sender];
    if (targetViewController) {
        [targetViewController to_showSecondaryViewController:secondaryViewController setDetailViewController:detailViewController sender:sender];
    }
}

- (void)to_showDetailViewController:(nullable UIViewController *)viewController sender:(nullable id)sender
{
    UIViewController *targetViewController = [self targetViewControllerForAction:@selector(to_showDetailViewController:sender:) sender:sender];
    if (targetViewController) {
        [targetViewController to_showDetailViewController:viewController sender:sender];
    }
}

- (void)to_setDetailViewController:(nullable UIViewController *)viewController sender:(nullable id)sender
{
    UIViewController *targetViewController = [self targetViewControllerForAction:@selector(to_setDetailViewController:sender:) sender:sender];
    if (targetViewController) {
        [targetViewController to_setDetailViewController:viewController sender:sender];
    }
}

@end

#pragma clang diagnostic pop

