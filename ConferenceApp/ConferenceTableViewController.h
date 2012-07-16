//  ConferenceTableViewController.h
//  ConferenceApp


#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface ConferenceTableViewController : UITableViewController{
    
    NSManagedObjectContext *conferenceContext;    
    NSMutableArray *fetchedConferencesResult;
}

@property (nonatomic, retain) NSManagedObjectContext *conferenceContext;
@property (nonatomic, retain) NSMutableArray *fetchedConferencesResult;
@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) MBProgressHUD *reloadHud;
- (void)addConference;
@end
