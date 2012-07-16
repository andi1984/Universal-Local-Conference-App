//  SingleTweet.h
//  simpleTwitter


#import <UIKit/UIKit.h>
@protocol showTweetProtocol;
@interface SingleTweet : UIViewController{
    IBOutlet UIImageView* avatarView;
    IBOutlet UILabel* twitterNameLabel;
    IBOutlet UILabel* twitterURILabel;
    IBOutlet UIButton* abortButton;
    IBOutlet UIButton* replyButton;
    IBOutlet UIButton* retweetButton;
    IBOutlet UITextView* tweetView;
    
    NSData* myAvatarData;
    NSString* myTwitterName;
    NSString* myTwitterURI;
    NSString* myTweet;
    
}
- (SingleTweet *) initWithAvatarData:(NSData *) avatarData andTwitterName:(NSString *)twitterName andTwitterURI:(NSString *)twitterURI andTweetText:(NSString *)tweet;
- (IBAction)pressedAbort:(UIButton *)sender;
- (IBAction)reply:(UIButton *)sender;
- (IBAction)retweet:(UIButton *)sender;
@property (nonatomic, retain) IBOutlet UIImageView* avatarView;
@property (nonatomic, retain) IBOutlet UILabel* twitterNameLabel;
@property (nonatomic, retain) IBOutlet UILabel* twitterURILabel;
@property (nonatomic, retain) IBOutlet UITextView* tweetView;
@property (nonatomic, retain) IBOutlet UIButton* abortButton;
@property (nonatomic, retain) IBOutlet UIButton* replyButton;
@property (nonatomic, retain) IBOutlet UIButton* retweetButton;
@property (assign) id <showTweetProtocol> delegate;
@property (nonatomic, retain) NSData* myAvatarData;
@property (nonatomic, retain) NSString* myTwitterName;
@property (nonatomic, retain) NSString* myTwitterURI;
@property (nonatomic, retain) NSString* myTweet;
@end

@protocol showTweetProtocol
- (void) abortByTweetShow:(SingleTweet *)sender;
@end
