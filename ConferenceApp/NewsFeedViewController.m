//  NewsFeedViewController.m
//  ConferenceApp

#import "NewsFeedViewController.h"
#import "TBXML.h"
#import "GTMNSString+HTML.h"
@implementation NewsFeedViewController
@synthesize newsItems, allItemReleaseDates, feedURLString, activityIndicator;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

-(void)dealloc
{
    [newsItems release];
    [allItemReleaseDates release];
    [feedURLString release];
    [activityIndicator release];
    [super dealloc];
}
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //Allocate a dictionary for all news items
    self.newsItems = [[[NSMutableDictionary alloc] init] autorelease];
    
    //Allocate a mutable array where all news release dates are saved
    self.allItemReleaseDates = [[[NSMutableArray alloc] init] autorelease];
   
    //Set up a activityIndicator which will be displayed during downloading news
    self.activityIndicator = [[[UIActivityIndicatorView alloc] init] autorelease];
    self.activityIndicator.frame = CGRectMake(self.view.frame.size.width - 40.0, 0.0, 40.0, 40.0);
    [self.activityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    UIBarButtonItem* leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    self.navigationItem.rightBarButtonItem = leftBarButtonItem;
    [leftBarButtonItem release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.activityIndicator = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //After view appeared, start activity indicator and load news in background thread
    [self.activityIndicator startAnimating];
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Reload Feed
        // Setup and start async download
        NSURL *feedURL = [[NSURL alloc] initWithString:feedURLString];
        
        //Configure XML parser
        TBXML* tbxml = [TBXML tbxmlWithURL:feedURL];
        [feedURL release];
        TBXMLElement * root = tbxml.rootXMLElement;
        
        if (root)
        {
            //If root element in XML structure is found, search for typical wordpress XML structure Channel -> Item 
            TBXMLElement *channelElement = [TBXML childElementNamed:@"channel" parentElement:root];
            if(channelElement)
            {
                //If channel structure block is found, search for item
                TBXMLElement *itemElement = [TBXML childElementNamed:@"item" parentElement:channelElement];
                
                while(itemElement)
                {
                    //For each news item (means blogpost) set up a mutable dictionary where all properties will be saved
                    NSMutableDictionary *singleBlogPost = [[NSMutableDictionary alloc] init];
                    
                    //Set blogpost title
                    TBXMLElement *titleElement = [TBXML childElementNamed:@"title" parentElement:itemElement];
                    [singleBlogPost setObject:[TBXML textForElement:titleElement] forKey:@"title"];
                    
                    //Set blogpost URL
                    TBXMLElement *linkElement = [TBXML childElementNamed:@"link" parentElement:itemElement];
                    [singleBlogPost setObject:[TBXML textForElement:linkElement] forKey:@"link"];
                    
                    //Set release date
                    TBXMLElement *pubDateElement = [TBXML childElementNamed:@"pubDate" parentElement:itemElement];
                    
                    //Trim pubDate that only format dd MM yyyy will rest
                    NSString *pubDate = [TBXML textForElement:pubDateElement];
                    if(![pubDate isEqualToString:@""])
                    {
                        NSArray *pubDateTrimmedElements = [pubDate componentsSeparatedByString:@" "];
                        NSString *dateString;
                        NSString *timeString;
                        for (int i=0; i<[pubDateTrimmedElements count]; i = i+1) {
                            if(i==1)
                            {
                                dateString = [pubDateTrimmedElements objectAtIndex:i];
                            }
                            
                            if(i == 2)
                                dateString = [dateString stringByAppendingFormat:@" %@",[pubDateTrimmedElements objectAtIndex:i]];
                            
                            if(i == 3)
                                dateString = [dateString stringByAppendingFormat:@" %@",[pubDateTrimmedElements objectAtIndex:i]];
                            
                            if(i == 4)
                                timeString = [pubDateTrimmedElements objectAtIndex:i];
                        }
                        
                        //Save release (publication date)
                        [singleBlogPost setObject:dateString forKey:@"pubDate"];
                        
                        //Save publication/release time
                        [singleBlogPost setObject:[timeString substringToIndex:[timeString length] - 3] forKey:@"pubTime"];
                        
                        //Check whether release date is already in allItemReleaseDates
                        bool dateAlreadyIn = false;
                        for (NSString *currentDateStrnig in allItemReleaseDates) {
                            if([currentDateStrnig isEqualToString:dateString])
                                dateAlreadyIn = true;
                        }
                        
                        if(!dateAlreadyIn)
                        {
                            //If release date is not set yet, set it to allItemReleaseDates
                            [allItemReleaseDates addObject:dateString];
                        }
                        
                        if([newsItems objectForKey:dateString] != nil)
                        {
                            //If there is already a blogpost published at the same day, at it to this list
                            [[newsItems objectForKey:dateString] addObject:singleBlogPost];
                        }
                        else
                        {
                            //Else create a new list (array) and save it there
                            NSMutableArray *pubDateArray = [[NSMutableArray alloc] init];
                            [pubDateArray addObject:singleBlogPost];
                            [newsItems setObject:pubDateArray forKey:dateString];
                            [pubDateArray release];
                        }
                    }
                    [singleBlogPost release];
                    itemElement = [TBXML nextSiblingNamed:@"item" searchFromElement:itemElement];
                }
            }
            else
            {
                NSLog(@"Channel Element not found. No Wordpress file!");            
            }
        }
        else
        {
            NSLog(@"Wrong XML structure.");
        }
        dispatch_async( dispatch_get_main_queue(), ^{    
            [self.tableView reloadData];
            [self.activityIndicator stopAnimating];
        });
    });
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
    return [allItemReleaseDates count];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[newsItems objectForKey:[allItemReleaseDates objectAtIndex:section]] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [allItemReleaseDates objectAtIndex:section];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    // Configure the cell...
    
    //Publish results in a tableview
    cell.textLabel.text = [[[[newsItems objectForKey:[allItemReleaseDates objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] objectForKey:@"title"] gtm_stringByUnescapingFromHTML];
    cell.detailTextLabel.text = [[[[newsItems objectForKey:[allItemReleaseDates objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] objectForKey:@"pubTime"] gtm_stringByUnescapingFromHTML];
    return cell;
}


#pragma mark - Table view delegate

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
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[[newsItems objectForKey:[allItemReleaseDates objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] valueForKey:@"link"]]];
}

@end
