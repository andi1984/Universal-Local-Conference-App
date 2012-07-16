//  VenueViewController.h
//  ConferenceApp

#import <UIKit/UIKit.h>
#import "Venue.h"
#import "MapKit/MapKit.h"
@interface VenueViewController : UIViewController
{
    Venue* thisVenue;
}
@property(nonatomic, retain) Venue* thisVenue;

//Loading Outlets
@property (nonatomic, retain) IBOutlet MKMapView* venueMap; 
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, retain) IBOutlet UIButton *urlButton;
@property (nonatomic, retain) IBOutlet UIButton *floorPlanButton;
- (VenueViewController *) initWithVenue:(Venue *)initializeVenue;
- (IBAction)websiteButtonTapped:(UIButton *)sender;
- (IBAction)floorPlanButtonTapped:(UIButton *)sender;
@end
