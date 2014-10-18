//
//  ViewController.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMAuthorizationController.h"

@interface HMAuthorizationController ()

@end

@implementation HMAuthorizationController

- (void)viewDidLoad {
    [super viewDidLoad];

    [VKSdk initializeWithDelegate:self andAppId:VK_APP_ID];
    if ([VKSdk wakeUpSession])
    {
        [VKSdk authorize:@[VK_PER_FRIENDS, VK_PER_MESSAGES]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - VKSdkDelegate methods
- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken;
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

@end
