//
//  HMProfileViewController.m
//  HelloMaps
//
//  Created by Макарычев Андрей on 19.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMProfileViewController.h"

@interface HMProfileViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profileEditBackgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *avatarView;
- (IBAction)removeTextAction:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation HMProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.profileEditBackgroundImageView.image = [[UIImage imageNamed:@"proofile_edit_background"] resizableImageWithCapInsets:UIEdgeInsetsMake(40, 40, 20, 100)];
    self.avatarView.layer.cornerRadius = self.avatarView.frame.size.height / 2;
}


- (IBAction)removeTextAction:(id)sender {
    self.textView.text = @"";
}

@end
