//  SpeakerTableView.h
//  ConferenceApp

#import <UIKit/UIKit.h>
#import "ProgressHUD.h"
@protocol speakerDelegate;
@interface SpeakerTableView : UITableViewController<UISearchBarDelegate>
{
    NSManagedObjectContext *speakerViewContext;
    NSMutableArray *speakerFetchResults;
    NSMutableDictionary *speakerImageFetchResults;
    NSString *conferenceName;
    NSURL *storeURL;
    IBOutlet UISearchBar* speakerSearchBar;
    ProgressHUD *progessDelegate;
    bool isSearching;
}
@property (nonatomic, retain) NSManagedObjectContext *speakerViewContext;
@property (nonatomic, retain) NSMutableArray *speakerFetchResults;
@property (nonatomic, retain) NSMutableDictionary *speakerImageFetchResults;
@property (nonatomic, retain) NSString *conferenceName;
@property (nonatomic, retain) NSURL *storeURL;
@property (nonatomic, retain) IBOutlet UISearchBar* speakerSearchBar;
@property (assign) id <speakerDelegate> delegate;
@property (nonatomic, retain) ProgressHUD *progessDelegate;
- (IBAction) updateIsFinished;
@end

@protocol speakerDelegate
- (IBAction) speakerTableViewForcedUpdateBy:(id)sender;
@end
