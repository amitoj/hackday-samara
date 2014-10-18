//
//  ViewController.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMAuthorizationController.h"
#import "HMMapViewController.h"

@interface HMAuthorizationController ()
@property (weak, nonatomic) IBOutlet UIView *hiddenView;
@property (weak, nonatomic) IBOutlet UIImageView *logoView;

@end

@implementation HMAuthorizationController

- (void)viewDidLoad
{
    [super viewDidLoad];
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

- (void)showMainScreen
{
    UIViewController * rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    if([rootViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController * navController = (UINavigationController*)rootViewController;
        if(![navController.topViewController isKindOfClass:[HMMapViewController class]])
        {
            HMMapViewController * mapController = [navController.storyboard instantiateViewControllerWithIdentifier:@"HMMapViewController"];
            [navController setViewControllers:@[mapController] animated:YES];
        }
    }
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
    [self showMainScreen];
}

@end
