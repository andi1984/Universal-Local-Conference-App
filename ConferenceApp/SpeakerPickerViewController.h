//  SpeakerPickerViewController.h
//  ConferenceApp

#import <UIKit/UIKit.h>
@protocol SpeakerPickerViewControllerDelegate;
@interface SpeakerPickerViewController : UIViewController<UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, retain) IBOutlet UIPickerView* speakerPickerView;
@property (nonatomic, retain) IBOutlet UILabel* instructionLabel;
@property (nonatomic, retain) IBOutlet UIButton* cancelButton;
@property (nonatomic, retain) NSMutableArray *speakerViewSourceArray;
@property (nonatomic, retain) NSMutableArray *correspondingIDsArray;
@property (nonatomic, retain) NSManagedObjectContext *pickerViewContext;
@property (nonatomic, retain) NSString *conferenceName;
@property (nonatomic, retain) NSURL *storeURL;
@property (assign) id <SpeakerPickerViewControllerDelegate> delegate;

- (SpeakerPickerViewController *) initWithSessionID:(NSString *)initSessionID andContext:(NSManagedObjectContext *)initContext andConferenceName:(NSString *)targetedConference;
- (IBAction)abort:(UIButton *)sender;
@end

@protocol SpeakerPickerViewControllerDelegate
- (void) speakerPickerViewController:(SpeakerPickerViewController *)sender didChooseSpeakerWithID:(NSString *)chosenSpeakerID;
- (void) abortByPickerViewController:(SpeakerPickerViewController *)sender;
@end