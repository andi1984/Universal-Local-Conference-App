//  SponsorTableView.h
//  ConferenceApp

#import <UIKit/UIKit.h>

@interface SponsorTableView : UITableViewController
{
    NSManagedObjectContext *sponsorViewContext;
    NSMutableArray *sponsorFetchResults;
    NSMutableDictionary *sponsorImageResults;
    NSString *conferenceName;
    NSURL *storeURL;
}
@property (nonatomic, retain) NSManagedObjectContext* sponsorViewContext;
@property (nonatomic, retain) NSMutableArray *sponsorFetchResults;
@property (nonatomic, retain) NSMutableDictionary *sponsorImageResults;
@property (nonatomic, retain) NSString *conferenceName;
@property (nonatomic, retain) NSURL *storeURL;
- (UIImage *) makeThumbnailFromImage:(UIImage *)bigImage ToSize:(CGSize)size;
@end
