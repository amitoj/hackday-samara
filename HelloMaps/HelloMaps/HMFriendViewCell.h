//
//  HMFriendViewCell.h
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HMFriendViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *avatarBackgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *radiusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *messangeIcon;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@end
