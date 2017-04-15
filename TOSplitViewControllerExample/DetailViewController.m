//
//  DetailViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 3/19/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation DetailViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"Detail will appear");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    self.label = [[UILabel alloc] initWithFrame:CGRectZero];
    self.label.textColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
    self.label.text = self.labelText ? self.labelText : @"XD";
    self.label.font = [UIFont systemFontOfSize:120.0f weight:UIFontWeightMedium];
    self.label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
                                    | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.label];

    [self.label sizeToFit];
    self.label.center = self.view.center;

    self.title = @"Detail";
}

@end
