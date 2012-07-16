//  sessionPickerViewController.h
//  ConferenceApp


#import <UIKit/UIKit.h>
@protocol SessionPickerViewControllerDelegate;
@interface SessionPickerViewController : UIViewController<UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, retain) IBOutlet UIPickerView* sessionPickerView;
@property (nonatomic, retain) IBOutlet UILabel* instructionLabel;
@property (nonatomic, retain) IBOutlet UIButton* cancelButton;
@property (nonatomic, retain) NSMutableArray *sessionViewSourceArray;
@property (nonatomic, retain) NSMutableArray *correspondingIDsArray;
@property (nonatomic, retain) NSManagedObjectContext *pickerViewContext;
@property (nonatomic, retain) NSString *conferenceName;
@property (nonatomic, retain) NSURL *storeURL;
@property (assign) id <SessionPickerViewControllerDelegate> delegate;

- (SessionPickerViewController *) initWithSpeakerID:(NSString *)initSpeakerID andContext:(NSManagedObjectContext *)initContext andConferenceName:(NSString *)targetedConferenceName;
- (IBAction)abort:(UIButton *)sender;
@end

@protocol SessionPickerViewControllerDelegate
- (void) sessionPickerViewController:(SessionPickerViewController *)sender didChoosesessionWithID:(NSString *)chosensessionID;
- (void) abortByPickerViewController:(SessionPickerViewController *)sender;
@end