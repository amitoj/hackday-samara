//
//  HMFriendsListController.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMFriendsListController.h"
#import "VKSdk.h"
#import "AppDelegate.h"
#import "HMDataBase.h"
#import "UIImageView+AFNetworking.h"
#import "HMFriendViewCell.h"
#import "HMAuthorizationController.h"
#import "HMSessionManager.h"

@interface HMFriendsListController ()
@property (nonatomic, strong) NSMutableDictionary * cursors;
@property (nonatomic, strong) NSMutableArray * sections;
@end

@implementation HMFriendsListController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        self.cursors = [NSMutableDictionary new];
        self.sections = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Друзья";
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([HMFriendViewCell class]) bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 52.0, 0.0, 15.0);
}

- (void)refresh
{
    [self loadFriendsListFromVKWithRefresh:YES];
}

- (void)clearList
{
    [[HMDataBase sharedInstance] executeQueryWithSQL:@"DELETE FROM friends" args:nil];
    [self.cursors removeAllObjects];
    [self.sections removeAllObjects];
}

- (void)updateCursors
{
    [self.cursors removeAllObjects];
    [self.sections removeAllObjects];
    SQLite3Cursor * cursor = [[HMDataBase sharedInstance] rawQueryWithSQL:@"SELECT * FROM friends WHERE is_user = 1  AND last_name IS NOT NULL GROUP BY last_name ORDER BY first_name" args:nil windowSize:20];
    if(cursor.count > 0)
    {
        NSString * section = @"";
        [self.sections addObject:section];
        [self.cursors setObject:cursor forKey:section];
    }
    cursor = [[HMDataBase sharedInstance] rawQueryWithSQL:@"SELECT * FROM friends WHERE is_user = 0 AND last_name IS NOT NULL GROUP BY last_name ORDER BY first_name" args:nil windowSize:20];
    if(cursor.count > 0)
    {
        NSString * section = @"Друзья вне HelloMaps";
        [self.sections addObject:section];
        [self.cursors setObject:cursor forKey:section];
    }
}

- (void)loadFriendsListFromVKWithRefresh:(BOOL)isRefresh
{
    if([VKSdk isLoggedIn])
    {
        [self updateCursors];
        if (self.sections.count == 0 || isRefresh)
        {
            VKRequest * usersReq = [[VKApi friends] get];
            [usersReq executeWithResultBlock:^(VKResponse *response) {
                NSArray * friendsIds = [response.json objectForKey:@"items"];
                VKRequest * friendsReq = [[VKApi users] get:@{VK_API_USER_IDS : friendsIds, VK_API_FIELDS: VK_API_PHOTO}];
                [friendsReq executeWithResultBlock:^(VKResponse *response) {
                    if(isRefresh)
                    {
                        [self.refreshControl endRefreshing];
                    }
                    for (NSDictionary * friend in response.json)
                    {
                        [[HMDataBase sharedInstance] executeQueryWithSQL:@"INSERT OR REPLACE INTO friends (_id, first_name, last_name, photo_url) VALUES (?, ?, ?, ?)"
                                                                    args:@[friend[@"id"],
                                                                           friend[@"first_name"] ?: [NSNull null],
                                                                           friend[@"last_name"] ?: [NSNull null],
                                                                           friend[@"photo"] ?: [NSNull null]]];
                    }
                // запрос состояний друзей
                    [[HMSessionManager sharedInstance] getFriendsRadiusWithCompletionBlock:^(NSURLSessionDataTask *task, id responceObject1, NSError *error) {
                        if([responceObject1 isKindOfClass:[NSArray class]])
                        {
                            for (NSDictionary * friendInfo in responceObject1) {
                                [[HMDataBase sharedInstance] executeQueryWithSQL:@"UPDATE friends SET radius = ?, is_user = 1 WHERE _id = ?"
                                                                            args:@[@([friendInfo[@"radius"] intValue]),
                                                                                   friendInfo[@"id"]]];
                            }
                        }
                        [self updateCursors];
                        [self.tableView reloadData];
                    }];
                } errorBlock:^(NSError *error) {
                    NSLog(@"get frieds list error %@", error);
                }];
            } errorBlock:^(NSError *error) {
                NSLog(@"get frieds ids error %@", error);
            }];
        }
        else
        {
            [[HMSessionManager sharedInstance] getFriendsRadiusWithCompletionBlock:^(NSURLSessionDataTask *task, id responceObject, NSError *error) {
                if([responceObject isKindOfClass:[NSArray class]])
                {
                    for (NSDictionary * friendInfo in responceObject) {
                        [[HMDataBase sharedInstance] executeQueryWithSQL:@"UPDATE friends SET radius = ?, is_user = 1  WHERE _id = ?"
                                                                    args:@[@([friendInfo[@"radius"] intValue]),
                                                                           friendInfo[@"id"]]];
                    }
                }
                [self updateCursors];
                [self.tableView reloadData];
            }];
        }
    }
    else
    {
        UIViewController * rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        if([rootViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController * navController = (UINavigationController*)rootViewController;
            if(![navController.topViewController isKindOfClass:[HMAuthorizationController class]])
            {
                HMAuthorizationController * authorizationController = [navController.storyboard instantiateViewControllerWithIdentifier:@"HMAuthorizationController"];
                [navController setViewControllers:@[authorizationController] animated:YES];
            }
        }
    }
}

- (void)inviteButtonClick:(UIButton *)button
{
    CGPoint point = [self.tableView convertPoint:button.center fromView:button.superview];
    NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:point];
    NSString * section = [self.sections objectAtIndex:indexPath.section];
    SQLite3Cursor * cursor = [self.cursors objectForKey:section];
    NSDictionary *friend = [cursor itemAtIndex: indexPath.row];
    VKRequest * sendMessage = [VKRequest requestWithMethod:@"messages.send" andParameters:@{VK_API_USER_ID : friend[@"_id"], VK_API_MESSAGE : @"Привет, присоединяйся ко мне в приложении HelloMaps! ;)"} andHttpMethod:@"POST"];
    [sendMessage executeWithResultBlock:^(VKResponse *response) {
        
    } errorBlock:^(NSError *error) {
        NSLog(@"MESSAGE SEND ERROR");
    }];
}

#pragma mark Public methods

- (void)loadFriendsListFromVK
{
    [self loadFriendsListFromVKWithRefresh:NO];
}

#pragma mark - configure cell

- (UIColor *)colorForType:(NSNumber *)type
{
    UIColor * color = UIColorFromRGB(0x4EBC1B);
    if (![type isKindOfClass:[NSNull class]])
    {
        switch ([type intValue]) {
            case 1:
                color = UIColorFromRGB(0xF9D003);
                break;
            case 2:
                color = UIColorFromRGB(0xF96A00);
                break;
            case 3:
                color = UIColorFromRGB(0xF3E3E3);
                break;
            default:
                color = UIColorFromRGB(0x4EBC1B);
                break;
        }
    }
    return color;
}

- (void)configureCell:(HMFriendViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSString * section = [self.sections objectAtIndex:indexPath.section];
    SQLite3Cursor * cursor = [self.cursors objectForKey:section];
    NSDictionary *friend = [cursor itemAtIndex: indexPath.row];
    cell.nameLabel.text = [NSString stringWithFormat:@"%@ %@", [friend[@"first_name"] capitalizedString], [friend[@"last_name"] capitalizedString]];
    BOOL isUser = [friend[@"is_user"] boolValue];
    NSNumber * radius = friend[@"radius"];
    if(radius && isUser)
    {
        int r = [radius intValue];
        if(r < 1000)
        {
            cell.radiusLabel.text = [NSString stringWithFormat:@"%d м.", r];
        }
        else
        {
            cell.radiusLabel.text = [NSString stringWithFormat:@"%d км.", (int)(r/1000.0)];
        }
        
    }
    else
    {
        cell.radiusLabel.text = @"";
    }
    NSString* status = friend[@"status"];
    cell.messangeIcon.hidden = ([status isKindOfClass:[NSNull class]] || status.length == 0) && !isUser;
    NSNumber * type = friend[@"type"];

    cell.avatarBackgroundView.backgroundColor = isUser ? [self colorForType:type] : [UIColor whiteColor];
    
    NSString * photo = friend[@"photo_url"];
    NSURL * url = [NSURL URLWithString:photo];
    [cell.avatarImageView setImageWithURL:url];
    
    cell.inviteButton.hidden = isUser;
    [cell.inviteButton addTarget:self action:@selector(inviteButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = self.sections.count;
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString * sectionKey = [self.sections objectAtIndex:section];
    SQLite3Cursor * cursor = [self.cursors objectForKey:sectionKey];
    return [cursor getCount];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    HMFriendViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString * sectionKey = [self.sections objectAtIndex:section];
    if(sectionKey.length > 0)
    {
        UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 34.0)];
        titleLabel.text = sectionKey;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.backgroundColor = UIColorFromRGB(0xB3B3B3);
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0];
        return titleLabel;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 63.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString * sectionKey = [self.sections objectAtIndex:section];
    if(sectionKey.length > 0)
    {
        return 20.0;
    }
    return 0.0;
    
}


@end
