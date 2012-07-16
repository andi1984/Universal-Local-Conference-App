//  JSONFlickrViewController.m
//  FlickrJSonApp

#import "JSONFlickrViewController.h"
#import "JSONKit.h"

#define connection_failed_header_de @"Verbindungsprobleme"
#define connection_failed_header_en @"Connection problems"

#define connection_failed_de @"Verbindung fehlgeschlagen: %@"
#define connection_failed_en @"Connection failed: %@"

@implementation JSONFlickrViewController
@synthesize theTableView, theImageView, activityIndicator, theScrollView, searchString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    // Create table view
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (JSONFlickrViewController *) initWithSearchString:(NSString *)search
{
    //Initializer method containing search string
    
    self.searchString = search;
    return self;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section 
{   
    NSLog(@"Number of Fotos %i",[photoSmallImageData count]);
    return [photoURLsLargeImage count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    UITableViewCell *cell = 
    [tableView dequeueReusableCellWithIdentifier:@"cachedCell"];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"cachedCell"] autorelease];
    }
    
    cell.textLabel.text = [photoTitles objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:13.0];
    
    NSData *imageData = [photoSmallImageData objectAtIndex:indexPath.row];
    
    cell.imageView.image = [UIImage imageWithData:imageData];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.theImageView setImage:nil];
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    NSLog(@"Touch Event started!");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:[photoURLsLargeImage objectAtIndex:indexPath.row]];
        UIImage *imageWithDat = [[UIImage alloc] initWithData:imageData];
        dispatch_async(dispatch_get_main_queue(), ^{
                    [self.activityIndicator stopAnimating];
                    self.activityIndicator.hidden = YES;
            [self.theImageView setImage:imageWithDat];
            [self.theImageView setFrame:CGRectMake(self.view.center.x-imageWithDat.size.width/2, self.theImageView.center.y - imageWithDat.size.height/2, imageWithDat.size.width, imageWithDat.size.height)];
            [imageWithDat release];
        
        });});
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    UIAlertView* failedAlertView = [[UIAlertView alloc] initWithTitle:connection_failed_header_en message:[NSString stringWithFormat:connection_failed_en,error.localizedDescription] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [failedAlertView show];
    [failedAlertView release];
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
    [photoTitles removeAllObjects];         // Titles of images
    [photoSmallImageData removeAllObjects]; // Image data (thumbnail)
    [photoURLsLargeImage removeAllObjects];
    
    [self.theTableView reloadData];
    self.theImageView.image = nil;
    self.activityIndicator.hidden = NO;
    
    //Show activity indicator
    [self.activityIndicator startAnimating];
    
    //
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Store incoming data into a string
        NSData *jsonString = [[NSData alloc] initWithData:data];
        
        JSONDecoder* flickrDecoder = [JSONDecoder decoder];
        
        // Create a dictionary from the JSON string
        NSDictionary *results = [flickrDecoder objectWithData:jsonString];
        [jsonString release];
        
        // Build an array from the dictionary for easy access to each entry
        NSArray *photos = [[results objectForKey:@"photos"] objectForKey:@"photo"];
        // Loop through each entry in the dictionary...
        for (NSDictionary *photo in photos)
        {
            // Get title of the image
            NSString *title = [photo objectForKey:@"title"];
            
            // Save the title to the photo titles array
            [photoTitles addObject:(title.length > 0 ? title : @"Untitled")];
            
            // Build the URL to where the image is stored (see the Flickr API)
            // In the format http://farmX.static.flickr.com/server/id_secret.jpg
            // Notice the "_s" which requests a "small" image 75 x 75 pixels
            NSString *photoURLString = 
            [NSString stringWithFormat:@"http://farm%@.static.flickr.com/%@/%@_%@_s.jpg", 
             [photo objectForKey:@"farm"], [photo objectForKey:@"server"], 
             [photo objectForKey:@"id"], [photo objectForKey:@"secret"]];
            
            // The performance (scrolling) of the table will be much better if we
            // build an array of the image data here, and then add this data as
            // the cell.image value (see cellForRowAtIndexPath:)
            [photoSmallImageData addObject:[NSData dataWithContentsOfURL:[NSURL URLWithString:photoURLString]]];
            
            // Build and save the URL to the large image so we can zoom
            // in on the image if requested
            photoURLString = 
            [NSString stringWithFormat:@"http://farm%@.static.flickr.com/%@/%@_%@_m.jpg", 
             [photo objectForKey:@"farm"], [photo objectForKey:@"server"], 
             [photo objectForKey:@"id"], [photo objectForKey:@"secret"]];
            [photoURLsLargeImage addObject:[NSURL URLWithString:photoURLString]];        
            
        } 
        dispatch_async( dispatch_get_main_queue(), ^{
            //Stop activity indicator
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = YES;

            // Update the table with data
            [self.theTableView reloadData];
            [self.theTableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionTop animated:YES];
            if([photoURLsLargeImage count])
                [self tableView:self.theTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        });
    });
}

-(void)searchFlickrPhotos:(NSString *)text
{
    // Build the string to call the Flickr API
    NSString *urlString = 
    [NSString stringWithFormat:
     @"http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=%@&tags=%@&per_page=15&format=json&nojsoncallback=1", FlickrAPIKey, text];
        
    // Create NSURL string from formatted string
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Setup and start async download
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL: url];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection release];
    [request release];
    
}

- (void)dealloc
{
    [FlickrAPIKey release];
    [photoTitles release];
    [photoSmallImageData release];
    [photoURLsLargeImage release];
    [theTableView release];
    [theImageView release];
    [activityIndicator release];
    [theScrollView release];
    [searchString release];
    [super dealloc];
}

- (void) handleSwiping
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //After view did load, save Flickr API key
    FlickrAPIKey = @"8659bbb89d4e295ec473427ec46342a8";
    
    //Allocate and initiate arrays for photo titles, small & large images
    photoTitles = [[NSMutableArray alloc] init];         // Titles of images
    photoSmallImageData = [[NSMutableArray alloc] init]; // Image data (thumbnail)
    photoURLsLargeImage = [[NSMutableArray alloc] init]; //Image data (large)
    
    //Set activity indicator to be hidden. Gets on screen during downloading flickr data
    self.activityIndicator.hidden = YES;
    
    //Add a swipe gesture recognizer to the left (get back)
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(handleSwiping)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    
    [self.view addGestureRecognizer:swipeRecognizer];
    [swipeRecognizer release];
}


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.theImageView;
}
- (void)viewWillAppear:(BOOL)animated
{
    //When view will appear, show the table view where all images will be listed
    self.theTableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 300, self.view.frame.size.width, self.view.frame.size.height - 300)] autorelease];
    [self.theTableView setDelegate:self];
    [self.theTableView setDataSource:self];
    [self.theTableView setRowHeight:80];
    [self.view addSubview:self.theTableView];
    
    //Execute request to get flickr data
    [self searchFlickrPhotos:self.searchString];
    
    // Update the table with data
    [self.theTableView reloadData];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.theTableView = nil;
    self.theImageView = nil;
    self.activityIndicator = nil;
    self.theScrollView = nil;
    self.searchString = nil;
    photoTitles = nil;
    photoSmallImageData = nil;
    photoURLsLargeImage = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
