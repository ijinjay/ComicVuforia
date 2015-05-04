//
//  ViewController.m
//  ComicVuforia
//
//  Created by 靳杰 on 15/3/5.
//  Copyright (c) 2015年 靳杰. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking/AFNetworking.h"
#import "MBProgressHUD.h"
#import "SSZipArchive/SSZipArchive.h"

// 服务器地址
static NSString *ServerAddress = @"http://182.92.175.104:8666";

@interface ViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *briefButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *aboutButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startTopSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startLeftSpace;
@property (nonatomic) NSString *response;
@property (nonatomic, retain) MBProgressHUD *hud;

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
    
    if ([user objectForKey:@"modelName"] == nil) {
        [user setObject:@"Histoire" forKey:@"modelName"];
    }
    
    _startButton.backgroundColor = colorArray[_colorIndex];
    _briefButton.backgroundColor = colorArray[_colorIndex];
    _aboutButton.tintColor = colorArray[_colorIndex];
    _settingButton.tintColor = colorArray[_colorIndex];
    // 检查更新
    _hud = [[MBProgressHUD alloc] initWithView:self.view];
    _hud.removeFromSuperViewOnHide = NO;
    [self.view addSubview:_hud];
    [self checkVersion];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - checkVersion
- (void)checkVersion{
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    if ([user objectForKey:@"needUpdate"] == nil) {
        [user setObject:@"YES" forKey:@"needUpdate"];
    }
    NSString *needUpdate = (NSString *)[user objectForKey:@"needUpdate"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:@"model.plist"]]) {
        NSMutableDictionary *localPlist  = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"model" ofType:@"plist"]];
        [localPlist writeToFile:[documentsDirectory stringByAppendingPathComponent:@"model.plist"] atomically:YES];
    }
    
    NSURL *url = [NSURL URLWithString:[ServerAddress stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        _response = operation.responseString;
        NSMutableDictionary *serverPlist = [NSPropertyListSerialization propertyListWithData:([_response dataUsingEncoding:NSUTF8StringEncoding]) options:kNilOptions format:nil error:nil];
        NSMutableDictionary *localPlist  = [[NSMutableDictionary alloc] initWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"model.plist"]];
        NSNumber *serverVersion = [serverPlist objectForKey:@"version"];
        NSNumber *localVersion  = [localPlist objectForKey:@"version"];
        
        if ([user objectForKey:@"serverVersion"] == nil || ([needUpdate compare:@"YES"] == NSOrderedSame)) {
            [user setObject:serverVersion forKey:@"serverVersion"];
        }
        NSLog(@"server:%@  local:%@ userServerVersion:%@, needUpdate:%@", serverVersion, localVersion, [user objectForKey:@"serverVersion"], needUpdate);
        if ( (([needUpdate compare:@"YES"] == NSOrderedSame) && ([serverVersion floatValue] > [localVersion floatValue])) || (([needUpdate compare:@"NO"] == NSOrderedSame) && ([serverVersion floatValue] > [(NSNumber *)[user objectForKey:@"serverVersion"] floatValue])) ) {
            NSLog(@"need upgrade");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"检测到更新" message:@"亲，升级数据库咯:^)" delegate:self cancelButtonTitle:@"残忍拒绝" otherButtonTitles:@"马上升级", nil];
            [alert show];
        }else{
            NSLog(@"did not need upgrade");
        }
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"未能检测版本更新 %@",error);
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

- (NSURLSessionDownloadTask *)download:(NSString *)urlString{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
        // Unzipping
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *zipPath = [documentsDirectory stringByAppendingPathComponent:[filePath lastPathComponent]];
        NSString *destinationPath = documentsDirectory;
        
        NSLog(@"destinationpath: %@", destinationPath);
        NSLog(@"unzip success?:%d", [SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath]);
        // 删除zip文件
        [[NSFileManager defaultManager] removeItemAtPath:zipPath error:nil];
    }];
    return downloadTask;
}

#pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    if (buttonIndex == 0) {
        NSLog(@"残忍拒绝");
        [user setObject:@"NO" forKey:@"needUpdate"];
    } else {
        [user setObject:@"YES" forKey:@"needUpdate"];
        NSLog(@"马上升级");
        _hud.mode = MBProgressHUDModeIndeterminate;
        _hud.labelText = @"正在下载";
        [_hud show:YES];
        NSMutableDictionary *serverPlist = [NSPropertyListSerialization propertyListWithData:([_response dataUsingEncoding:NSUTF8StringEncoding]) options:kNilOptions format:nil error:nil];
        NSMutableDictionary *localPlist  = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"model" ofType:@"plist"]];
        for (NSString *aKey in [serverPlist allKeys]) {
            if ([aKey compare:@"version"] != NSOrderedSame) {
                NSMutableDictionary *localItem = [localPlist objectForKey:aKey];
                NSMutableDictionary *serverItem = [serverPlist objectForKey:aKey];
                if (localItem == nil || ([(NSNumber *)[localItem objectForKey:@"version"] floatValue] < [(NSNumber *)[serverItem objectForKey:@"version"] floatValue])) {
                    NSString *downloadUrl = [NSString stringWithFormat:@"%@/static/%@.scnassets.zip", ServerAddress, aKey];
                    NSURLSessionDownloadTask *downloadTask = [self download:downloadUrl];
                    [downloadTask resume];
                }
            }
        }
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        [_response writeToFile:[documentsDirectory stringByAppendingPathComponent:@"model.plist"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [_hud hide:YES];
    }
}

@end
