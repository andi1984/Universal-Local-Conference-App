//  AddConferenceViewController.h
//  ConferenceApp

#import <UIKit/UIKit.h>

@interface AddConferenceViewController : UIViewController<UITextFieldDelegate>
{
   IBOutlet UITextField* conferenceXMLUrlTextfield;
    NSManagedObjectContext* addContext;
}
@property (nonatomic, retain) UITextField* conferenceXMLUrlTextfield;
@property (nonatomic, retain) NSManagedObjectContext* addContext;
- (IBAction)pushAddConference:(id)sender;
@end
