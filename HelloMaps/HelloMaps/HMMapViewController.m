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

@interface HMMapViewController ()
{
    BOOL _isControlViewShown;
    CGFloat _offsetY;
    CGFloat _yPosition;
    CGFloat _newYPosition;
    CGFloat _firstTouchPositionY;
    CGRect _blueViewFrame;
    BOOL _isAnimationEnded;
}
@property (weak, nonatomic) IBOutlet UILabel *blueViewLabel;
@property (weak, nonatomic) IBOutlet UIView *fingerPlaceView;
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (weak, nonatomic) IBOutlet UIView *blueView;
@property (weak, nonatomic) IBOutlet UILabel *notificationsCountLabel;

@property (nonatomic, strong) HMLocationTracker *locationTracker;
@end

@implementation HMMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.fingerPlaceView.layer.cornerRadius = 21.0;
    self.notificationsCountLabel.clipsToBounds = YES;
    self.notificationsCountLabel.layer.cornerRadius = 9.0;
    _isControlViewShown = NO;
    _isAnimationEnded = YES;
    _offsetY = 0;
    CGRect frame = self.bottomControlView.frame;
    _yPosition = frame.origin.y;
    _newYPosition = frame.origin.y;
    _blueViewFrame = self.blueView.frame;
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
    [self.locationTracker startUpdatingLocation];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.locationManager.distanceFilter = kCLDistanceFilterNone; //Whenever we move
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
    NSLog(@"%@", [self deviceLocation]);
    
    //View Area
    MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
    region.center.latitude = self.locationManager.location.coordinate.latitude;
    region.center.longitude = self.locationManager.location.coordinate.longitude;
    region.span.longitudeDelta = 0.005f;
    region.span.longitudeDelta = 0.005f;
    [self.mapView setRegion:region animated:YES];
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
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

#pragma mark - Touch Events
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    _firstTouchPositionY = touchLocation.y;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    NSLog(@"%f", touchLocation.y);
    for (UIView *view in self.view.subviews)
    {
        if (view == self.bottomControlView &&
            CGRectContainsPoint(view.frame, touchLocation))
        {
            _offsetY = touchLocation.y - _firstTouchPositionY;
            
            CGRect frame = self.bottomControlView.frame;
            if (!_isControlViewShown)
            {
                _offsetY = _offsetY > 0.0 ? 0.0 : _offsetY;
                _offsetY = _offsetY < -51.0 ? -51.0 : _offsetY;
            }
            else
            {
                _offsetY = _offsetY > 51.0 ? 51.0 : _offsetY;
                _offsetY = _offsetY < 0.0 ? 0.0 : _offsetY;
            }
            NSLog(@"%hhd, %f",_isControlViewShown, _offsetY);
            frame.origin.y = _newYPosition + _offsetY;
            self.bottomControlView.frame = frame;
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    __weak typeof(self) weakSelf = self;
    if (!_isControlViewShown)
    {
        _isControlViewShown =  _offsetY == -51.0 ? YES : [self animateControlView];
        _newYPosition = _yPosition - 51.0;
        if (_isControlViewShown)
        {
            _isAnimationEnded = NO;
            [UIView animateWithDuration:0.3 animations:^{
                CGRect newFrame = CGRectMake(0, _blueViewFrame.origin.y, weakSelf.bottomControlView.frame.size.width, _blueViewFrame.size.height);
                weakSelf.blueView.frame = newFrame;
            } completion:^(BOOL finished){
                _isAnimationEnded = YES;
            }];
        }
    }
    else
    {
        _isControlViewShown  = _offsetY == 51.0 ? NO : [self animateControlView];
        _newYPosition = _yPosition;
        if (!_isControlViewShown)
        {
            _isAnimationEnded = NO;
            [UIView animateWithDuration:0.3 animations:^{
                weakSelf.blueView.frame = _blueViewFrame;
            } completion:^(BOOL finished){
                _isAnimationEnded = YES;
            }];
        }
    }
    _offsetY = 0.0;
}

-(BOOL)animateControlView
{
    _isAnimationEnded = NO;
    CGFloat duration = 0.3;
    BOOL result = YES;
    CGRect frame = self.bottomControlView.frame;
    __weak typeof(self) weakSelf = self;
    if  (_isControlViewShown)
    {
        frame.origin.y = _yPosition;
        result = NO;
        [UIView animateWithDuration:duration animations:^{
            weakSelf.bottomControlView.frame = frame;
        } completion:^(BOOL finished) {
            _isAnimationEnded = YES;
        }];
        [UIView animateWithDuration:duration delay:duration options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.blueView.frame = _blueViewFrame;
        } completion:nil];
    }
    else
    {
        frame.origin.y = _yPosition - 51.0;
        [UIView animateWithDuration:duration animations:^{
            weakSelf.bottomControlView.frame = frame;
        } completion:^(BOOL finished) {
            _isAnimationEnded = YES;
        }];
        [UIView animateWithDuration:duration delay:duration options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect newFrame = CGRectMake(0, _blueViewFrame.origin.y, weakSelf.bottomControlView.frame.size.width, _blueViewFrame.size.height);
            weakSelf.blueView.frame = newFrame;
        } completion:nil];
    }
    return result;
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

@end
