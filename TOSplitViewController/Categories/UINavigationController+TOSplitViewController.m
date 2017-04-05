//
//  UINavigationController+TOSplitViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 4/4/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "UINavigationController+TOSplitViewController.h"
#import <objc/runtime.h>

static void *TOSplitViewControllerRootControllerKey;
static void *TOSplitViewControllerViewControllersKey;

const NSString *TOSplitViewControllerMapTableKey = @"viewControllers";

@implementation UINavigationController (TOSplitViewController)

- (BOOL)toSplitViewController_moveViewControllersToNavigationController:(UINavigationController *)navigationController
{
    if (self.viewControllers.count == 0) {
        return YES;
    }

    // Save a strong reference to the root controller, so even if it is completely dismissed, it
    // won't be released from memory
    [self toSplitViewController_setRootViewController:self.viewControllers.firstObject];

    // Save an internal reference to all view controllers weakly so they can be backtracked here
    [self toSplitViewController_setViewControllerStack:self.viewControllers];

    // Pull out the view controllers, and push them onto the target controller
    NSArray *controllers = [self.viewControllers copy];
    self.viewControllers = [NSArray array];

    for (UIViewController *controller in controllers) {
        [navigationController pushViewController:controller animated:NO];
    }

    return YES;
}

- (void)toSplitViewController_restoreViewControllers
{
    NSArray *viewControllers = [self toSplitViewController_viewControllerStack];
    for (UIViewController *controller in viewControllers) {
        // Remove this controller from the other controller
        if (controller.navigationController) {
            NSMutableArray *viewControllers = [controller.navigationController.viewControllers mutableCopy];
            [viewControllers removeObject:controller];
            [controller.navigationController setViewControllers:viewControllers animated:NO];
        }

        // Push it back to us
        [self pushViewController:controller animated:NO];
    }

    // Flush out the internal properties
    [self toSplitViewController_setViewControllerStack:nil];
    [self toSplitViewController_setRootViewController:nil];
}

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

@end
