//  StreamViewController.m
//  simpleTwitter

#import "StreamViewController.h"
#import "GTMNSString+HTML.h"
#import "SingleTweet.h"
#import "Conference.h"
#import "JSONKit.h"

#define connection_failed_de @"Verbindung fehlgeschlagen!"
#define connection_failed_en @"Connection failed."

@implementation StreamViewController
@synthesize fetchedTweets, feedURL, fetchedJSONData, highestTweetID, conferenceAcronym, activityIndicator;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"Dealloc was called!");
    [feedURL release];
    [fetchedTweets release];
    [fetchedJSONData release];
    [highestTweetID release];
    [conferenceAcronym release];
    [activityIndicator release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //After view is loaded...
    
    //... set first run variable to YES (true)
    firstRun = YES;
    
    //Allocate and initiate NSMutableData where JSON string is stored
    self.fetchedJSONData = [[[NSMutableData alloc] initWithLength:0] autorelease];
    
    //Allocate and initiate NSMutableArray where all tweets are stored
    self.fetchedTweets = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
    
    //Add a button to the right side of the navigation bar for reloading data. Fire reloadTwitterFeed method, after button is clicked
    UIBarButtonItem* rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reload.png"] style:UIBarButtonItemStylePlain target:self action:@selector(reloadTwitterFeed)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    [rightBarButtonItem release];
   
    //Run reloadTwitterFeed method manually
    [self reloadTwitterFeed];
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //Connection is unavailable
    NSLog(@"Failed connection");
    UIAlertView *connectionFailedAlertView = [[UIAlertView alloc] initWithTitle:connection_failed_en message:@"" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [connectionFailedAlertView show];
    [connectionFailedAlertView release];
    
    //UIActivityIndicator stoppen und Back-Button setzen
    [self.activityIndicator stopAnimating];
    self.navigationItem.leftBarButtonItem = UIBarButtonItemStylePlain;

}

- (void) reloadTwitterFeed
{
    NSLog(@"Reload!");

    //Add a activity indicator to the view to display loading status to the user
    self.activityIndicator = [[[UIActivityIndicatorView alloc] init] autorelease];
    self.activityIndicator.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
    [self.activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    UIBarButtonItem* leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    [leftBarButtonItem release];
    
    //Start the acitivity indicator
    [self.activityIndicator startAnimating];
    
    //Load data from twitter inc. in background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //If it's the first run, remove the since_id option in URL. This one is added to load all tweets which match query and which were written after the tweet with ID
        if(!firstRun)
            self.feedURL = [[[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://search.twitter.com/search.json?q=%@&result_type=recent&count=5&since_id=%@", self.conferenceAcronym, self.highestTweetID]] autorelease];
        else
            self.feedURL = [[[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://search.twitter.com/search.json?q=%@&result_type=recent&count=5", self.conferenceAcronym]] autorelease];
        dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"Feed-URL: http://search.twitter.com/search.json?q=%@&result_type=recent&count=5",self.conferenceAcronym);
        
        //Set up a url request and try to connect    
        NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:self.feedURL];
        [NSURLConnection connectionWithRequest:urlRequest delegate:self];
        [urlRequest release];
        });
    });
    
}
- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Connection was successful");

    //The connection was successful, hence save jsonString and decode all tweets and save them in fetchedTweets array
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
        // Store incoming data into a string
        NSData *jsonString = [[NSData alloc] initWithData:self.fetchedJSONData];
        
        //Clear fetchedJSONData by setting length to zero
        [self.fetchedJSONData setLength:0];
        
        // Create a dictionary from the JSON string
        JSONDecoder *twitterDecoder = [JSONDecoder decoder];
        NSDictionary *results = [[NSDictionary alloc] initWithDictionary:[twitterDecoder objectWithData:jsonString]];
        [jsonString release];
        
        //Set highestTweetID (can be used for option since_id)
        self.highestTweetID = [[[results objectForKey:@"max_id_str"] copy] autorelease];

        //Fetch all tweets
        NSArray *tweets = [[NSArray alloc] initWithArray:[results objectForKey:@"results"]];
        for (NSDictionary *tweet in tweets)
        {
            //For each tweet
            NSAutoreleasePool *innerReleasePool = [[NSAutoreleasePool alloc] init];
            
            //Create a mutable dictionary
            NSMutableDictionary* currentTweet = [[[NSMutableDictionary alloc] init] autorelease];
            
            //Read out tweet ID
            NSString* tweetID = [tweet objectForKey:@"id_str"];
            [currentTweet setObject:tweetID forKey:@"id"];
            
            //Read out twitter user name
            NSString *userName = [tweet objectForKey:@"from_user"];
            [currentTweet setObject:userName forKey:@"user"];
            
            //Read out data about user picture
            NSData* avatarData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[tweet objectForKey:@"profile_image_url"]]]; 
            [currentTweet setObject:avatarData forKey:@"avatar"];
            
            //Read out the tweet content itself
            NSString *tweetContent = [tweet objectForKey:@"text"];
            NSLog(@"Tweet: %@",tweetContent);
            [currentTweet setObject:tweetContent forKey:@"tweet"];
            
            //Save tweet in the right order in fetchedTweets array (will be displayed on view the same order as it is saved in the array)
            if(!firstRun)
                [self.fetchedTweets insertObject:currentTweet atIndex:0];
            else
                [self.fetchedTweets insertObject:currentTweet atIndex:[self.fetchedTweets count]];
            [innerReleasePool drain];
        }
        [outerPool drain];
        [results release];
        [tweets release];
        dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            NSLog(@"Reload Data!");
            [self.activityIndicator stopAnimating];
            self.navigationItem.leftBarButtonItem = UIBarButtonItemStylePlain;
            firstRun = FALSE;
        });
    });
    
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //Append all received data to the fetchedJSONData variable
    [self.fetchedJSONData appendData:data];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.activityIndicator = nil;
    self.fetchedJSONData = nil;
    self.fetchedTweets = nil;
    self.tableView = nil;
    self.feedURL = nil;
    self.highestTweetID = nil;
    self.conferenceAcronym = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}



- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.fetchedTweets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        NSLog(@"Neue Zelle!");
    }
    
    // Configure the cell...
    //Get tweet which should be displayed
    NSMutableDictionary* currentTweet = [[NSMutableDictionary alloc] initWithDictionary:[self.fetchedTweets objectAtIndex:indexPath.row]];
    
    //Set tweet itself as the general cell text
    cell.textLabel.text = [[currentTweet objectForKey:@"tweet"] gtm_stringByUnescapingFromHTML];
    
    //Set username as detailedtextlabel
    cell.detailTextLabel.text = [[currentTweet objectForKey:@"user"] gtm_stringByUnescapingFromHTML];
    
    //If the user has a picture
    if(![[currentTweet objectForKey:@"avatar"] isEqual:@""] && [currentTweet objectForKey:@"avatar"] != nil)
    {
        //Set picture as imageview.image
        cell.imageView.image = [UIImage imageWithData:[currentTweet objectForKey:@"avatar"]];
    }
    
    //Add a accessory button to open tweet in browser
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    [currentTweet release];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate
- (void)abortByTweetShow:(SingleTweet *)sender
{
    [self dismissModalViewControllerAnimated:YES];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    
    //After user clicked on a specific row, a new view (instance of class SingleTweet) with detailed tweet information (+ reply & retweet button) is displayed
   
    NSAutoreleasePool* didSelectRowPool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* currentTweet = [[NSMutableDictionary alloc] initWithDictionary:[self.fetchedTweets objectAtIndex:indexPath.row]];
    NSString* tweetURL = [[[NSString alloc] init] autorelease];
    tweetURL = @"https://twitter.com/#!/";
    tweetURL = [tweetURL stringByAppendingString:[currentTweet objectForKey:@"user"]];
    SingleTweet* singleTweetView = [[SingleTweet alloc] initWithAvatarData:[currentTweet objectForKey:@"avatar"]  andTwitterName:[[currentTweet objectForKey:@"user"] gtm_stringByUnescapingFromHTML] andTwitterURI:tweetURL andTweetText:[[currentTweet objectForKey:@"tweet"] gtm_stringByUnescapingFromHTML]];
    singleTweetView.delegate = self;
    singleTweetView.view.frame = CGRectMake(0.0, 0.0, 320.0, 200.0);
    
    /*
     
            SHAREKIT HAS A PROBLEM WITH PRESENTING ON A MODAL VIEW CONTROLLER! --> Best way to do this: Present normal view.
     
     */
    
    /*self.modalPresentationStyle = UIModalPresentationPageSheet;
    self.modalTransitionStyle = UIModalTransitionStylePartialCurl;*/
    
    [self.navigationController pushViewController:singleTweetView animated:YES];
    [singleTweetView release];
    [currentTweet release];
    [didSelectRowPool drain];
    
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    //This method gets called when user clicks on the accessory button of a row (tweet), then create a string named tweetURL with the corresponding tweet url which consists out of the user's name and the tweet id
    NSAutoreleasePool* didSelectRowPool = [[NSAutoreleasePool alloc] init];
    
    NSMutableDictionary* currentTweet = [[[NSMutableDictionary alloc] initWithDictionary:[self.fetchedTweets objectAtIndex:indexPath.row]] autorelease];
    NSString* tweetURL = [[[NSString alloc] init] autorelease];
    tweetURL = @"https://twitter.com/#!/";
    tweetURL = [tweetURL stringByAppendingString:[currentTweet objectForKey:@"user"]];
    tweetURL = [tweetURL stringByAppendingString:@"/status/"];
    
    NSString* pureID = [[[NSString alloc] init] autorelease];
    pureID = [currentTweet objectForKey:@"id"];
    tweetURL = [tweetURL stringByAppendingString:pureID];
    
    //Open URL in Safari browser
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: tweetURL]];
    [didSelectRowPool drain];
}
@end
