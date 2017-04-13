//
//  TONavigationControllerCategoryTests.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 4/4/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "UINavigationController+TOSplitViewController.h"

@interface TONavigationControllerCategoryTests : XCTestCase

@end

@implementation TONavigationControllerCategoryTests

- (void)testNavigationController {
    // Create two navigation controllers
    UINavigationController *primaryNavigationController = [[UINavigationController alloc] init];
    UINavigationController *secondaryNavigationController = [[UINavigationController alloc] init];

    // Perform these operations in an autoreleasepool so our creation of the view controllers here
    // don't influence the release operation at the bottom
    @autoreleasepool {
        // Push 3 arbitrary controllers onto each one
        for (NSInteger i = 0; i < 3; i++) {
            UIViewController *primaryController = [[UIViewController alloc] init];
            UIViewController *secondaryController = [[UIViewController alloc] init];

            [primaryNavigationController pushViewController:primaryController animated:NO];
            [secondaryNavigationController pushViewController:secondaryController animated:NO];
        }

        // Confirm each controller now has 3 controllers assigned
        XCTAssert(primaryNavigationController.viewControllers.count == 3);
        XCTAssert(secondaryNavigationController.viewControllers.count == 3);

        // Move all the controllers to the primary navigation controller
        [secondaryNavigationController toSplitViewController_moveViewControllersToNavigationController:primaryNavigationController animated:NO];

        // Confirm the primary has 6 controllers, and the secondary has 0
        XCTAssert(primaryNavigationController.viewControllers.count == 6);
        XCTAssert(secondaryNavigationController.viewControllers.count == 0);

        // Move them back
        [secondaryNavigationController toSplitViewController_restoreViewControllersAnimated:NO];

        // Confirm the controllers are in parity again
        XCTAssert(primaryNavigationController.viewControllers.count == 3);
        XCTAssert(secondaryNavigationController.viewControllers.count == 3);

        // Move the controllers across, and then dismiss all controllers from the secondary controller
        [secondaryNavigationController toSplitViewController_moveViewControllersToNavigationController:primaryNavigationController animated:NO];

        for (NSInteger i = 0; i < 3; i++) {
            [primaryNavigationController popViewControllerAnimated:NO];
        }
    }

    // Confirm the controllers were popped
    XCTAssert(primaryNavigationController.viewControllers.count == 3);

    // Now attempt to restore the second controller
    [secondaryNavigationController toSplitViewController_restoreViewControllersAnimated:NO];

    // We should have gotten the root controller of the secondary controller back
    XCTAssert(secondaryNavigationController.viewControllers.count == 1);
}

@end
