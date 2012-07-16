//  StreamViewController.h
//  simpleTwitter

#import <UIKit/UIKit.h>
#import "SingleTweet.h"

@interface StreamViewController : UITableViewController<UITableViewDelegate, showTweetProtocol> {
    NSMutableData *fetchedJSONData;
    NSMutableArray* fetchedTweets;
    NSURL* feedURL;
    BOOL firstRun;
    NSString *conferenceAcronym;
    NSString *highestTweetID;
    UIActivityIndicatorView *activityIndicator;
}
- (void) reloadTwitterFeed;
@property(nonatomic, retain) NSMutableData *fetchedJSONData;
@property(nonatomic, retain) NSMutableArray* fetchedTweets;
@property(nonatomic, retain) NSURL* feedURL;
@property(nonatomic, retain) NSString *highestTweetID;
@property(nonatomic, retain) NSString *conferenceAcronym;
@property(nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@end
