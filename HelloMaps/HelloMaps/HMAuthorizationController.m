//
//  ViewController.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMAuthorizationController.h"
#import "HMMapViewController.h"
#import "AFHTTPSessionManager.h"
#import "VKSdk.h"

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
    [VKSdk authorize:@[VK_PER_FRIENDS, VK_PER_MESSAGES]];
}


@end
