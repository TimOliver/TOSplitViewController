//
//  UINavigationController+TOSplitViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 4/4/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "UINavigationController+TOSplitViewController.h"
#import <objc/runtime.h>
#import "TOSplitViewController.h"

static void *TOSplitViewControllerRootControllerKey;
static void *TOSplitViewControllerViewControllersKey;

const NSString *TOSplitViewControllerMapTableKey = @"viewControllers";

@implementation UINavigationController (TOSplitViewController)

#pragma mark - Public Interface -

- (BOOL)toSplitViewController_moveViewControllersToNavigationController:(UINavigationController *)navigationController
{
    if (self.viewControllers.count == 0) {
        return YES;
    }

    // Save a strong reference to the root controller, so even if it is completely dismissed, it
    // won't be released from memory (and we can restore to it later)
    [self toSplitViewController_setRootViewController:self.viewControllers.firstObject];

    // Save an weak copy of all of the view controllers. If they get popped by the user,
    // they'll be released from here too.
    [self toSplitViewController_setViewControllerStack:self.viewControllers];

    // Pull out the view controllers, and nil them out from this controller
    NSArray *controllers = [self.viewControllers copy];
    self.viewControllers = [NSArray array];

    // Push them onto the target controller
    for (UIViewController *controller in controllers) {
        [navigationController pushViewController:controller animated:NO];
    }

    return YES;
}

- (void)toSplitViewController_restoreViewControllers
{
    // Loop through all the controllers we had saved and restore them.
    NSArray *viewControllers = [self toSplitViewController_viewControllerStack];
    for (UIViewController *controller in viewControllers) {
        if (controller.navigationController) {
            NSMutableArray *viewControllers = [controller.navigationController.viewControllers mutableCopy];
            [viewControllers removeObject:controller];
            [controller.navigationController setViewControllers:viewControllers animated:NO];
        }

        // Push it back to us
        [self pushViewController:controller animated:NO];
    }

    // Flush out the internal properties so there are no leaked references
    [self toSplitViewController_setViewControllerStack:nil];
    [self toSplitViewController_setRootViewController:nil];
}

#pragma mark - Property Management -

- (void)toSplitViewController_setRootViewController:(UIViewController *)rootViewController
{
    objc_setAssociatedObject(self, &TOSplitViewControllerRootControllerKey, rootViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable UIViewController *)toSplitViewController_rootViewController
{
    return objc_getAssociatedObject(self, &TOSplitViewControllerRootControllerKey);
}

- (void)toSplitViewController_setViewControllerStack:(NSArray<UIViewController *> *)viewControllers
{
    if (viewControllers == nil) {
        objc_setAssociatedObject(self, &TOSplitViewControllerViewControllersKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    NSPointerArray *pointerArray = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
    for (UIViewController *controller in viewControllers) {
        [pointerArray addPointer:(__bridge void * _Nullable)(controller)];
    }

    objc_setAssociatedObject(self, &TOSplitViewControllerViewControllersKey, pointerArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable NSArray *)toSplitViewController_viewControllerStack
{
    NSPointerArray *pointerArray = objc_getAssociatedObject(self, &TOSplitViewControllerViewControllersKey);
    NSMutableArray *viewControllers = [NSMutableArray array];
    for (id object in pointerArray) {
        if ([object isKindOfClass:[UIViewController class]] == NO) { continue; }
        [viewControllers addObject:object];
    }

    return viewControllers;
}

#pragma mark - Expand/Collapse Integration -
- (void)collapseAuxiliaryViewController:(UIViewController *)auxiliaryViewController
                                 ofType:(TOSplitViewControllerType)type
                 forSplitViewController:(TOSplitViewController *)splitViewController
{
    // We can only work with 2 navigation view controllers
    if (![auxiliaryViewController isKindOfClass:[UINavigationController class]]) {
        return;
    }

    [(UINavigationController *)auxiliaryViewController toSplitViewController_moveViewControllersToNavigationController:self];
}

- (nullable UIViewController *)separateAuxiliaryViewControllerOfType:(TOSplitViewControllerType)type
                                              forSplitViewController:(TOSplitViewController *)splitViewController
{
    UIViewController *targetViewController = nil;
    if (type == TOSplitViewControllerTypeDetail) { //expanding from 1 column to 2
        targetViewController = splitViewController.detailViewController;
    }
    else if (type == TOSplitViewControllerTypeSecondary) { // expanding from 2 to 3 columns
        targetViewController = splitViewController.secondaryViewController;
    }

    if (targetViewController || ![targetViewController isKindOfClass:[UINavigationController class]]) {
        return nil;
    }

    [(UINavigationController *) targetViewController toSplitViewController_restoreViewControllers];
    return targetViewController;
}

@end
