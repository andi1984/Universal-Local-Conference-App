//  ShareOverviewController.m
//  ConferenceApp

#import "ShareOverviewController.h"
#import "StreamViewController.h"
#import "JSONFlickrViewController.h"
#import "Conference.h"
#import "SHK.h"

#define twitter_stream_de @"Twitter-Nachrichten"
#define twitter_stream_en @"Twitterstream"

#define images_de @"Bilder"
#define images_en @"Images"

#define no_hashtag_header_de @"Kein Schlagwort angegeben"
#define no_hashtag_header_en @"No Hashtag"

#define no_hashtag_de @"Für die Konferenz wurde kein Schlagwort definiert um danach zu suchen."
#define no_hashtag_en @"The conference has no hashtag to search for."

@implementation ShareOverviewController
@synthesize shareButtonGeneral, flickrImagesButton, twitterWallButton, conferenceName, shareContext;
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

#pragma mark - View lifecycle
- (IBAction)shareButtonIsPressed:(id)sender
{
    //This method gets called when the user clicks on the share button
    
    //First get informations about the conference by setting up a NSFetchRequest
    NSFetchRequest* getAllNeededData = [[NSFetchRequest alloc] init];
    getAllNeededData.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.shareContext];
    getAllNeededData.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
    
    NSError *fetchingAllDataError = nil;;
    Conference* ourConference = [[[self.shareContext executeFetchRequest:getAllNeededData error:&fetchingAllDataError] lastObject] retain];
    
    if(!fetchingAllDataError && ourConference != nil)
    {
        //If conference exists
        if(ourConference.acronym != nil && ![ourConference.acronym isEqualToString:@""])
        {
            //If hashtag exists
            //Create the item to share (in this example the acronym)
            SHKItem *item = [SHKItem text:[NSString stringWithFormat:@"#%@",ourConference.acronym]];
            
            // Get the ShareKit action sheet
            SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
            
            // Display the action sheet
            [actionSheet showInView:self.view];
        }
        else
        {
            // Create the item to share (in this example a blank textfield)
            SHKItem *item = [SHKItem text:@""];
            
            // Get the ShareKit action sheet
            SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
            
            // Display the action sheet
            [actionSheet showInView:self.view];
        }
    }
    else
    {
        // Create the item to share (in this example a blank textfield)
        SHKItem *item = [SHKItem text:@""];
        
        // Get the ShareKit action sheet
        SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
        
        // Display the action sheet
        [actionSheet showInView:self.view];
    }
    [ourConference release];
    [getAllNeededData release];
}

- (IBAction)twitterWallButtonIsPressed:(id)sender
{
    //This method gets called when the user clicks on the twitterwall button
    
    //First get conference details with a NSFetchRequest
    NSFetchRequest *conferenceDataRequest = [[NSFetchRequest alloc] init];
    conferenceDataRequest.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.shareContext];
    conferenceDataRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
    NSError *requestError = nil;
    
    Conference *ourConference = [[self.shareContext executeFetchRequest:conferenceDataRequest error:&requestError] lastObject];
    [conferenceDataRequest release];
    
    if(!requestError)
    {
        if(ourConference.acronym != nil && ![ourConference.acronym isEqualToString:@""])
        {
            //If the conference has an acronym, set up (allocate and init) a StreamViewController instance
            StreamViewController* twitterStream = [[StreamViewController alloc] init];
            twitterStream.conferenceAcronym = [ourConference.acronym stringByReplacingOccurrencesOfString:@" " withString:@""];//Cut out blank characters
            twitterStream.conferenceAcronym = [twitterStream.conferenceAcronym stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //Use UTF8 encoding
            NSLog(@"%@",twitterStream.conferenceAcronym);
            
            //Set title of view
            twitterStream.title = twitter_stream_en;
            
            //Show view on screen and hide navigation bar
            [self.navigationController pushViewController:twitterStream animated:YES];
            [twitterStream release];
            [self.navigationController setNavigationBarHidden:NO];
        }
        else
        {
            //Else if there is no acronym send a message to the user.
            UIAlertView *noHashtagGiven = [[UIAlertView alloc] initWithTitle:no_hashtag_header_en message:no_hashtag_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [noHashtagGiven show];
            [noHashtagGiven release];
        }
    }
    else
    {
        NSLog(@"Problem beim Transferrieren der Konferenz-Daten in ShareOverview - Twitterwall");
    }
}

- (IBAction)flickrImagesButtonIsPressed:(id)sender
{
    //This method gets called when the user clicks on the flickr gallery button
    
    //First get conference details
    NSFetchRequest *conferenceDataRequest = [[NSFetchRequest alloc] init];
    conferenceDataRequest.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.shareContext];
    conferenceDataRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
    NSError *requestError = nil;
    
    Conference *ourConference = [[self.shareContext executeFetchRequest:conferenceDataRequest error:&requestError] lastObject];
    [conferenceDataRequest release];
    if(!requestError)
    {
        if(ourConference.acronym != nil && ![ourConference.acronym isEqualToString:@""])
        {
            //If the conference has an acronym, set up a JSONFlickrViewController instance
            JSONFlickrViewController* flickrView = [[JSONFlickrViewController alloc] initWithSearchString:[[ourConference.acronym stringByReplacingOccurrencesOfString:@" " withString:@""] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];//blank characters are removed from acronym because of URL extension reasons
            
            //Set up the view title
            flickrView.title = images_en;
            
            //Push the view to the screen and hide navigation bar.
            [self.navigationController pushViewController:flickrView animated:YES];
            [flickrView release];
            [self.navigationController setNavigationBarHidden:YES];
        }
        else
        {
            //If there is no acronym (hashtag) given, send a message to the user.
            UIAlertView *noHashtagGiven = [[UIAlertView alloc] initWithTitle:no_hashtag_header_en message:no_hashtag_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [noHashtagGiven show];
            [noHashtagGiven release];
        }
    }
    else
    {
        NSLog(@"Problem beim Transferrieren der Konferenz-Daten in ShareOverview - Flickr");
    }
}

- (void) handleSwiping
{
    //Get back to the previous view in navigationController view stack.
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //Add a swipe gesture recognizer to be able to get back to the last screen by a swipe gesture to the left. handleSwiping method is fired then.
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(handleSwiping)];
    
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeRecognizer];
    [swipeRecognizer release];
}

- (void)dealloc
{
    [shareButtonGeneral release];
    [twitterWallButton release];
    [flickrImagesButton release];
    [conferenceName release];
    [shareContext release];
    [super dealloc];
}
- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.shareButtonGeneral = nil;
    self.twitterWallButton = nil;
    self.flickrImagesButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
