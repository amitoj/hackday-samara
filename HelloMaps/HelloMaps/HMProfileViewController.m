//
//  HMProfileViewController.m
//  HelloMaps
//
//  Created by Макарычев Андрей on 19.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMProfileViewController.h"
#import "HMSessionManager.h"
#import "UIImageView+AFNetworking.h"

@interface HMProfileViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profileEditBackgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *avatarView;
- (IBAction)removeTextAction:(id)sender;
- (IBAction)saveProfileChangesBtn:(id)sender;
- (IBAction)selectItemAction:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *userDistance;
@property (weak, nonatomic) IBOutlet UIView *moodView;
@property (nonatomic) NSInteger moodType;
@end

@implementation HMProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.profileEditBackgroundImageView.image = [[UIImage imageNamed:@"proofile_edit_background"] resizableImageWithCapInsets:UIEdgeInsetsMake(40, 40, 20, 100)];
    //Ава
    self.avatarView.layer.cornerRadius = self.avatarView.frame.size.height / 2;
    self.view.backgroundColor = UIColorFromRGBA(0x0084FD, 0.7);
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.height / 2;
    NSDictionary * userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"user"];
    if (userInfo[@"photo"])
    {
        NSURL* avatarUrl = [NSURL URLWithString:userInfo[@"photo"]];
        [self.avatarImageView setImageWithURL:avatarUrl];
        
    }
    //Имя
    self.userName.text = [NSString stringWithFormat:@"%@ %@", [userInfo[@"first_name"] capitalizedString], [userInfo[@"last_name"] capitalizedString]];
    //Видимость
    self.userDistance.text = [userInfo[@"radius"] isKindOfClass:[NSNull class]] || !userInfo[@"radius"] ? @"" : [NSString stringWithFormat:@"Видимость %@.",userInfo[@"radius"]] ;
    //Статус
    self.textView.text = userInfo[@"status"];
    //Настроение
    if (userInfo[@"type"] && ![userInfo[@"type"] isKindOfClass:[NSNull class]])
    {
        for (UIButton* button in self.moodView.subviews)
        {
            if (button.tag == [userInfo[@"type"] integerValue])
            {
                button.selected = YES;
            }
        }
    }
    else
    {
        for (UIButton* button in self.moodView.subviews)
        {
            if (button.tag == 0)
            {
                button.selected = YES;
            }
        }
    }
}


- (IBAction)removeTextAction:(id)sender
{
    self.textView.text = @"";
}

- (IBAction)saveProfileChangesBtn:(id)sender
{
    NSMutableDictionary* userInfo = [[[NSUserDefaults standardUserDefaults] objectForKey:@"user"] mutableCopy];
    userInfo[@"status"] = self.textView.text.length > 0 ? self.textView.text : @"";
    userInfo[@"type"] = @(self.moodType);
    [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:@"user"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[HMSessionManager sharedInstance] setUserDataWithCompletionBlock:^(NSURLSessionDataTask *task, NSError *error) {
        if (error)
        {
            NSLog(@"/SET ERROR: %@", error);
        }
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)selectItemAction:(id)sender
{
    self.moodType = ((UIButton*)sender).tag;
    for (UIButton* button in ((UIButton*)sender).superview.subviews) {
        if ([button isKindOfClass:[UIButton class]])
        {
            button.selected = NO;
        }
    }
    
    
    ((UIButton*)sender).selected = YES;
}


@end
