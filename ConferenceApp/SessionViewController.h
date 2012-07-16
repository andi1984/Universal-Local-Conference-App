//  SessionViewController.h
//  ConferenceApp

#import <UIKit/UIKit.h>
#import "SpeakerPickerViewController.h"
#import "Venue.h"
#import <EventKitUI/EventKitUI.h>
@interface SessionViewController : UIViewController<SpeakerPickerViewControllerDelegate, EKEventEditViewDelegate>
{  
    
}

@property (nonatomic, retain) IBOutlet UILabel* sessionTitleLabel;
@property (nonatomic, retain) IBOutlet UILabel* sessionTagsLabel;
@property (nonatomic, retain) IBOutlet UILabel* sessionDateLabel;
@property (nonatomic, retain) IBOutlet UITextView* descriptionLabel;
@property (nonatomic, retain) IBOutlet UIButton* favedButton;
@property (nonatomic, retain) IBOutlet UIButton* speakerButton;
@property (nonatomic, retain) IBOutlet UIButton* venueButton;
@property (nonatomic, retain) IBOutlet UIButton* addEventButton;
@property (nonatomic, retain) IBOutlet UIButton* tagButton;
@property (nonatomic, retain) IBOutlet UILabel* speakersLabel;
@property (nonatomic, retain) IBOutlet UILabel* venueAndRoomLabel;
@property (nonatomic, retain) NSString* conferenceName;
@property (nonatomic, retain) NSURL* storeURL;

@property (nonatomic, retain) NSManagedObjectContext* objectContext;


@property (nonatomic, retain) NSString* sessionTitleString;
@property (nonatomic, retain) NSString* sessionDescriptionString;
@property (nonatomic, retain) NSSet* sessionSpeakerSet;
@property (nonatomic, retain) NSSet* sessionTagSet;
@property (nonatomic, retain) NSDate* sessionNSDate;
@property (nonatomic, retain) NSDate* sessionStartTime;
@property (nonatomic, retain) NSString* sessionID;
@property (nonatomic, retain) NSString* roomNameString;
@property (nonatomic, retain) NSString *sessionDuration;
@property (nonatomic, retain) Venue* venueOfTheSession;


-  (SessionViewController *) initWithSessionID:(NSString *)inputSessionID andManagedObjectContext:(NSManagedObjectContext *)context andConference:(NSString *)targetedConferenceName;

- (IBAction) changeFavState:(UIButton *)sender;
- (IBAction) moreInformationAboutSpeaker:(UIButton *)sender;
- (IBAction) moreInformationAboutVenue:(UIButton *)sender;
- (IBAction) shareSession:(UIButton *)sender;
- (IBAction) addToiOSCalendar:(UIButton *)sender;
@end
