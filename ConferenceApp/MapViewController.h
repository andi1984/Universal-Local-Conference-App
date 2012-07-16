//  MapViewController.h
//  PinMap

#import "UIKit/UIKit.h"
#import "MapKit/MapKit.h"

@interface MapViewController : UIViewController<CLLocationManagerDelegate ,MKMapViewDelegate, UIAlertViewDelegate>{
    NSMutableData *fetchedJSONData;
    IBOutlet MKMapView *mapView;
    NSArray* pinArray;
    UIActivityIndicatorView *activityIndicator;
    CLLocationManager* locationManager;
}
@property (nonatomic, retain) MKMapView *mapView;
@property (nonatomic, retain) NSArray* pinArray;
@property (nonatomic, retain) NSMutableData *fetchedJSONData;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) CLLocationManager *locationManager;
@end

