//
//  ViewController.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMAuthorizationController.h"
#import "HMFriendsListController.h"

@interface HMAuthorizationController ()

@end

@implementation HMAuthorizationController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (IBAction)vkLoginBtClick:(id)sender
{
    [VKSdk initializeWithDelegate:self andAppId:VK_APP_ID];
    [VKSdk authorize:@[VK_PER_FRIENDS, VK_PER_MESSAGES]];
}

#pragma mark - Private methods

- (void)showFriendsList
{
    HMFriendsListController * friendsListController = [HMFriendsListController new];
    [friendsListController loadFriendsListFromVK];
    [self.navigationController pushViewController:friendsListController animated:YES];
}

#pragma mark - VKSdkDelegate methods

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError;
{
    VKCaptchaViewController * vc = [VKCaptchaViewController captchaControllerWithError:captchaError];
    [vc presentIn:self];
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
    [self showFriendsList];
}

@end
