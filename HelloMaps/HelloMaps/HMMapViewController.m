//
//  HMMapViewController.m
//  HelloMaps
//
//  Created by Макарычев Андрей on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMMapViewController.h"
#import "HMFriendsListController.h"
#import "HMLocationTracker.h"
#import "HMSessionManager.h"
#import "HMUserAnnotation.h"
#import "UIImageView+AFNetworking.h"
#import "UIButton+AFNetworking.h"
#import "HMDataBase.h"

@interface HMMapViewController ()
{
    BOOL _isControlViewShown;
    CGFloat _yPosition;
    CGFloat _blueViewWidth;
    NSArray * _radiusAvailableValues;
}
@property (weak, nonatomic) IBOutlet UILabel *blueViewLabel;
@property (weak, nonatomic) IBOutlet UIView *fingerPlaceView;
@property (weak, nonatomic) IBOutlet UISlider *radiusSlider;
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (weak, nonatomic) IBOutlet UIView *blueView;
@property (weak, nonatomic) IBOutlet UILabel *notificationsCountLabel;
@property (nonatomic) CGFloat radius;
@property (weak, nonatomic) IBOutlet UIView *avatarView;
@property (nonatomic, strong) NSMutableArray * anotations;

@property (nonatomic, strong) HMLocationTracker *locationTracker;
@end

@implementation HMMapViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        self.radius = 0.0;
        NSMutableArray * values = [NSMutableArray array];
        for (int i = 0; i < 2000; i+=50) {
            [values addObject:@(i)];
        }
        _radiusAvailableValues = values;
        self.anotations = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.fingerPlaceView.layer.cornerRadius = 21.0;
    self.notificationsCountLabel.clipsToBounds = YES;
    self.notificationsCountLabel.layer.cornerRadius = 9.0;
    _isControlViewShown = NO;
    _blueViewWidth = self.blueView.frame.size.width;
    self.locationManager = [[CLLocationManager alloc] init];
    self.mapView.delegate = self;
    self.locationManager.delegate = self;
#ifdef __IPHONE_8_0
    if(IS_OS_8_OR_LATER) {
        // Use one or the other, not both. Depending on what you put in info.plist
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
#endif
    [self.locationManager startUpdatingLocation];
    
    NSInteger numberOfSteps = [_radiusAvailableValues count] - 1;
    self.radiusSlider.maximumValue = numberOfSteps;
    self.radiusSlider.minimumValue = 0;
    self.radiusSlider.continuous = YES;
    self.radiusSlider.value = self.radius;
    [self updateRadiusLabel:self.radius];
    
    self.mapView.showsUserLocation = YES;
    [self.mapView setMapType:MKMapTypeStandard];
    [self.mapView setZoomEnabled:YES];
    [self.mapView setScrollEnabled:YES];
    
    
    self.locationTracker = [[HMLocationTracker alloc] init];
    [self.locationTracker setLocationUpdatedInForeground:^ (CLLocation *location) {
        [[HMSessionManager sharedInstance] setUserDataWithCompletionBlock:^(NSURLSessionDataTask *task, NSError *error) {
        }];
    }];
    [self.locationTracker setLocationUpdatedInBackground:^ (CLLocation *location) {
        [[HMSessionManager sharedInstance] setUserDataWithCompletionBlock:^(NSURLSessionDataTask *task, NSError *error) {
        }];
    }];
    self.locationManager.distanceFilter = kCLDistanceFilterNone; //Whenever we move
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationTracker startUpdatingLocation];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.avatarView.layer.cornerRadius = self.avatarView.frame.size.height / 2;
    NSDictionary * userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"user"];
    if (userInfo[@"photo"])
    {
        NSURL* avatarUrl = [NSURL URLWithString:userInfo[@"photo"]];
        NSURLRequest* avatarRequest = [NSURLRequest requestWithURL:avatarUrl];
        [((UIButton*)self.avatarView.subviews[0]) setImageForState:UIControlStateNormal withURLRequest:avatarRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            UIButton* button = ((UIButton*)self.avatarView.subviews[0]);
            UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
            [button addSubview:imageView];
            imageView.frame = button.bounds;
            imageView.layer.cornerRadius = imageView.frame.size.height / 2;
            imageView.clipsToBounds = YES;
        } failure:^(NSError *error) {
            NSLog(@"ERROR: %@", error);
        }];
        
        [((UIButton*)self.avatarView.subviews[0]) setImageForState:UIControlStateNormal withURL:avatarUrl];
        
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //View Area
    MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = self.locationManager.location.coordinate.latitude;
    region.center.longitude = self.locationManager.location.coordinate.longitude;
    region.span.longitudeDelta = 0.005f;
    region.span.longitudeDelta = 0.005f;
    [self.mapView setRegion:region animated:YES];
    
    CGRect frame = self.bottomControlView.frame;
    _yPosition = frame.origin.y;
    
    [self updateCirclePosition];
}

- (void)updateRadiusLabel:(NSInteger) radius
{
    //    if(radius >= 1000)
    //    {
    //        self.blueViewLabel.text = [NSString stringWithFormat:@"%d км.", (int)(radius/1000)];
    //    }
    //    else
    //    {
    self.blueViewLabel.text = [NSString stringWithFormat:@"%d м.", (int)radius];
    //    }
}

-(void)updateCirclePosition
{
    [self.mapView removeOverlays: [self.mapView overlays]];
    
    MKCircle * circle = [MKCircle circleWithCenterCoordinate:self.mapView.userLocation.location.coordinate radius:self.radius];
    [self.mapView addOverlay:circle];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    [self updateCirclePosition];
}

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

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"user"];
        if(!annotationView) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"user"];
            annotationView.canShowCallout = NO;
            annotationView.image = [UIImage imageNamed:@"12"];
        }
        return annotationView;
    }
    else if ([annotation isKindOfClass:[HMUserAnnotation class]])
    {
        NSDictionary * user = ((HMUserAnnotation *)annotation).userInfo;
        if(user[@"photo_url"])
        {
            MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"friend"];
            if(!annotationView) {
                annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"friend"];
                annotationView.canShowCallout = NO;
            }
            
            UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 24.0, 24.0)];
            view.layer.cornerRadius = 12.0;
            view.backgroundColor = [self colorForType:user[@"type"]];
            
            UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(2.0, 2.0, 20.0, 20.0)];
            imageView.layer.cornerRadius = 12.0;
            imageView.clipsToBounds = YES;
            [imageView setImageWithURL:[NSURL URLWithString:user[@"photo_url"]]];
            [view addSubview:imageView];
            
            annotationView.frame = view.bounds;
            [annotationView addSubview:view];
            
            return annotationView;
        }
        return nil;
    }
    return nil;
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKCircle class]]){
        MKCircle *circle = (MKCircle *)overlay;
        MKCircleRenderer *circleR = [[MKCircleRenderer alloc] initWithCircle:circle];
        circleR.fillColor = UIColorFromRGB(0x0084FD);
        circleR.alpha = 0.5;
        return circleR;
    } else{
        return nil;
    }
}

- (NSString *)deviceLocation {
    return [NSString stringWithFormat:@"latitude: %f longitude: %f", self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude];
}
- (NSString *)deviceLat {
    return [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.latitude];
}
- (NSString *)deviceLon {
    return [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.longitude];
}
- (NSString *)deviceAlt {
    return [NSString stringWithFormat:@"%f", self.locationManager.location.altitude];
}

- (void)showUsers:(NSArray *)users
{
    [self.mapView removeAnnotations:self.anotations];
    [self.anotations removeAllObjects];
    
    NSArray * ids = [users valueForKeyPath:@"@unionOfObjects.id"];
    NSString * query = [NSString stringWithFormat:@"SELECT * FROM friends WHERE _id IN ('%@')", [ids componentsJoinedByString:@"', '"]];
    NSArray * friends = [[HMDataBase sharedInstance] arrayFromQueryWithSQL:query args:nil];
    for (NSDictionary * user in friends)
    {
        CLLocationCoordinate2D coor = CLLocationCoordinate2DMake([user[@"latitude"] doubleValue], [user[@"longitude"] doubleValue]);
        HMUserAnnotation *annotation = [[HMUserAnnotation alloc] initWithCoordinate:coor];
        annotation.userInfo = user;
        [self.anotations addObject:annotation];
    }
    [self.mapView addAnnotations:self.anotations];
    
}
#pragma mark - Touch Events

-(void)animateControlView
{
    CGFloat duration = 0.3;
    CGRect frame = self.bottomControlView.frame;
    CGRect blueFrame = self.blueView.frame;
    __weak typeof(self) weakSelf = self;
    if  (_isControlViewShown)
    {
        frame.origin.y = _yPosition;
        blueFrame.size.width = _blueViewWidth;
        blueFrame.origin.x = CGRectGetMidX(self.bottomControlView.frame) - CGRectGetMidX(blueFrame);
        [UIView animateWithDuration:duration animations:^{
            weakSelf.bottomControlView.frame = frame;
        } completion:^(BOOL finished) {
        }];
        [UIView animateWithDuration:duration delay:duration options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.blueView.frame = blueFrame;
        } completion:nil];
    }
    else
    {
        frame.origin.y = _yPosition - 51.0;
        blueFrame.size.width = self.bottomControlView.frame.size.width;
        blueFrame.origin.x = 0.0;
        [UIView animateWithDuration:duration animations:^{
            weakSelf.bottomControlView.frame = frame;
        } completion:^(BOOL finished) {
        }];
        [UIView animateWithDuration:duration delay:duration options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.blueView.frame = blueFrame;
        } completion:nil];
    }
    _isControlViewShown = !_isControlViewShown;
}

#pragma mark - Actions

- (IBAction)zoomIn:(id)sender {
    MKCoordinateRegion region = self.mapView.region;
    region.span.latitudeDelta /= 2.0;
    region.span.longitudeDelta /= 2.0;
    [self.mapView setRegion:region animated:YES];
}

- (IBAction)zoomOut:(id)sender {
    MKCoordinateRegion region = self.mapView.region;
    region.span.latitudeDelta  = MIN(region.span.latitudeDelta  * 2.0, 180.0);
    region.span.longitudeDelta = MIN(region.span.longitudeDelta * 2.0, 180.0);
    [self.mapView setRegion:region animated:YES];
}

- (IBAction)friendsListOpen:(id)sender
{
    HMFriendsListController * friendsListController = [HMFriendsListController new];
    [friendsListController loadFriendsListFromVK];
    [self.navigationController pushViewController:friendsListController animated:YES];
}

- (void) updateUsersInfo
{
    __weak typeof(self)weakSelf = self;
    [[HMSessionManager sharedInstance] setUserDataWithCompletionBlock:^(NSURLSessionDataTask *task, NSError *error) {
        [[HMSessionManager sharedInstance] getNearWithCompletionBlock:^(NSURLSessionDataTask *task, id responseObject, NSError *error) {
            if([responseObject isKindOfClass:[NSArray class]])
            {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                if(strongSelf)
                {
                    [weakSelf showUsers:responseObject];
                }
            }
        }];
    }];
}

- (IBAction)sliderShowBtClick:(id)sender
{
    [self animateControlView];
}

- (IBAction)sliderValueChange:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateUsersInfo) object:nil];
    NSUInteger index = (NSUInteger)(self.radiusSlider.value + 0.5);
    [self.radiusSlider setValue:index animated:NO];
    NSNumber *number = _radiusAvailableValues[index];
    NSInteger radius = [number intValue];
    //    [self updateRadiusLabel:radius];
    self.radius = radius;
    [self updateCirclePosition];
    
    [self performSelector:@selector(updateUsersInfo) withObject:nil afterDelay:3.0];
}

@end
