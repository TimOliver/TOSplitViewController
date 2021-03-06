//
//  ListTableViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 3/19/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "SecondaryViewController.h"
#import "TOSplitViewController.h"

@interface SecondaryViewController ()

@end

@implementation SecondaryViewController

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

- (void)splitControllerShowTargetChangedNotification:(NSNotification *)notification
{
    [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Secondary";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"Secondary will appear");
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Show the disclosure chevrons if we're completely collapsed
    if (self.to_splitViewController.visibleViewControllers.count < 2)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    cell.textLabel.text = [NSString stringWithFormat:@"Cell %ld", (long)indexPath.row];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

@end
