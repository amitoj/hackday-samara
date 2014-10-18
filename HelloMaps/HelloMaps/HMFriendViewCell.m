//
//  HMFriendViewCell.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMFriendViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation HMFriendViewCell

- (void)awakeFromNib {
    self.avatarBackgroundView.layer.cornerRadius = truncf(self.avatarBackgroundView.frame.size.width / 2.0);
    self.avatarImageView.layer.cornerRadius = truncf(self.avatarImageView.frame.size.width / 2.0);
    self.avatarImageView.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
