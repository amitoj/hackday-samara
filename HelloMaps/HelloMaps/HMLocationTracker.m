//
//  HMLocationTracker.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 19.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMLocationTracker.h"
#import <UIKit/UIKit.h>

static CGFloat const kMinUpdateDistance = 10.0;
static NSTimeInterval const kMinUpdateTime = 90.0;
static NSTimeInterval const kMaxTimeToLive = 30.0;

static NSString *const kArchivedLocationKey = @"com.HelloMaps.Defaults.ArchivedLocation";

@interface HMLocationTracker () {
@private
    UIBackgroundTaskIdentifier bgTask;
}
@end

@implementation HMLocationTracker

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:    UIApplicationDidEnterBackgroundNotification object:nil];
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager requestWhenInUseAuthorization];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification handlers

- (void)applicationDidBecomeActive {
    [self.locationManager stopMonitoringSignificantLocationChanges];
    [self.locationManager startUpdatingLocation];
}

- (void)applicationDidEnterBackground {
    [self.locationManager stopUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
}

#pragma mark - Public

- (void)startUpdatingLocation {
    [self stopUpdatingLocation];
    [self isInBackground] ? [self.locationManager startMonitoringSignificantLocationChanges] : [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)endBackgroundTask {
    if (bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
}
#pragma mark - Private

- (BOOL)isInBackground {
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
}

#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    if (oldLocation && ([newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp] < kMinUpdateTime ||
                        [newLocation distanceFromLocation:oldLocation] < kMinUpdateDistance)) {
        return;
    }
    
    NSMutableDictionary * userInfo = [[[NSUserDefaults standardUserDefaults] objectForKey:@"user"] mutableCopy];
    userInfo[@"latitude"] = @(newLocation.coordinate.latitude);
    userInfo[@"longitude"] = @(newLocation.coordinate.longitude);
    [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:@"user"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if ([self isInBackground]) {
        if (self.locationUpdatedInBackground) {
            bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^{
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            }];
            
            self.locationUpdatedInBackground(newLocation);
//            [self endBackgroundTask];
        }
    } else {
        if (self.locationUpdatedInForeground) {
            self.locationUpdatedInForeground(newLocation);
        }
    }
}

@end
