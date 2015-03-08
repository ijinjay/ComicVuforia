//
//  ViewController.m
//  ComicVuforia
//
//  Created by 靳杰 on 15/3/5.
//  Copyright (c) 2015年 靳杰. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *briefButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *aboutButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startTopSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startLeftSpace;

@property (nonatomic) NSInteger colorIndex;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prefersStatusBarHidden];
    _startButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    // 更新iPad的界面
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        _startButton.titleLabel.font = [UIFont systemFontOfSize:60];
        _briefButton.titleLabel.font = [UIFont systemFontOfSize:45];
        [_aboutButton setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:45]} forState:UIControlStateNormal];
        [_settingButton setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:45]} forState:UIControlStateNormal];
        _startLeftSpace.constant = 100;
        _startTopSpace.constant = 100;
        _toolbarHeight.constant = 64;
    }
    
    // 设置界面颜色
    _startButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_startButton setTitle:@"开启\n奇幻之旅" forState:UIControlStateNormal];
    UIColor *color1 = [UIColor colorWithRed:(46/255.0) green:(204/255.0) blue:(113/255.0) alpha:1.0];
    UIColor *color2 = [UIColor colorWithRed:(26/255.0) green:(188/255.0) blue:(204/255.0) alpha:1.0];
    UIColor *color3 = [UIColor colorWithRed:(231/255.0) green:(76/255.0) blue:(60/255.0) alpha:1.0];
    UIColor *color4 = [UIColor colorWithRed:(0/255.0) green:(213/255.0) blue:(255/255.0) alpha:1.0];
    UIColor *color5 = [UIColor colorWithRed:(255/255.0) green:(51/255.0) blue:(146/255.0) alpha:1.0];
    UIColor *color6 = [UIColor colorWithRed:(254/255.0) green:(247/255.0) blue:(4/255.0) alpha:1.0];
    UIColor *color7 = [UIColor colorWithRed:(231/255.0) green:(76/255.0) blue:(60/255.0) alpha:1.0];

    
    NSArray *colorArray = [[NSArray alloc] initWithObjects:color1, color2, color3, color4, color5, color6, color7, nil];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    if ([user objectForKey:@"colorIndex"] == nil) {
        _colorIndex = 0;
        [user setInteger:_colorIndex forKey:@"colorIndex"];
    } else {
        _colorIndex = [user integerForKey:@"colorIndex"];
    }
    [user setObject:[NSKeyedArchiver archivedDataWithRootObject:colorArray[_colorIndex]] forKey:@"backgroundcolor"];
    [user setInteger:colorArray.count forKey:@"colorcount"];
    
    _startButton.backgroundColor = colorArray[_colorIndex];
    _briefButton.backgroundColor = colorArray[_colorIndex];
    _aboutButton.tintColor = colorArray[_colorIndex];
    _settingButton.tintColor = colorArray[_colorIndex];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
