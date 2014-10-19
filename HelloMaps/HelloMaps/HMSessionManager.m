//
//  HMSessionManager.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 19.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMSessionManager.h"
#import "HMDataBase.h"

@implementation HMSessionManager

+(instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static id sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    return [self initWithBaseURL:[NSURL URLWithString:@"http://beardedfox.ru"] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

-(instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    return [self initWithBaseURL:[NSURL URLWithString:@"http://beardedfox.ru"] sessionConfiguration:configuration];
}

- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self)
    {
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        // success и failure будут выполняться в бэкграунде
        self.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

+ (NSString *)descriptionForRequest:(NSURLRequest *)request
{
    NSMutableString * description = [NSMutableString stringWithString:@"<<<"];
    [description appendFormat:@" URL : %@ ", request.URL];
    if ([request.HTTPMethod isEqualToString:@"POST"]) {
        [description appendFormat:@"BODY : %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]];
    }
    [description appendString:@">>>"];
    return description;
}

- (void) logTask:(NSURLSessionDataTask *)task
{
    NSLog(@"%@", [self.class descriptionForRequest:task.originalRequest]);
    NSLog(@"request header : %@", task.originalRequest.allHTTPHeaderFields);
}

- (NSURLSessionDataTask *) setUserDataWithCompletionBlock:(void (^)(NSURLSessionDataTask *task, NSError * error))completionBlock
{
    NSURLSessionDataTask * task = nil;
    NSDictionary * userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"user"];
    if(userInfo)
    {
        NSMutableDictionary * params = [NSMutableDictionary dictionary];
        params[@"id"] = userInfo[@"id"]? : @"";
        params[@"status"] = userInfo[@"status"]? : @"";
        params[@"type"] = userInfo[@"type"]? : @(0);
        params[@"latitude"] = userInfo[@"latitude"]? : @(0.0);
        params[@"longitude"] = userInfo[@"longitude"]? : @(0.0);
        params[@"radius"] = userInfo[@"radius"]? : @(500);
        task = [self POST:@"/set"
               parameters:params
                  success:^(NSURLSessionDataTask *task, id responseObject) {
                      NSLog(@"/set RESPONCE %@", responseObject);
                      completionBlock(task, nil);
                  } failure:^(NSURLSessionDataTask *task, NSError *error) {
                      NSLog(@"/set ERROR %@", error);
                      completionBlock(task, error);
                  }];
        [self logTask:task];
        
    }
    return task;
}

- (NSURLSessionDataTask *) getFriendsRadiusWithCompletionBlock:(void (^)(NSURLSessionDataTask *task, id responseObject, NSError * error))completionBlock
{
    NSURLSessionDataTask * task = nil;
    NSArray * friends = [[HMDataBase sharedInstance] arrayFromQueryWithSQL:@"SELECT _id FROM friends" args:nil];
    if(friends.count > 0)
    {
        friends = [friends valueForKeyPath:@"@unionOfObjects._id"];
        task = [self POST:@"/friends"
               parameters:@{@"id":friends}
                  success:^(NSURLSessionDataTask *task, id responseObject) {
                      NSLog(@"/friend RESPONCE %@", responseObject);
                      completionBlock(task, responseObject, nil);
                  } failure:^(NSURLSessionDataTask *task, NSError *error) {
                      NSLog(@"/friend ERROR %@", error);
                      completionBlock(task, nil, error);
                  }];
        [self logTask:task];
        
    }
    return task;
}

- (NSURLSessionDataTask *)getNearWithCompletionBlock:(void (^)(NSURLSessionDataTask *task, id responseObject, NSError * error))completionBlock
{
    NSURLSessionDataTask * task = nil;
    NSDictionary * userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"user"];
    if(userInfo)
    {
        NSMutableDictionary * params = [NSMutableDictionary dictionary];
        params[@"id"] = userInfo[@"id"]? : @"";
        params[@"status"] = userInfo[@"status"]? : @"";
        params[@"type"] = userInfo[@"type"]? : @(0);
        params[@"latitude"] = userInfo[@"latitude"]? : @(0.0);
        params[@"longitude"] = userInfo[@"longitude"]? : @(0.0);
        params[@"radius"] = userInfo[@"radius"]? : @(500);
        task = [self POST:@"/near"
               parameters:params
                  success:^(NSURLSessionDataTask *task, id responseObject) {
                      NSLog(@"/friend RESPONCE %@", responseObject);
                      if([responseObject isKindOfClass:[NSArray class]])
                      {
                          for (NSDictionary * item in responseObject) {
                              [[HMDataBase sharedInstance] executeQueryWithSQL:@"UPDATE friends SET latitude = ?, longitude = ? WHERE _id = ?"
                                                                          args:@[item[@"point"][@"latitude"]?:[NSNull null],
                                                                                 item[@"point"][@"longitude"]?:[NSNull null],
                                                                                 item[@"id"]]];
                          }
                      }
                      completionBlock(task, responseObject, nil);
                  } failure:^(NSURLSessionDataTask *task, NSError *error) {
                      NSLog(@"/friend ERROR %@", error);
                      completionBlock(task, nil, error);
                  }];
        [self logTask:task];
        
    }
    return task;
}

@end
