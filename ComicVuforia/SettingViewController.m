//
//  SettingViewController.m
//  ComicVuforia
//
//  Created by JinJay on 15/3/18.
//  Copyright (c) 2015年 靳杰. All rights reserved.
//

#import "SettingViewController.h"
#import "ViewController.h"

@interface SettingViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
- (IBAction)finished:(id)sender;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleTop;
@property (weak, nonatomic) IBOutlet UILabel *titleText;

@property (nonatomic, retain) NSArray *array;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidth;
@property (weak, nonatomic) IBOutlet UILabel *choseTitle;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chooseTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pickerTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pickerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pickerWidth;
@property (weak, nonatomic) IBOutlet UIButton *finishButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *finishBottom;

@end

@implementation SettingViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    // 更新iPad的界面
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        _titleTop.constant = 50;
        _imageTop.constant = 50;
        _chooseTop.constant = 80;
        _pickerTop.constant = 80;
        _pickerHeight.constant = 200;
        _pickerWidth.constant = 300;
        
        _imageView.frame = CGRectMake(0, 0, 300, 300);
        _imageWidth.constant = 300;
        
        _titleText.font = [UIFont systemFontOfSize:50];
        _finishButton.titleLabel.font = [UIFont systemFontOfSize:50];
        _finishBottom.constant = 50;
        _choseTitle.font = [UIFont systemFontOfSize:40];
    }
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:[user objectForKey:@"backgroundcolor"]];
    self.view.backgroundColor = color;
    
    _array = [[NSArray alloc] initWithObjects:@"Histoire", @"superman", nil];
    // get the user data
    if ([user objectForKey:@"modelName"] == nil) {
        [user setObject:[_array objectAtIndex:0] forKey:@"modelName"];
    }
    
    NSString *modelName = [user objectForKey:@"modelName"];
    _imageView.layer.masksToBounds = YES;
    _imageView.layer.cornerRadius = _imageView.frame.size.height / 2;
    
    UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:modelName ofType:@"png"]];
    [_imageView setImage:image];
    
    _pickerView.delegate = self;
    _pickerView.dataSource = self;
    [_pickerView setShowsSelectionIndicator:YES];
    if ([modelName compare:@"superman"] == NSOrderedSame) {
        [_pickerView selectRow:1 inComponent:0 animated:YES];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)finished:(id)sender {
    NSString *modelName = [_array  objectAtIndex:[_pickerView selectedRowInComponent:0]];
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    [user setObject:modelName forKey:@"modelName"];
    NSLog(@"set modelName: %@", modelName);
}
#pragma mark PickerView protocol
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel* tView = (UILabel*)view;
    view.frame = CGRectMake(0, 0, 200, 30);
    if (!tView){
        tView = [[UILabel alloc] init];
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        tView.font = [UIFont systemFontOfSize:40];
        tView.frame = CGRectMake(0, 0, 300, 50);
    }
    tView.textAlignment = NSTextAlignmentCenter;
    tView.text = [_array objectAtIndex:row];
    return tView;
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [_array objectAtIndex:row];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_array count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *modelName = [_array  objectAtIndex:[pickerView selectedRowInComponent:0]];
    UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:modelName ofType:@"png"]];
    [_imageView setImage:image];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return 40.0;
    }
    return 20.0;
}
@end
