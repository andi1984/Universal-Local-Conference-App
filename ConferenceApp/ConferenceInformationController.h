//  ConferenceInformationController.h
//  ConferenceApp


#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
@interface ConferenceInformationController : UITableViewController<EKEventEditViewDelegate>
{
    NSMutableArray *conferenceData;
    NSMutableArray *sectionHeaders;
    NSManagedObjectContext *conferenceContext;
    NSString *conferenceName;
    UIImage *conferenceLogoImage;
}
@property (nonatomic, retain) NSMutableArray *conferenceData, *sectionHeaders;
@property (nonatomic, retain) NSManagedObjectContext *conferenceContext;
@property (nonatomic, retain) NSString *conferenceName;
@property (nonatomic, retain) UIImage *conferenceLogoImage;
- (UIImage *) makeThumbnailFromImage:(UIImage *)bigImage ToSize:(CGSize)size;
@end
