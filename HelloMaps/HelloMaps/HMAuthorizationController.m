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
@property (weak, nonatomic) IBOutlet UIView *hiddenView;
@property (weak, nonatomic) IBOutlet UIImageView *logoView;

@end

@implementation HMAuthorizationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [VKSdk initializeWithDelegate:self andAppId:VK_APP_ID];
    if ([VKSdk wakeUpSession])
    {
        [VKSdk authorize:@[VK_PER_FRIENDS, VK_PER_MESSAGES]];
    }
    self.hiddenView.alpha = 0.0;
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.6 animations:^{
        CGRect frame = weakSelf.logoView.frame;
        frame.origin.y = 71.00;
        weakSelf.logoView.frame = frame;
    }];
    [UIView animateWithDuration:0.6 delay:0.25 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.hiddenView.alpha = 1.0;
    } completion:nil
     ];
    
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
    [self showFriendsList];
}

@end
