//  SpeakerViewController.h
//  ConferenceApp

#import <UIKit/UIKit.h>
#import "SessionPickerViewController.h"
@interface SpeakerViewController : UIViewController<SessionPickerViewControllerDelegate>
@property (nonatomic, retain) NSString* speakerID;
@property (nonatomic, retain) NSString* role;
@property (nonatomic, retain) NSString* speakerFirstName;
@property (nonatomic, retain) NSString* speakerLastName;
@property (nonatomic, retain) NSString* shortDescription;
@property (nonatomic, retain) NSNumber* age;
@property (nonatomic, retain) NSString* pictureURL;
@property (nonatomic, retain) NSString* homepageURL;
@property (nonatomic, retain) NSString* cvURL;
@property (nonatomic, retain) NSString* vcardURL;
@property (nonatomic, retain) NSSet* hasSessionsSet;
@property (nonatomic, retain) NSSet* hasTagsSet;
@property (nonatomic, retain) NSManagedObjectContext *speakerContext;
@property (nonatomic, retain) NSString *conferenceName;
@property (nonatomic, retain) NSURL *storeURL;


@property (nonatomic, retain) IBOutlet UIImageView* speakerImageView;
@property (nonatomic, retain) IBOutlet UILabel* speakerNameLabel;
@property (nonatomic, retain) IBOutlet UILabel* speakerAgeLabel;
@property (nonatomic, retain) IBOutlet UILabel* speakerTagsLabel;
@property (nonatomic, retain) IBOutlet UITextView* shortDescriptionLabel;
@property (nonatomic, retain) IBOutlet UIImageView* invitedView;
@property (nonatomic, retain) IBOutlet UIButton* vcardButton;
@property (nonatomic, retain) IBOutlet UIButton* cvButton;
@property (nonatomic, retain) IBOutlet UIButton* tagButton;
@property (nonatomic, retain) IBOutlet UIButton* homepageButton;
@property (nonatomic, retain) IBOutlet UITextView* sessionsLabel;
@property (nonatomic, retain) IBOutlet UIButton* moreAboutSessionsButton;
//Muss noch weitergeführt werden

- (SpeakerViewController *) initWithSpeakerID:(NSString*)inputID andManagedObjectContext:(NSManagedObjectContext*)inputContext andConference:(NSString *)targetedConferenceName;
- (IBAction) shareSpeaker:(UIButton *)sender;
- (IBAction) moreInformationAboutSessions:(UIButton *)sender;
@end
