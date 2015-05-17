//
//  AboutViewController.m
//  ComicAR
//
//  Created by 靳杰 on 15/2/4.
//  Copyright (c) 2015年 靳杰. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *copyrightButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *copyrightWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *copyrightHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *closeWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aboutTopSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *closeRightSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *closeTopSpace;
@property (weak, nonatomic) IBOutlet UITextView *versionTextView;

@end

@implementation AboutViewController

- (BOOL) isPad {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self isPad]) {
        _titleLabel.font = [UIFont systemFontOfSize:50];
        _versionLabel.font = [UIFont systemFontOfSize:30];
        _copyrightButton.font = [UIFont systemFontOfSize:30];
        _copyrightWidth.constant = 400;
        _copyrightHeight.constant = 100;
        _closeWidth.constant = 60;
        _aboutTopSpace.constant = 100;
        _closeRightSpace.constant = 100;
        _closeTopSpace.constant = 100;
        _versionTextView.font = [UIFont systemFontOfSize:50];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end