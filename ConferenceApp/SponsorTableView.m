//  SponsorTableView.m
//  ConferenceApp

#import "SponsorTableView.h"
#import "Sponsor.h"
#import "Reachability.h"
@implementation SponsorTableView
@synthesize sponsorFetchResults, sponsorImageResults, sponsorViewContext, storeURL, conferenceName;

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

#pragma mark - View lifecycle
- (void)dealloc
{
    [sponsorFetchResults release];
    [sponsorImageResults release];
    [sponsorViewContext release];
    [storeURL release];
    [conferenceName release];
    [super dealloc];
}
- (void)handleSwiping
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIImage *) makeThumbnailFromImage:(UIImage *)bigImage ToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);  
    // draw scaled image into thumbnail context
    [bigImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();        
    // pop the context
    UIGraphicsEndImageContext();
    if(newThumbnail == nil) 
        NSLog(@"could not scale image");
    return newThumbnail;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Allocate and initiate a swipe gesture recognizer to get back to last view controller on navigationbar view stack.
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(handleSwiping)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeRecognizer];
    [swipeRecognizer release];
    
    //Allocate and initiate a NSMutableDictionary to save sponsor images
    self.sponsorImageResults = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
    
    //Add store to persistent store coordinator
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    NSString* storeFileName = [NSString stringWithFormat:@"%@",self.conferenceName];
    self.storeURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:storeFileName]];
    
    [[self.sponsorViewContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:nil];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL) isFileAtURLReachable:(NSURL *)fileURL 
{
    NSMutableURLRequest *userFileRequest = [[NSMutableURLRequest alloc] initWithURL:fileURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [userFileRequest setHTTPMethod:@"PUT"];
    NSHTTPURLResponse *urlResponse;
    NSError *error;
    [NSURLConnection sendSynchronousRequest:userFileRequest returningResponse:&urlResponse error:&error];
    [userFileRequest release];
    if(urlResponse.statusCode == 404)
        return false;
    else
        return true;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Search for all saved sponsor informations
            
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setAffectedStores:[NSArray arrayWithObject:[[self.sponsorViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sponsor" inManagedObjectContext:self.sponsorViewContext];
    [request setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    [sortDescriptors release];
    [sortDescriptor release];
    
    NSError *error = nil;
    
    //Clear cache and save all fetched informations in sponsorFetchResults
    [self.sponsorFetchResults removeAllObjects];
    self.sponsorFetchResults = [[[self.sponsorViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
    [request release];
    
    //Remove all sponsor images
    [self.sponsorImageResults removeAllObjects];
    
    //Now go through the information of all saved sponsors
    for (Sponsor* currentSponsor in self.sponsorFetchResults) {
        //If sponsor logo url is specified
        if(currentSponsor.logourl && ![currentSponsor.logourl isEqualToString:@""])
        {
            //Load images in background thread
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError* loadImageError = nil;

                //Load image in background
                NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:currentSponsor.logourl] options:NSDataReadingUncached error:&loadImageError];
                dispatch_async( dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    
                    //Find out the right Sponsor to the loaded image 
                    int row = 0;
                    for (Sponsor* fetchedSponsor in self.sponsorFetchResults) {
                        NSLog(@"Innere Schleife");
                        if([fetchedSponsor.name isEqualToString:currentSponsor.name])
                            break;
                        else
                            row = row+1;
                    }
                    
                    //Then update the corresponding cell (row) in the view
                    NSIndexPath *a = [NSIndexPath indexPathForRow:row inSection:0]; // I wanted to update this cell specifically
                    NSLog(@"Indexpath row: %i",row);
                    UITableViewCell *c = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:a];
                    
                    if(imageData != nil && !loadImageError)
                    {
                        //If image is specified, add it to view and delete title label (only showing the image)
                        c.textLabel.text = @"";
                        c.detailTextLabel.text = @"";
                        c.imageView.hidden = FALSE;
                        UIImage* sponsorLogo = [[UIImage alloc] initWithData:imageData];
                        
                        float imageRatio = sponsorLogo.size.height/sponsorLogo.size.width;
                        [c.imageView setImage:[self makeThumbnailFromImage:sponsorLogo ToSize:CGSizeMake(175.0, 175.0*imageRatio)]];
                        [sponsorLogo release];
                        
                        //Reload the corresponding cells (rows)
                        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:a] withRowAnimation:UITableViewRowAnimationNone];
                        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:a] withRowAnimation:UITableViewRowAnimationNone];   
                    }
                    else
                    {
                        //If no image is specified, set imageView to nil.
                        c.imageView.image = nil;
                        
                        //Set name label
                        c.textLabel.text = currentSponsor.name;
                        
                        //Set sponsor url as detailed text label
                        if(currentSponsor.sponsorurl != nil && ![currentSponsor.sponsorurl isEqualToString:@""])
                        {
                            c.detailTextLabel.text = currentSponsor.sponsorurl;
                        }
                        
                        //Reload the corresponding cells (rows)
                        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:a] withRowAnimation:UITableViewRowAnimationNone];
                        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:a] withRowAnimation:UITableViewRowAnimationNone];
                    }
                });
                [imageData release];
            });
        }
        else
        {
            NSLog(@"Setze Standard-Bild");
        }
        
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    return [self.sponsorFetchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    //First get infomration about the sponsor which should be displayed at this row (indexPath.row)
    Sponsor* currentSponsor= [self.sponsorFetchResults objectAtIndex:indexPath.row];
    
    
    //If a logo was specified, prepare all image and text frames and coment
    if(currentSponsor.logourl == nil || [currentSponsor.logourl isEqualToString:@""])
    {

        cell.imageView.frame = CGRectMake(0.0f , 0.0f, 0.0f, 0.0f);
        
        //Setze Namenstext
        cell.textLabel.text = currentSponsor.name;
        
        //Setze Beschreibung zum Referent
        if(currentSponsor.sponsorurl != nil && ![currentSponsor.sponsorurl isEqualToString:@""])
        {
            cell.detailTextLabel.text = currentSponsor.sponsorurl;
        }
    }
    
    //If URL was specified, set accessory button else remove accessory button
    if(currentSponsor.sponsorurl != nil && ![currentSponsor.sponsorurl isEqualToString:@""])
    {
         cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
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
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    
    //If accessory button was clicked, open URL in browser.
    Sponsor* currentSponsor= [self.sponsorFetchResults objectAtIndex:indexPath.row];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: currentSponsor.sponsorurl]];
}

@end
