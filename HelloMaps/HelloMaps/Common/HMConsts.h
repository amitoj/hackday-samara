//
//  HMConsts.h
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#define VK_APP_ID @"4594420"

// Макрос получения UIColor из hex-представления RGB цвета
#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0f \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0f \
blue:((float)(rgbValue & 0xFF))/255.0f alpha:1.0]

// Макрос получения UIColor из hex-представления RGB цвета с альфа-слоем
#define UIColorFromRGBA(rgbValue,aValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0f \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0f \
blue:((float)(rgbValue & 0xFF))/255.0f alpha:aValue]