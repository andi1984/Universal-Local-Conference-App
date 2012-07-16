//  mapViewController.m
//  PinMap

#import "MapViewController.h"
#import "MapKit/MapKit.h"
#import "Venue.h"
#import "JSONKit.h"

@implementation MapViewController
static NSString *clientID = @"TFOOMAYJFUPMSR35TDWFJWISENUFIDPKCB3TY325GIIG13YI";
static NSString *clientSecret = @"40R1T2AGIL2QH2U2UEKI5UYIRWODTVVJJ0VEJRXGTJPD24O4"; 
@synthesize mapView, pinArray, fetchedJSONData, activityIndicator, locationManager;
//minLong, minLat, maxLong, maxLat;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"Dealloc is called!");
    
    //Release of all foursquare pin labels
    
    for (id annotation in self.mapView.annotations) {
        BOOL isFoursquarePin =true;
        for (id annotationInArray in self.pinArray) {
            if([[annotation title] isEqualToString:[annotationInArray name]])
                isFoursquarePin = false;
        }
        
        if(isFoursquarePin)
        {
            [annotation setTitle:nil];
            [annotation setSubtitle:nil];
        }
    }
    
    [mapView release];
    [pinArray release];
    [fetchedJSONData release];
    [activityIndicator release];
    [locationManager release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
/*- (void)loadView
{   
}*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void) changeMapType
{
    //Method gets called during rotation gesture. If rotation is done, map type gets changed between Satellite and Standard map type
    for (UIRotationGestureRecognizer* recognizer in [self.view gestureRecognizers]) {
        if(recognizer.state == UIGestureRecognizerStateEnded)
        {
            if(self.mapView.mapType == MKMapTypeStandard)
                self.mapView.mapType = MKMapTypeSatellite;
            else
                self.mapView.mapType = MKMapTypeStandard;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //If position of user changed
    
    //Save new location
    CLLocationCoordinate2D coord = {.latitude =  newLocation.coordinate.latitude, .longitude =  newLocation.coordinate.longitude};
    
    //Create a new pin there
    MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
    annotationPoint.coordinate = coord;
    annotationPoint.title = @"Current Location";
    
    //Add pin to map
    [self.mapView addAnnotation:annotationPoint];
    [annotationPoint release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
	{
        //If user has agreed to access his position start updating location...
		[locationManager startUpdatingLocation];
	}
    else
    {
        //... else stop it
        [locationManager stopUpdatingLocation];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Add a rotation gesture recognizer to this view
    UIRotationGestureRecognizer* rotationForChangingMapType = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(changeMapType)];
    [self.view addGestureRecognizer:rotationForChangingMapType];
    [rotationForChangingMapType release];
    
    //Add store to store coordinator
    CGSize size = self.view.frame.size;
    self.mapView =[[[MKMapView alloc] initWithFrame:CGRectMake(0,0, size.width, size.height)] autorelease];
    self.mapView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.delegate = self;
    
    [self.view addSubview:self.mapView];
    
    //Set up a activity indicator displaying update process while downloading data from foursquare
    self.activityIndicator = [[[UIActivityIndicatorView alloc] init] autorelease];
    self.activityIndicator.frame = CGRectMake(self.view.frame.size.width - 40.0, 0.0, 40.0, 40.0);
    [self.activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    UIBarButtonItem* rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    [rightBarButtonItem release];
    
    //Allocate and initiate mutable json data.
    self.fetchedJSONData = [[[NSMutableData alloc] init] autorelease];
    [self.fetchedJSONData setLength:0];
    
    //Configure location manager and current position accuracy to navigation quality
    self.locationManager.distanceFilter = kCLDistanceFilterNone; 
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.locationManager.delegate = self;
    
    //Show an alert to the user whether he wants to activate geo detection or not.
    UIAlertView *alert = [[UIAlertView alloc] init];
	[alert setTitle:@"Allow Geo Detection"];
	[alert setMessage:@"Do you want to allow detection of your geo position?"];
	[alert setDelegate:self];
	[alert addButtonWithTitle:@"Yes, I want!"];
	[alert addButtonWithTitle:@"No, I don't want!"];
	[alert show];
	[alert release];
}

- (void) viewWillDisappear:(BOOL)animated
{
     //Löschen der Annotationpoints
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    //This method declares style for pins
    
    //Differentiate between conference venues (red pins) and foursquare data (green pins)
    
    BOOL isInConferenceVenueList = false;
    
    for(Venue* currentVenue in self.pinArray)
    {
        if([currentVenue.name isEqualToString:[annotation title]])
            isInConferenceVenueList = true;
    }
    
    //If pin does not display a conference venue it has to be a venue from foursquare data, hence set the styling.
    if(!isInConferenceVenueList)
    {
        MKPinAnnotationView *pin = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: @"foursquare"];
        if (pin == nil)
        {
            pin = [[[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"foursquare"] autorelease];
        }
        else
        {
            pin.annotation = annotation;
        }
        
        pin.pinColor = MKPinAnnotationColorGreen;
        pin.animatesDrop = NO;
        pin.canShowCallout = true;
        return pin;
    }
    else
    {
        //If the pin displays conference venue
        MKPinAnnotationView *pin = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: @"conferencevenues"];
        if (pin == nil)
        {
            pin = [[[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"conferencevenues"] autorelease];
        }
        else
        {
            pin.annotation = annotation;
        }
        pin.pinColor = MKPinAnnotationColorRed;
        pin.animatesDrop = NO;
        pin.canShowCallout = true;
        return pin;
    }
    
    
}
- (void) addingMethod:(id)annotation
{
    [self.mapView addAnnotation:annotation];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //If connection is established

    //Start downloading foursquare data in background thread, hence start activityIndicator
    [self.activityIndicator startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
        // Store incoming data into a string
        NSData *jsonString = [[[NSData alloc] initWithData:self.fetchedJSONData] autorelease];
        
        //Clear fetchedJSONData storage
        [self.fetchedJSONData setLength:0];
    
        //Set up a JSON decoder
        JSONDecoder *jsonDecoder = [JSONDecoder decoder];
        
        for (int i=0; i<[[NSArray arrayWithArray:[[[NSArray arrayWithArray:[[NSDictionary dictionaryWithDictionary:[[NSDictionary dictionaryWithDictionary:[jsonDecoder objectWithData:jsonString]] objectForKey:@"response"]] objectForKey:@"groups"]] lastObject] objectForKey:@"items"]] count]; i++)
        {
            NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
            
            CLLocationCoordinate2D annotationCoord;
            
            MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
                        
            NSDictionary *singleVenue = [NSDictionary dictionaryWithDictionary:[[NSDictionary dictionaryWithDictionary:[[NSArray arrayWithArray:[[[NSArray arrayWithArray:[[NSDictionary dictionaryWithDictionary:[[NSDictionary dictionaryWithDictionary:[jsonDecoder objectWithData:jsonString]] objectForKey:@"response"]] objectForKey:@"groups"]] lastObject] objectForKey:@"items"]] objectAtIndex:i]] objectForKey:@"venue"]];

            
            NSDictionary *oneCategory = [[[NSDictionary dictionaryWithDictionary:[[NSDictionary dictionaryWithDictionary:[[NSArray arrayWithArray:[[[NSArray arrayWithArray:[[NSDictionary dictionaryWithDictionary:[[NSDictionary dictionaryWithDictionary:[jsonDecoder objectWithData:jsonString]] objectForKey:@"response"]] objectForKey:@"groups"]] lastObject] objectForKey:@"items"]] objectAtIndex:i]] objectForKey:@"venue"]] objectForKey:@"categories"] lastObject];
            
            if(oneCategory != nil)
            {
                NSString* catName = [[[[NSDictionary dictionaryWithDictionary:[[NSDictionary dictionaryWithDictionary:[[NSArray arrayWithArray:[[[NSArray arrayWithArray:[[NSDictionary dictionaryWithDictionary:[[NSDictionary dictionaryWithDictionary:[jsonDecoder objectWithData:jsonString]] objectForKey:@"response"]] objectForKey:@"groups"]] lastObject] objectForKey:@"items"]] objectAtIndex:i]] objectForKey:@"venue"]] objectForKey:@"categories"] lastObject] objectForKey:@"shortName"];
                
                
                //If the foursquare venue has a category, set it as subtitle of the pin
                if(![catName isEqualToString:@""] && catName !=nil)
                    [annotationPoint setSubtitle:catName];
            }
            
                      
            //Set venue name as main title of the pin
            [annotationPoint setTitle:[singleVenue objectForKey:@"name"]];
            
            
            
            //Read out location data of foursquare venue
            NSDictionary *locationOfVenue = [NSDictionary dictionaryWithDictionary:[singleVenue objectForKey:@"location"]];
            
            annotationCoord.latitude = [[locationOfVenue objectForKey:@"lat"] doubleValue];
            
            annotationCoord.longitude = [[locationOfVenue objectForKey:@"lng"] doubleValue];
            
            annotationPoint.coordinate = annotationCoord;
            
            //Add venue to map
            [self performSelectorOnMainThread:@selector(addingMethod:) withObject:annotationPoint waitUntilDone:NO];
            
            [annotationPoint release];
            [innerPool drain];
        }
        [outerPool drain];
         dispatch_async(dispatch_get_main_queue(), ^{
             //Stop acitivty indicator
             [self.activityIndicator stopAnimating];             
         });
        });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //Append new loaded JSON data
   [self.fetchedJSONData appendData:data];
}
- (void)viewWillAppear:(BOOL)animated
{    
    NSAutoreleasePool* washAllAway = [[NSAutoreleasePool alloc] init];

    if([self.pinArray count])
    {
        //If at least one venue is specified in conference data...
        double minLong, maxLong, minLat, maxLat;
        bool firstVenue = true;
        for (Venue* currentPlace in self.pinArray) 
        {
            //For all venues, check whether longitude AND latitude values are given
            if(currentPlace.longitude != nil && currentPlace.latitude != nil)
            {
                //If this is the first processed value, set all variables to the properties of this venue
                if(firstVenue)
                {
                    minLong = [currentPlace.longitude doubleValue];
                    maxLong = [currentPlace.longitude doubleValue];
                    minLat = [currentPlace.latitude doubleValue];
                    maxLat = [currentPlace.latitude doubleValue];
                    firstVenue = false;
                }
                else
                {
                    //If it's not the first value, check whether variables should be set to new values
                    
                    if([currentPlace.longitude doubleValue]  < minLong)
                    {
                        minLong = [currentPlace.longitude doubleValue];
                    }
                    if([currentPlace.longitude doubleValue] > maxLong)
                    {
                        maxLong = [currentPlace.longitude doubleValue];
                    }
                    if([currentPlace.latitude doubleValue]  < minLat)
                    {
                        minLat = [currentPlace.latitude doubleValue];
                    }
                    if([currentPlace.latitude doubleValue] > maxLat)
                    {
                        maxLat = [currentPlace.latitude doubleValue];
                    }
                }
                
                //Create a annotation coordinate
                CLLocationCoordinate2D annotationCoord;
                annotationCoord.latitude = [currentPlace.latitude doubleValue];
                annotationCoord.longitude = [currentPlace.longitude doubleValue];
                
                //Create a pin for the map
                MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
                annotationPoint.coordinate = annotationCoord;
                annotationPoint.title = [currentPlace.name autorelease];
                annotationPoint.subtitle = [currentPlace.websiteurl autorelease];
                
                //Add it to the map
                [self.mapView addAnnotation:annotationPoint];
                [annotationPoint release];

        
            //Add a region frame which is displayed around all conference pins
            if((maxLat == minLat) && (maxLong == minLong))
            {        
                NSLog(@"Alle Max Werte sind gleich!");
                self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(maxLat, maxLong), MKCoordinateSpanMake(0.2, 0.2));
            }
            else if(maxLong == minLong)
            {
                NSLog(@"Longitude ist gleich groß!");
                self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(minLat + (maxLat - minLat)/2, maxLong), MKCoordinateSpanMake((maxLat  - minLat), 0));
            }
            else if(maxLat == minLat)
            {
                NSLog(@"Latitude ist gleich groß!");
                self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(maxLat, minLong + (maxLong - minLong)/2), MKCoordinateSpanMake(0, (maxLong - minLong)));
            }
            else
            {
                NSLog(@"Alles unterschiedlich!");
                self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(minLat + (maxLat  - minLat)/2, minLong + (maxLong - minLong)/2), MKCoordinateSpanMake((maxLat - minLat), (maxLong - minLong)));
            }
        }
    }
  }
    [self.fetchedJSONData setLength:0];
    for (Venue *currentVenue in self.pinArray) {
        //For each conference venue search for interesting venues around it (max. distance 50 km and max. 250 venues)
        NSDate *dateNow = [NSDate date];
        NSDateFormatter *formatDateToVAttribute = [[NSDateFormatter alloc] init];
        [formatDateToVAttribute setDateFormat:@"YYYYMMDD"];
        NSString *vAttribute = [formatDateToVAttribute stringFromDate:dateNow];
        [formatDateToVAttribute release];
        NSLog(@"v-Attribut %@",vAttribute);
        NSString *foursquareAPIString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/explore?ll=%@,%@&client_id=%@&client_secret=%@&v=%@&radius=50000&limit=250", [NSString stringWithFormat:@"%f",[currentVenue.latitude doubleValue]], [NSString stringWithFormat:@"%f",[currentVenue.longitude doubleValue]], clientID, clientSecret, vAttribute];
               
        NSLog(@"Foursqure API-String: %@",foursquareAPIString);
        
        // Create NSURL string from formatted string
        NSURL *url = [NSURL URLWithString:foursquareAPIString];
        
        // Setup and start async download
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL: url];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [connection release];
        [request release];
    }
    
    [self.view reloadInputViews];
    [washAllAway drain];
}
- (void)viewDidUnload
{
    NSLog(@"ViewDidUnload is called for MAPS");
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.mapView = nil;
    self.activityIndicator= nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
