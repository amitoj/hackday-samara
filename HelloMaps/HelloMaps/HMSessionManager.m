//
//  HMSessionManager.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 19.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMSessionManager.h"

@interface HMHTTPRequestSerializer : AFHTTPRequestSerializer

@end

@implementation HMHTTPRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);
    
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    
    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];
    
    if (parameters) {
        NSString *query = nil;
        NSMutableArray * params = [NSMutableArray array];
        for (id param in [parameters allKeys]) {
            [params addObject:[NSString stringWithFormat:@"\"%@\":\"%@\"", param, [parameters objectForKey:param]]];
        }
        if(params.count > 0)
        {
            query = [NSString stringWithFormat:@"\"item={%@}\"", [params componentsJoinedByString:@","]];
        }
        [mutableRequest setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return mutableRequest;
}

@end


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
        self.requestSerializer = [HMHTTPRequestSerializer serializer];;
        
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
        task = [self POST:@"/set"
               parameters:userInfo
                  success:^(NSURLSessionDataTask *task, id responseObject) {
                      NSLog(@"/set RESPONCE %@", responseObject);
                      completionBlock(task, nil);
                  } failure:^(NSURLSessionDataTask *task, NSError *error) {
                      NSLog(@"/set ERROR %@", error);
                      completionBlock(task, nil);
                  }];
        [self logTask:task];
        
    }
    return task;
}

@end
