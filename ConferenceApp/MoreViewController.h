//  MoreViewController.h
//  ConferenceApp

#import <UIKit/UIKit.h>

@interface MoreViewController : UIViewController
{
    IBOutlet UIButton* mapButton;
    IBOutlet UIButton* shareButton;
    IBOutlet UIButton* sponsorButton;
    NSString *conferenceName;
    NSManagedObjectContext *ourContext;
}
@property (nonatomic,retain) IBOutlet UIButton* mapButton;
@property (nonatomic, retain) IBOutlet UIButton* shareButton;
@property (nonatomic, retain) IBOutlet UIButton* sponsorButton;
@property (nonatomic, retain) NSString *conferenceName;
@property (nonatomic, retain) NSManagedObjectContext *ourContext;
- (IBAction)mapButtonPressed:(id)sender;
- (IBAction)shareButtonPressed:(id)sender;
- (IBAction)newsButtonPressed:(id)sender;
@end
