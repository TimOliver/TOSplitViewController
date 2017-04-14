//
//  PrimaryViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 4/13/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "PrimaryViewController.h"
#import "TOSplitViewController.h"
#import "SecondaryViewController.h"

@interface PrimaryViewController ()

@end

@implementation PrimaryViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    if (indexPath.row == 0) {
        cell.textLabel.text = @"Three Columns";
    }
    else {
        cell.textLabel.text = @"Two Columns";
    }

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [self to_showSecondaryViewController:nil sender:self];
    }
    else {
        SecondaryViewController *secondary = [[SecondaryViewController alloc] init];
        [self to_showSecondaryViewController:[[UINavigationController alloc] initWithRootViewController:secondary] sender:self];
    }
}

@end
