//  SessionTableView.h
//  TableViewFav

#import <UIKit/UIKit.h>
#import "Session.h"
#import "SpeakerTableView.h"
#import "ProgressHUD.h"

@class Reachability;
@interface SessionTableView : UITableViewController<UISearchBarDelegate, speakerDelegate> {
    NSManagedObjectContext *tableViewContext;
    NSMutableArray *mutableFetchResults;
    NSString *conferenceName;
    int rightButtonCalls;
    NSURL *usersURL, * sessionURL, *venueURL, *sponsorURL, *storeURL;
    NSTimeZone *conferenceTimeZone;
    NSTimer *reloadLabelTimer;
    IBOutlet UIButton* favButton;
    IBOutlet UILabel* titleLabel;
    IBOutlet UISearchBar* sessionSearchBar;
    ProgressHUD *delegate;
    bool isNotSyncing, problemWithData, isSearching, isDelegated, isReloadingLabels, isReloadingData;
    id delegater;
}
@property (nonatomic, retain) NSManagedObjectContext * tableViewContext;
@property (nonatomic, retain) NSMutableArray *mutableFetchResults;
@property (nonatomic, retain) NSString *conferenceName;
@property (nonatomic, retain) NSURL *usersURL;
@property (nonatomic, retain) NSURL *sessionURL;
@property (nonatomic, retain) NSURL *venueURL;
@property (nonatomic, retain) NSURL *sponsorURL;
@property (nonatomic, retain) NSURL *storeURL;
@property (nonatomic, retain) NSTimeZone *conferenceTimeZone;
@property (nonatomic, retain) IBOutlet UIButton* favButton;
@property (nonatomic, retain) IBOutlet UIButton* showOldSessionsButton;
@property (nonatomic, retain) IBOutlet UILabel* titleLabel;
@property (nonatomic, retain) IBOutlet UISearchBar* sessionSearchBar;
@property (nonatomic, assign) bool isNotSyncing, problemWithData, hideOldSessions, isSearching, isDelegated, isReloadingLabels, isReloadingData;
@property (nonatomic, assign) id delegater;
@property (nonatomic, retain) ProgressHUD *delegate;
- (void) showFav;
- (void) showHud;
- (void)checkButtonTapped:(id)sender event:(id)event;
- (void)reloadStream;
- (void) reloadXMLFilesWithBlock:(void (^)())reloadProcessBlock;
- (BOOL)connected;
- (NSString *) setDetailTextLabelForIndexPath:(NSIndexPath *)indexPath OrSession:(Session *)inputSession;
- (IBAction) speakerTableViewForcedUpdateBy:(id)sender;
@end
