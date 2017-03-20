//
//  AppDelegate.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 3/14/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "AppDelegate.h"
#import "TOSplitViewController.h"
#import "ListTableViewController.h"
#import "DetailViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    ListTableViewController *mainController = [[ListTableViewController alloc] init];
    UINavigationController *primaryNavController = [[UINavigationController alloc] initWithRootViewController:mainController];

    ListTableViewController *secondaryController = [[ListTableViewController alloc] init];
    UINavigationController *secondaryNavController = [[UINavigationController alloc] initWithRootViewController:secondaryController];

    DetailViewController *detailController = [[DetailViewController alloc] init];
    UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:detailController];

    NSArray *controllers = @[primaryNavController, secondaryNavController, detailNavController];
    TOSplitViewController *splitViewController = [[TOSplitViewController alloc] initWithViewControllers:controllers];

    self.window.rootViewController = splitViewController;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
