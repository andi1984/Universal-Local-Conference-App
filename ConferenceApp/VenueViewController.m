//  VenueViewController.m
//  ConferenceApp

#import "VenueViewController.h"
#import "Venue.h"
#import "MapKit/MapKit.h"
@implementation VenueViewController
@synthesize thisVenue;
@synthesize venueMap;
@synthesize titleLabel;
@synthesize descriptionTextView;
@synthesize urlButton, floorPlanButton;
-(void)dealloc
{
    [thisVenue release];
    [venueMap release];
    [descriptionTextView release];
    [titleLabel release];
    [urlButton release];
    [floorPlanButton release];
    [super dealloc];
}
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
- (VenueViewController *) initWithVenue:(Venue *)initializeVenue
{
    //This is the initialize method
    self.thisVenue = initializeVenue;
    return self;
}
- (void) handleSwipeLeft
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) changeMapType
{
    for (UIRotationGestureRecognizer* recognizer in [self.view gestureRecognizers]) {
        if(recognizer.state == UIGestureRecognizerStateEnded)
        {
            NSLog(@"Bin drin!");
            if(self.venueMap.mapType == MKMapTypeStandard)
                self.venueMap.mapType = MKMapTypeSatellite;
            else
                self.venueMap.mapType = MKMapTypeStandard;
        }
    }
}
- (IBAction)websiteButtonTapped:(UIButton *)sender
{
    //Open website url after website button is clicked
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: thisVenue.websiteurl]];
}
- (IBAction)floorPlanButtonTapped:(UIButton *)sender
{
    //Open online floorplan after floorplan button is clicked
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: thisVenue.floorplan]];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //After view did load
    
    //First configure buttons
    
    //Hide floorplan buttons
    self.floorPlanButton.alpha = 0.0;
    self.floorPlanButton.enabled = FALSE;
    
    //Hide website URL buttons
    self.urlButton.alpha = 0.0;
    self.urlButton.enabled = FALSE;
    
    //Add a swipe gesture recognizer to recognize a swipe to the left (to get back)
    UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft)];
    swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeftRecognizer];
    [swipeLeftRecognizer release];
    
    //Add a rotation gesture recognizer
    UIRotationGestureRecognizer* rotationForChangingMapType = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(changeMapType)];
    [self.view addGestureRecognizer:rotationForChangingMapType];
    [rotationForChangingMapType release];
    
    //Set up a CLLocationCoordinate2D
    CLLocationCoordinate2D annotationCoord;

    //Add longitude and latitude
    annotationCoord.latitude = [thisVenue.latitude doubleValue];
    annotationCoord.longitude = [thisVenue.longitude doubleValue];
    
    //Build a pin for the map
    MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
    annotationPoint.coordinate = annotationCoord;
    annotationPoint.title = thisVenue.name;
    annotationPoint.subtitle = thisVenue.websiteurl;
    
    //Add a region around the pin
    //self.mapView.region = MKCoordinateRegionMakeWithDistance(annotationPoint.coordinate, 200, 200);
    
    //Add pin to the map
    [self.venueMap addAnnotation:annotationPoint];
    
    //Set map type to MKMapSatellite (change map type by rotate two fingers
    self.venueMap.mapType = MKMapTypeSatellite;
    [annotationPoint release];
}

- (BOOL) isFileAtURLReachable:(NSURL *)fileURL 
{
    //Checks whether file is reachable online.
    NSMutableURLRequest *userFileRequest = [[NSMutableURLRequest alloc] initWithURL:fileURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [userFileRequest setHTTPMethod:@"PUT"];
    NSHTTPURLResponse *urlResponse;
    NSError *error;
    [NSURLConnection sendSynchronousRequest:userFileRequest returningResponse:&urlResponse error:&error];
    [userFileRequest release];
    if(urlResponse.statusCode == 404 || urlResponse.statusCode == 106)
        return false;
    else
        return true;
}

-(void)viewWillAppear:(BOOL)animated
{
    //Before view appears, set title label
    [self.titleLabel setText:self.thisVenue.name];
    
    //Set map region to show a frame around venue pin on map
    self.venueMap.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake([thisVenue.latitude doubleValue], [thisVenue.longitude doubleValue]), MKCoordinateSpanMake(0.001, 0.001));
    
    //If the venue has a website
    if(thisVenue.websiteurl != nil && ![thisVenue.websiteurl isEqualToString:@""])
    {
        //Build website url in background without blocking main thread
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //Baue URL
            NSURL *venueURL = [[NSURL alloc] initWithString:thisVenue.websiteurl];
            BOOL goodVenueURL = [self isFileAtURLReachable:venueURL];
            dispatch_async( dispatch_get_main_queue(), ^{
                if(goodVenueURL)
                {
                    [self.urlButton setTitle:thisVenue.websiteurl forState:UIControlStateNormal];
                    self.urlButton.alpha = 1.0;
                    self.urlButton.enabled = TRUE;
                }

                
            });
            [venueURL release];
        });
    }
    
    //If venue has a floorplan
    if(thisVenue.floorplan != nil && ![thisVenue.floorplan isEqualToString:@""])
    {
        //Build floorplan url in background 
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //Baue URL
            NSURL *floorPlanURL =[[NSURL alloc] initWithString:thisVenue.floorplan];
            BOOL goodFloorPlanURL = [self isFileAtURLReachable:floorPlanURL];
            dispatch_async( dispatch_get_main_queue(), ^{
                if(goodFloorPlanURL)
                {
                    //Sofern kein 404 Error bei obiger URL, gebe Button frei
                    self.floorPlanButton.alpha = 1.0;
                    self.floorPlanButton.enabled = YES;
                }

            });
            [floorPlanURL release];
        });       
    }
    
    //If venue has a info text
    if(thisVenue.infotext != nil && ![thisVenue.infotext isEqualToString:@""])
    {
        NSString* infoText = @"";
        
        //Get all single components by separate text by string "\\". Then Add all components and add a line break \n between them
        NSArray* componentsOfContactString = [thisVenue.infotext componentsSeparatedByString:@"\\"];
        for (NSString* singleComponent in componentsOfContactString) {
            NSLog(@"Single Component: %@ \n",singleComponent);
            if(![[singleComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
            {
                infoText = [infoText stringByAppendingString:[singleComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                infoText = [infoText stringByAppendingString:@" \n"];
            }
        }
        self.descriptionTextView.text = infoText;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.venueMap = nil;
    self.titleLabel = nil;
    self.urlButton = nil;
    self.descriptionTextView = nil;
    self.floorPlanButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
