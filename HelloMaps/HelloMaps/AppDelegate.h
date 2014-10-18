//
//  AppDelegate.h
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "VKSdk.h"
@class HMLocationTracker;
@interface AppDelegate : UIResponder <UIApplicationDelegate, VKSdkDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) HMLocationTracker * locationTracker;

- (NSURL *)applicationDocumentsDirectory;

@end

