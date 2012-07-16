//  JSONFlickrViewController.h
//  FlickrJSonApp

#import <UIKit/UIKit.h>

@interface JSONFlickrViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>
{
    NSString* FlickrAPIKey;
    NSMutableArray  *photoTitles;         // Titles of images
    NSMutableArray  *photoSmallImageData; // Image data (thumbnail)
    NSMutableArray  *photoURLsLargeImage; // URL to larger image
    IBOutlet UITableView *theTableView;
    IBOutlet UIImageView *theImageView;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    IBOutlet UIScrollView *theScrollView;
    NSString* searchString;
}
- (JSONFlickrViewController *) initWithSearchString:(NSString *)search;
@property (nonatomic, retain) IBOutlet UITableView* theTableView;
@property (nonatomic, retain) IBOutlet UIImageView* theImageView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UIScrollView *theScrollView;
@property (nonatomic, retain) NSString *searchString;
@end
