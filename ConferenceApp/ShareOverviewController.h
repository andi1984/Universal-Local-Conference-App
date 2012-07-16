//  ShareOverviewController.h
//  ConferenceApp

#import <UIKit/UIKit.h>

@interface ShareOverviewController : UIViewController
{
    IBOutlet UIButton *shareButtonGeneral, *twitterWallButton, *flickrImagesButton;
    NSManagedObjectContext *shareContext;
    NSString *conferenceName;
}
@property (nonatomic, retain) UIButton *shareButtonGeneral, *twitterWallButton, *flickrImagesButton;
@property (nonatomic, retain) NSManagedObjectContext *shareContext;
@property (nonatomic, retain) NSString *conferenceName;
- (IBAction)shareButtonIsPressed:(id)sender;
- (IBAction)twitterWallButtonIsPressed:(id)sender;
- (IBAction)flickrImagesButtonIsPressed:(id)sender;
@end
