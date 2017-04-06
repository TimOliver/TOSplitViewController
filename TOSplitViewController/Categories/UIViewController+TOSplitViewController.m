//
//  UIViewController+TOSplitViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 4/5/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "UIViewController+TOSplitViewController.h"

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
