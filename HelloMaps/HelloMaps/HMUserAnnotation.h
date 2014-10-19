//
//  UserAnnotation.h
//  HelloMaps
//
//  Created by Alexandr Khrulev on 19.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>

@interface HMUserAnnotation : NSObject <MKAnnotation>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
@end
