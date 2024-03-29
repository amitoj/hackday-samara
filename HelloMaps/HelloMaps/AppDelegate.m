//
//  AppDelegate.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "AppDelegate.h"
#import "VKSdk.h"
#import "HMAuthorizationController.h"
#import "HMMapViewController.h"
#import "HMSessionManager.h"
#import "HMLocationTracker.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UINavigationBar appearance] setBarTintColor:UIColorFromRGB(0x0084FD)];
    [VKSdk initializeWithDelegate:self andAppId:VK_APP_ID];
    if ([VKSdk wakeUpSession] && [VKSdk isLoggedIn])
    {
        UIViewController * rootViewController = [[self window] rootViewController];
        if([rootViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController * navController = (UINavigationController*)rootViewController;
            if(![navController.topViewController isKindOfClass:[HMMapViewController class]])
            {
                HMMapViewController * mapController = [navController.storyboard instantiateViewControllerWithIdentifier:@"HMMapViewController"];
                [navController setViewControllers:@[mapController] animated:NO];
            }
        }
        [NSTimer scheduledTimerWithTimeInterval:120.0 target:self selector:@selector(updateNearestFriends) userInfo:nil repeats:YES];
        
        
        if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey])
        {
            self.locationTracker = [[HMLocationTracker alloc] init];
            __weak HMLocationTracker *lc = self.locationTracker;
            __weak typeof(self) weakSelf = self;
            [self.locationTracker setLocationUpdatedInBackground:^(CLLocation *location) {
                //тестовый блок, будет показывать local notification с координатами
                UILocalNotification *notification = [[UILocalNotification alloc] init];
                notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:15];
                notification.alertBody = [NSString stringWithFormat:@"New location: %@", location];
                [[UIApplication sharedApplication] scheduleLocalNotification:notification];
                //отправка данных после входа в систему
                [[HMSessionManager sharedInstance] setUserDataWithCompletionBlock:^(NSURLSessionDataTask *task, NSError *error) {
                    [[HMSessionManager sharedInstance] getNearWithCompletionBlock:^(NSURLSessionDataTask *task, id responseObject, NSError *error) {
                        if([responseObject isKindOfClass:[NSArray class]])
                        {
                            [[weakSelf mapViewController] showUsers:responseObject];
                        }
                        [lc endBackgroundTask];
                    }];
                }];
                
            }];
            [self.locationTracker startUpdatingLocation];
        }
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"user"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return YES;
}

- (HMMapViewController *)mapViewController
{
    UIViewController * rootViewController = [[self window] rootViewController];
    if([rootViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController * navController = (UINavigationController*)rootViewController;
        if([navController.topViewController isKindOfClass:[HMMapViewController class]])
        {
            return (HMMapViewController *)navController.topViewController;
        }
    }
    return nil;
}

- (void)updateNearestFriends
{
    [[HMSessionManager sharedInstance] getNearWithCompletionBlock:^(NSURLSessionDataTask *task, id responseObject, NSError *error) {
        if([responseObject isKindOfClass:[NSArray class]])
        {
            [[self mapViewController] showUsers:responseObject];
        }
    }];
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [VKSdk processOpenURL:url fromApplication:sourceApplication];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
}

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "hackday.HelloMaps" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - VKSdkDelegate methods

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError;
{
    UIViewController * rootViewController = [[self window] rootViewController];
    if([rootViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController * navController = (UINavigationController*)rootViewController;
        VKCaptchaViewController * vc = [VKCaptchaViewController captchaControllerWithError:captchaError];
        [vc presentIn:navController.topViewController];
    }
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
    UIViewController * rootViewController = [[self window] rootViewController];
    if([rootViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController * navController = (UINavigationController*)rootViewController;
        if(![navController.topViewController isKindOfClass:[HMMapViewController class]])
        {
            HMMapViewController * mapController = [navController.storyboard instantiateViewControllerWithIdentifier:@"HMMapViewController"];
            [navController setViewControllers:@[mapController] animated:YES];
        }
    }
    
    VKRequest * userReq = [[VKApi users] get:@{VK_API_FIELDS: VK_API_PHOTO}];
    [userReq executeWithResultBlock:^(VKResponse *response) {
        [[NSUserDefaults standardUserDefaults] setObject:response.json[0] forKey:@"user"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } errorBlock:^(NSError *error) {
        
    }];
}

@end
