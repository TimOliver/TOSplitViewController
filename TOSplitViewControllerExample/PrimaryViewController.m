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

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(splitControllerShowTargetChangedNotification:) name:TOSplitViewControllerShowTargetDidChangeNotification object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TOSplitViewControllerShowTargetDidChangeNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Primary";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"Primary will appear");
}

- (void)splitControllerShowTargetChangedNotification:(NSNotification *)notification
{
    [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Unless we're completely expanded, this controller will have some UINavigationController push logic.
    // As such, show the disclosure chevrons
    if ((indexPath.section == 0 && self.to_splitViewController.visibleViewControllers.count < 3) ||
        (indexPath.section == 1 && self.to_splitViewController.visibleViewControllers.count < 2))
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
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

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
