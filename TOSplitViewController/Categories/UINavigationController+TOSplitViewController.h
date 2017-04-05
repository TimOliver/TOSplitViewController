//
//  UINavigationController+TOSplitViewController.h
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 4/4/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (TOSplitViewController)

- (BOOL)toSplitViewController_moveViewControllersToNavigationController:(UINavigationController *)navigationController;
- (void)toSplitViewController_restoreViewControllers;

@end
