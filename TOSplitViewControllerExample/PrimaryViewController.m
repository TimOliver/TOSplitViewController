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
#import "DetailViewController.h"

@interface PrimaryViewController ()

@end

@implementation PrimaryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Primary";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"Primary will appear");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"THREE COLUMNS" : @"TWO COLUMNS";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    cell.textLabel.text = [NSString stringWithFormat:@"Cell %ld", (long)indexPath.row+1];

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Two columns
    if (indexPath.section == 1) {
        [self to_showSecondaryViewController:nil sender:self];

        DetailViewController *controller = [[DetailViewController alloc] init];
        [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
    }
    else { // Three columns
        SecondaryViewController *secondary = [[SecondaryViewController alloc] init];
        [self to_showSecondaryViewController:[[UINavigationController alloc] initWithRootViewController:secondary] sender:self];
    }
}

@end
