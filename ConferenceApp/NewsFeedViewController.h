//  NewsFeedViewController.h
//  ConferenceApp

#import <UIKit/UIKit.h>

@interface NewsFeedViewController : UITableViewController
{
    NSMutableDictionary *newsItems;
    NSMutableArray *allItemReleaseDates;
    NSString *feedURLString;
    IBOutlet UIActivityIndicatorView *activityIndicator;
}
@property (nonatomic, retain) NSMutableDictionary *newsItems;
@property (nonatomic, retain) NSMutableArray *allItemReleaseDates;
@property (nonatomic, copy) NSString *feedURLString;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@end
