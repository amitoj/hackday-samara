//
//  HMSessionManager.h
//  HelloMaps
//
//  Created by Alexandr Khrulev on 19.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface HMSessionManager : AFHTTPSessionManager
+(instancetype)sharedInstance;

- (NSURLSessionDataTask *) setUserDataWithCompletionBlock:(void (^)(NSURLSessionDataTask *task, NSError * error))completionBlock;
- (NSURLSessionDataTask *) getFriendsRadiusWithCompletionBlock:(void (^)(NSURLSessionDataTask *task, id responseObject, NSError * error))completionBlock;
- (NSURLSessionDataTask *)getNearWithCompletionBlock:(void (^)(NSURLSessionDataTask *task, id responseObject, NSError * error))completionBlock;

@end
