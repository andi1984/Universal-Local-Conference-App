//  WelcomeViewController.h
//  ConferenceApp

#import <UIKit/UIKit.h>

@interface WelcomeViewController : UIViewController
{
    IBOutlet UITextView* welcomeTextView;
}
@property (nonatomic, copy) NSString *welcome_message, *welcome_video;
- (void) initWelcomeViewWithMessage:(NSString *)message AndVideoUrl:(NSString *)videourl;
- (void)embedYouTube:(NSString *)urlString frame:(CGRect)frame;
@end
