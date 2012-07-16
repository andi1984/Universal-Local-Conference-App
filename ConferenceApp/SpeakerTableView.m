//  SpeakerTableView.m
//  ConferenceApp

#import "SpeakerTableView.h"
#import "Session.h"
#import "User.h"
#import "Tag.h"
#import "TBXML.h"
#import "SpeakerViewController.h"
#import "SessionTableView.h"
#import "ProgressHUD.h"
#define searching_de @"Suche..."
#define searching_en @"Searching..."

@implementation SpeakerTableView
@synthesize speakerViewContext, speakerFetchResults, speakerImageFetchResults, conferenceName, storeURL, speakerSearchBar, delegate, progessDelegate;


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
- (void)handleSwiping
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)updateView
{
    //This method gets called to update the view with the actual saved data
    [self.speakerViewContext lock];
    
    //First setup a NSFetchRequest to get the data from core data
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setAffectedStores:[NSArray arrayWithObject:[[self.speakerViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.speakerViewContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"role ==\"speaker\" OR role ==\"invited_speaker\""];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"userid" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    [sortDescriptors release];
    [sortDescriptor release];
    
    NSError *error = nil;
    
    //Delete cache
    [self.speakerFetchResults removeAllObjects];
    
    //Set the results to speakerFetchResults
    self.speakerFetchResults = [[[self.speakerViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
    [self.tableView reloadData];
    [request release];
    
    [self.speakerViewContext unlock];
    
    if(isSearching)
    {
        //If user is searching, reset the searchtext
        [self searchBar:self.speakerSearchBar textDidChange:self.speakerSearchBar.text];
    }
}

- (void) handleRotation
{
        for (UIRotationGestureRecognizer* recognizer in [self.view gestureRecognizers]) {
            if(recognizer.state == UIGestureRecognizerStateEnded)
            {
                NSLog(@"Rotation is done!");
                [self.progessDelegate setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
                
                
                //Remove every cached data
                [self.speakerFetchResults removeAllObjects];
                [self.speakerImageFetchResults removeAllObjects];
                
                //Reload everything
                [self presentViewController:self.progessDelegate animated:YES completion:^{[self.delegate speakerTableViewForcedUpdateBy:self];}];
                
                //Reload view
                [self updateView];
            }
        }
}

- (IBAction) updateIsFinished
{
    [self viewWillDisappear:NO];
    [self viewWillAppear:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Allocate and initiate a swipe recognizer (swipe to the left) to get back to previous view
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(handleSwiping)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeRecognizer];
    [swipeRecognizer release];
    
    
    //Allocate and initiate a rotation gesture recognizer to reload data
    UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation)];
    [self.view addGestureRecognizer:rotationRecognizer];
    [rotationRecognizer release];
    
    //Set search variable to false, gets true when user is searching through searchbar
    isSearching = false;
    
    
    //Allocate and initiate a NSMutableDictionary to cache speaker images
    self.speakerImageFetchResults = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
    
    //Add store to persistentStoreCoordinator
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    NSString* storeFileName = [NSString stringWithFormat:@"%@",self.conferenceName];
    self.storeURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:storeFileName]];
    
    [self.speakerViewContext lock];

    [[self.speakerViewContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:nil];        
    
    [self.speakerViewContext unlock];
    
    //Create SearchBar
    self.speakerSearchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 50.0, 320.0, 50.0)] autorelease];
    [self.speakerSearchBar setBackgroundColor:[UIColor whiteColor]];
    [self.speakerSearchBar setDelegate:self];
    [self.speakerSearchBar setBarStyle:UIBarStyleBlackTranslucent];  
    
    //Delete background of searchbar
    for (UIView *view in self.speakerSearchBar.subviews)
    {
        if ([view isKindOfClass:NSClassFromString
             (@"UISearchBarBackground")])
        {
            [view removeFromSuperview];
            break;
        }
    }
    
    //Set searchbar as table header
    self.tableView.tableHeaderView = self.speakerSearchBar;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.speakerSearchBar = nil;
}
- (void)dealloc {
    [speakerFetchResults release];
    [speakerViewContext release];
    [speakerImageFetchResults release];
    [conferenceName release];
    [storeURL release];
    [speakerSearchBar release];
    [progessDelegate release];
    [super dealloc];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Allocate and initiate Upload-HUD when view appears
    self.progessDelegate = [[[ProgressHUD alloc] init] autorelease];
    
    //Run updateView method
    [self updateView];
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
    return [self.speakerFetchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //This method creates all cells (rows) with content about the speakers
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    
    //Get the participant corresponding to this cell
    User* currentSpeaker = [self.speakerFetchResults objectAtIndex:indexPath.row];
    
    //Set name label
    
    NSString* mainTextLabel = @"";
    if(currentSpeaker.firstname != nil && ![currentSpeaker.firstname isEqualToString:@""])
        mainTextLabel = [mainTextLabel stringByAppendingFormat:@"%@ ",currentSpeaker.firstname];
    if(currentSpeaker.lastname != nil && ![currentSpeaker.lastname isEqualToString:@""])
        mainTextLabel = [mainTextLabel stringByAppendingString:currentSpeaker.lastname];
    
    //If speaker is invited speaker, add this information to cell
    if([currentSpeaker.role isEqualToString:@"invited_speaker"])
    {
        if(mainTextLabel.length)
           mainTextLabel = [mainTextLabel stringByAppendingString:@"\nInvited Speaker"];
        else
            mainTextLabel = @"Invited Speaker";
    }
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.text = mainTextLabel;
    
    
    
    cell.detailTextLabel.numberOfLines = 1;
    //If speaker has specified short description, add this to the detailed textlabel
    if(currentSpeaker.shortdescription != nil && ![currentSpeaker.shortdescription isEqualToString:@""])
      cell.detailTextLabel.text = currentSpeaker.shortdescription;
    
    //If image of the speaker is in cache, load it. Otherwise download it and save it in cache
    if([self.speakerImageFetchResults valueForKey:[NSString stringWithFormat:@"%i",currentSpeaker.userid]] != nil)
    {
        NSLog(@"Cached Image found!");
        [cell.imageView setImage:[self.speakerImageFetchResults valueForKey:[NSString stringWithFormat:@"%i",currentSpeaker.userid]]];
    }
    else
    {
        if(currentSpeaker.pictureurl != nil && ![currentSpeaker.pictureurl isEqualToString:@""])
        {    
            UIImage *userImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:currentSpeaker.pictureurl]]];
            [cell.imageView setImage:userImage];
            [self.speakerImageFetchResults setValue:userImage forKey:[NSString stringWithFormat:@"%i",currentSpeaker.userid]];
            
        }
        else
            [cell.imageView setImage:[UIImage imageNamed:@"profile_missing_big.png"]];
    }
        
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
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
    
    //Get speaker content
    User* viewingSpeaker = [self.speakerFetchResults objectAtIndex:indexPath.row];
    
    //Allocate and initiate a detailed speaker view (instance of SpeakerViewController class)
    SpeakerViewController* showSpeakerViewController = [[SpeakerViewController alloc] initWithSpeakerID:viewingSpeaker.userid andManagedObjectContext:self.speakerViewContext andConference:self.conferenceName];
    
    //Push view to screen
    [self.navigationController pushViewController:showSpeakerViewController animated:YES];
    [showSpeakerViewController release];
}

#pragma mark - SearchBar
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //If user clicks on the search button, set isSearching to true and set focus from searchbar to complete view
    isSearching = true;
    [self.speakerSearchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    //If user starts typing in searchbar, set isSearching to true
    isSearching = true;
    
    //Display cancel button and disable autocorrection.
    self.speakerSearchBar.showsCancelButton = YES;
    self.speakerSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    //If cancel button is clicked, set isSearching to false
    isSearching = false;
    
    //Set focus from searchbar to view
  	[self.speakerSearchBar resignFirstResponder];
    
    //Set searchtext to empty text
    self.speakerSearchBar.text = @"";
    
    //Remove cancel button
    self.speakerSearchBar.showsCancelButton = NO;
    
    //Reload data from core data
    [self viewWillAppear:NO];
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //First delete all white space at the beginning of searchtext
    NSRange alphaNumericRange = [searchText rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]];
    if(alphaNumericRange.location < searchText.length)
    {
            searchText = [searchText substringFromIndex:alphaNumericRange.location];
    }
    else
        searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSLog(@"Text did change with searchtext: %@",searchText);
    
    //Remove all entries from search results
    [self.speakerFetchResults removeAllObjects];// remove all data that belongs to previous search

    [self.speakerViewContext lock];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setAffectedStores:[NSArray arrayWithObject:[[self.speakerViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.speakerViewContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"role ==\"speaker\" OR role ==\"invited_speaker\""];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"userid" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    [sortDescriptors release];
    [sortDescriptor release];
    
    NSError *error = nil;
    
    //Delete cache
    [self.speakerFetchResults removeAllObjects];
    
    
    //If searchtext is empty
    if([searchText isEqualToString:@""] || searchText==nil)
    {
        //Show all general results
        self.speakerFetchResults = [[[self.speakerViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
    }
    else
    {
        //Else set results as allAppropriateSpeakerItems
        NSArray* allAppropriateSpeakerItems = [[[self.speakerViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
        
        //For each potential searched user
        for(User *speaker in allAppropriateSpeakerItems)
        {
            //Set speakerAlreadySset to false, gets true if speaker fulfills searchtext
            bool speakerAlreadySet = false;
            
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
            
            //Search for search text in speaker's firstname
            NSRange r = [speaker.firstname rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(r.location != NSNotFound)
            {
                if(r.location== 0)//If searchtext matches firstname from beginning --> set speakerAlreadySet to true
                {
                    [self.speakerFetchResults addObject:speaker];
                    speakerAlreadySet = true;
                }
            }
            
            //Search for search text in speaker's lastname
            NSRange r2 = [speaker.lastname rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(r2.location != NSNotFound && !speakerAlreadySet)
            {
                if(r2.location== 0)//If searchtext matches lastname from beginning --> set speakerAlreadySet to true
                {
                    [self.speakerFetchResults addObject:speaker];
                    speakerAlreadySet = true;
                }
            }
            
            //Search for search text in description
            NSRange descriptionRange = [speaker.description rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(descriptionRange.location != NSNotFound && !speakerAlreadySet)
            {
                [self.speakerFetchResults addObject:speaker];
                speakerAlreadySet = true;
            }
            
            //Search for search text in first- and lastname
            NSString *firstAndLastName = [[NSString alloc] initWithFormat:@"%@ %@",speaker.firstname,speaker.lastname];
            NSRange firstAndLastNameRange = [firstAndLastName rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(firstAndLastNameRange.location != NSNotFound && !speakerAlreadySet)
            {
                if(firstAndLastNameRange.location == 0)
                {
                    [self.speakerFetchResults addObject:speaker];
                    speakerAlreadySet = true;
                }
            }
            [firstAndLastName release];
            
            //Search for match at speaker's tags
            for (Tag *currentTag in speaker.hasTags) {
                
                NSRange tagRange = [currentTag.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
                if(tagRange.location != NSNotFound && !speakerAlreadySet)
                {
                    if(tagRange.location == 0)
                    {
                        [self.speakerFetchResults addObject:speaker];
                        speakerAlreadySet = true;
                    }
                }
            }
            
            
            [pool release];
        }
    }
    [request release];
    
    [self.speakerViewContext unlock];
    [self.tableView reloadData];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    //If user ends typing search text
    NSLog(@"Did End Editing");
    
    //Remove cancel button
    self.speakerSearchBar.showsCancelButton = NO;
    
    //Reload data from core data
    [self.tableView reloadData];
}


@end
