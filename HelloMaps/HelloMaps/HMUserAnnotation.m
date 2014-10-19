//
//  UserAnnotation.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 19.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMUserAnnotation.h"

@implementation HMUserAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    if(self)
    {
        _coordinate = coordinate;
    }
    return self;
}

@end
