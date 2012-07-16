//  MoreViewController.m
//  ConferenceApp

#import "MoreViewController.h"
#import "MapViewController.h"
#import "ShareOverviewController.h"
#import "SponsorTableView.h"
#import "NewsFeedViewController.h"
#import "Conference.h"

//Definition of all translation variables 

#define map_de @"Karte"
#define map_en @"Map"

#define sponsors_de @"Sponsoren"
#define sponsors_en @"Sponsors"

#define news_de @"Neuigkeiten"
#define news_en @"News"

#define no_news_resource_header_de @"Keine News-Quelle vorhanden"
#define no_news_resource_header_en @"No News-Resource"

#define no_news_resource_de @"Es wurde keine News-Quelle für die Veranstaltung festgelegt."
#define no_news_resource_en @"There is no news resource given by the conference organisation."

@implementation MoreViewController
@synthesize mapButton, shareButton, conferenceName, ourContext, sponsorButton;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)mapButtonPressed:(id)sender
{   
    //This method gets fired when the user clicks on the map icon (see MoreViewController.xib file)
    NSAutoreleasePool *releaseAllAutoreleaseObjects = [[NSAutoreleasePool alloc] init];
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    NSString* storeFileName = [NSString stringWithFormat:@"%@",self.conferenceName];
    NSURL *storeURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:storeFileName]];
    
    //First allocate and initiate a NSFetchRequest to get all 'Venue' entities which are stored in the specific conference's store.
    NSFetchRequest* whatPlacesAreThereRequest = [[NSFetchRequest alloc] init];
    [whatPlacesAreThereRequest setAffectedStores:[NSArray arrayWithObject:[[self.ourContext persistentStoreCoordinator] persistentStoreForURL:storeURL]]];
    whatPlacesAreThereRequest.entity = [NSEntityDescription entityForName:@"Venue" inManagedObjectContext:self.ourContext];
    
    //Prepare for request
    NSError* error;
    error = nil;
    
    //Get all venues, which will be represented as pins on the map in an array
    NSArray *allPins = [self.ourContext executeFetchRequest:whatPlacesAreThereRequest error:&error];
    [whatPlacesAreThereRequest release];
    NSLog(@"All-Pins Size: %i",[allPins count]);
    
    //Finally allocate and initiate a MapViewController
    MapViewController* mapView = [[MapViewController alloc] init];
    
    //Overtake the set with all pins
    mapView.pinArray = allPins;
    
    //Set the title
    mapView.title = map_en;
    
    //Push new view animated to the screen and hide navigation bar.
    [self.navigationController pushViewController:mapView animated:YES];
    [self.navigationController setNavigationBarHidden:NO];
    
    [mapView release];
    [releaseAllAutoreleaseObjects drain];
}

- (IBAction)shareButtonPressed:(id)sender
{
    //This method gets fired when the user clicks on the speech bubble icon on screen (see MoreViewController.xib file)
    
    //Simply setup a ShareOverviewController
    ShareOverviewController* shareView = [[ShareOverviewController alloc] init];
    
    //Set the context
    shareView.shareContext = self.ourContext;
    
    //... and the name of the conference
    shareView.conferenceName = self.conferenceName;
    
    //And finally push the new view on screen and hide navigation bar
    [self.navigationController pushViewController:shareView animated:YES];
    [self.navigationController setNavigationBarHidden:YES];
    [shareView release];
}

- (IBAction)sponsorButtonPressed:(id)sender
{
    //This method gets fired when the user clicks on the dollar icon (see MoreViewController.xib file)
    
    //Then simply setup a SponsorTableView, set name, title and context
    SponsorTableView *sponsorView = [[SponsorTableView alloc] init];
    sponsorView.conferenceName = self.conferenceName;
    sponsorView.sponsorViewContext = self.ourContext;
    sponsorView.title = sponsors_en;
    
    //And push it on screen
    [self.navigationController pushViewController:sponsorView animated:YES];
    [self.navigationController setNavigationBarHidden:YES];
    [sponsorView release];
}

- (IBAction)newsButtonPressed:(id)sender
{
    //This method gets fired when the user clicks on the rss icon to read the latest news
    
    //First allocate and initiate a request to get conference data
    NSFetchRequest *conferenceDataRequest = [[NSFetchRequest alloc] init];
    conferenceDataRequest.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.ourContext];
    conferenceDataRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
    NSError *requestError = nil;
    
    Conference *ourConference = [[self.ourContext executeFetchRequest:conferenceDataRequest error:&requestError] lastObject];
    if(!requestError)
    {
        if(ourConference.newsfeedurl != nil && ![ourConference.newsfeedurl isEqualToString:@""])
        {
            //If the conference has some newsfeed URL, allocate and initiate a NewsFeedViewController
            NewsFeedViewController *newsView = [[NewsFeedViewController alloc] init];
            
            //Set the title of the new view
            newsView.title = news_en;
            
            //Set the feed URL
            newsView.feedURLString = ourConference.newsfeedurl;
            
            //And push the new ViewController to the screen and hide the navigation bar
            [self.navigationController pushViewController:newsView animated:YES];
            [self.navigationController setNavigationBarHidden:NO];
            [newsView release];
        }
        else
        {
            //Else display a message, that newsfeed is not available at this conference.
            UIAlertView *noNewsFeed = [[UIAlertView alloc] initWithTitle:no_news_resource_header_en message:no_news_resource_en delegate:self cancelButtonTitle:@"Ok!" otherButtonTitles:nil, nil];
            [noNewsFeed show];
            [noNewsFeed release];
            NSLog(@"Keine feedURL angegeben!");
        }
    }
    [conferenceDataRequest release]; 
}
#pragma mark - View lifecycle
- (void) handleSwiping
{
    //If the user swipes to the left (means the user wants to get back), get one back on the view stack of the navigationController
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //Setup a swipe gesture recognizer and run handleSwiping method if swiping to the left is done.
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(handleSwiping)];
    
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeRecognizer];
    [swipeRecognizer release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.mapButton = nil;
    self.shareButton = nil;
    self.sponsorButton = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
   [self.navigationController setNavigationBarHidden:YES];
}
- (void)dealloc
{
    [mapButton release];
    [shareButton release];
    [conferenceName release];
    [ourContext release];
    [sponsorButton release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
