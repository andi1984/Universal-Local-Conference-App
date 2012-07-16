//  SessionTableView.m
//  TableViewFav

#import "SessionTableView.h"
#import "TBXML.h"
#import "Session.h"
#import "User.h"
#import "Venue.h"
#import "Sponsor.h"
#import "Tag.h"
#import "SessionViewController.h"
#import "ProgressHUD.h"
#import "Conference.h"
#import "Reachability.h"
#import "SHK.h"
#import "UserCSVParser.h"
#import "SessionCSVParser.h"

#define cellHeight 150.0

#define no_speakers_deutsch @"Keine Referenten"
#define no_speakers_english @"No Speakers"

#define session_overview_de @"Session Übersicht"
#define session_overview_en @"Session Overview"

#define faved_session_overview_de @"Favoriten"
#define faved_session_overview_en @"Favorized Sessions"

#define starts_now_de @"Findet jetzt statt!"
#define starts_now_en @"Starts now!"

#define just_over_de @"Gerade vorbei!"
#define just_over_en @"Is over right now!"

#define already_over_de @"Schon vorbei"
#define already_over_en @"Already over"

#define still_de @"Noch"
#define still_en @"Still"

#define still_running_de @"Läuft noch"
#define still_running_en @"Still running"

#define year_de @"Jahr"
#define year_en @"year"

#define years_de @"Jahre"
#define years_en @"years"

#define month_de @"Monat"
#define month_en @"month"

#define months_de @"Monate"
#define months_en @"months"

#define day_de @"Tag"
#define day_en @"day"

#define days_de @"Tage"
#define days_en @"days"

#define hour_de @"Stunde"
#define hour_en @"hour"

#define hours_de @"Stunden"
#define hours_en @"hours"

#define minute_de @"Minute"
#define minute_en @"minute"

#define minutes_de @"Minuten"
#define minutes_en @"minutes"

#define today_de @"Heute"
#define today_en @"Today"

#define access_problem_header_de @"Zugangsproblem"
#define access_problem_header_en @"Access Problem"

#define access_problem_de @"Die Anwendung konnte die Konferenz-Daten nicht abrufen."
#define access_problem_en @"App could not access the conference data"

#define too_many_results_header_de @"Konferenz existiert bereits"
#define too_many_results_header_en @"Conference already exists" 

#define too_many_results_de @"Es scheint bereits eine Konferenz mit dem gleichen Namen zu existieren."
#define too_many_results_en @"There seems to be already a conference with the same name."

#define data_could_not_be_found_header_de @"Daten konnten nicht gefunden werden."
#define data_could_not_be_found_header_en @"Data could not be found."

#define data_could_not_be_found_de @"Schliess die Anwendung und öffne sie erneut."
#define data_could_not_be_found_en @"Close and reload your app."

#define loading_data_error_header_de @"Laden der Daten nicht möglich."
#define loading_data_error_header_en @"Loading data failed."

#define loading_data_error_de @"Das Laden aktueller Daten war nicht erfolgreich, da die Angaben in der conference.xml-Datei fehlerhaft sind. Kontaktieren Sie den Konferenz-Veranstalter."
#define loading_data_error_en @"Loading data failed because of a invalid conference.xml file. Please contact the corresponding conference organizer."

#define no_internet_connection_header_de @"Keine Internetverbindung!"
#define no_internet_connection_header_en @"No internet connection!"

#define no_internet_connection_de @"Das Laden aktueller Daten ist nicht möglich. Überprüfen Sie ihre Internetverbindung!"
#define no_internet_connection_en @"Loading data failed. Please check your internet connection!"

#define time_overlay_header_de @"Zeitüberschneidung"
#define time_overlay_header_en @"Time Overlay"

#define time_overlay_de @"Es gibt eine Zeitüberschneidung mit den Session(s): %@"
#define time_overlay_en @"There is a time overlay with session(s): %@"

//#import "SessionViewController.h"
@implementation SessionTableView
@synthesize tableViewContext;
@synthesize mutableFetchResults;
@synthesize conferenceName;
@synthesize usersURL, sessionURL, venueURL, sponsorURL, storeURL;
@synthesize titleLabel, favButton, showOldSessionsButton, sessionSearchBar;
@synthesize conferenceTimeZone;
@synthesize isNotSyncing, problemWithData, hideOldSessions, isSearching, isDelegated, delegater, isReloadingData, isReloadingLabels, delegate;

- (void)checkButtonTapped:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    if (indexPath != nil)
    {
        [self tableView: self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
    }
}



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
        //Setze Notification, sofern App aus dem Ruhestand zurückgeholt wird und sessiontableview noch aktiv ist
        //Erstmal nochmal rausgenommen, da komische Bugs im Zusammenhang mit CoreData entstanden sind
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHud) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"Dealloc of SessionTableView");
      
    [mutableFetchResults release];
    [tableViewContext release];
    [conferenceName release];
    [usersURL release];
    [sessionURL release];
    [venueURL release];
    [sponsorURL release];
    [titleLabel release];
    [favButton release];
    [showOldSessionsButton release];
    [storeURL release];
    [conferenceTimeZone release];
    [sessionSearchBar release];
    //[delegate release];
    //[delegater release]; muss raus, da nur assigned wird  
    // Remove our Observer
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (BOOL)connected 
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];  
    NetworkStatus networkStatus = [reachability currentReachabilityStatus]; 
    return !(networkStatus == NotReachable);
}

- (void) handleSwiping
{
    NSLog(@"Swiping erkannt.");
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (void) handleRotation
{
    for (UIRotationGestureRecognizer* recognizer in [self.view gestureRecognizers]) {
        if(recognizer.state == UIGestureRecognizerStateEnded)
        {
            NSLog(@"Rotation is done!");
            
            NSLog(@"PresentModalViewController");
            [self.delegate setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
            [self presentViewController:self.delegate animated:YES completion:^{[self showHud];}];
        }
    }
}

- (IBAction) speakerTableViewForcedUpdateBy:(id)sender
{
    self.isDelegated = TRUE;
    self.delegater = sender;
    [self showHud];
}

- (void)viewDidLoad
{
    NSLog(@"View did load");
    [super viewDidLoad];
    
    //After view is load, set all bool variables to FALSE.
    
    //isNotSyncing is true if saved data could not be synced with online data, due to internet connection problems
    self.isNotSyncing = FALSE; 
    
    //problemWithData is true if online data could not be found
    self.problemWithData = FALSE;
    
    //hideOldSessions is true if user wants to hide sessions from overview which were done in the past
    self.hideOldSessions = FALSE;
    
    //isSearching is true if user is currently searching with the searchBar
    self.isSearching = FALSE;
    
    //isDelegated is true, if SpeakerTableView instance forces upload process within this class
    self.isDelegated = FALSE;
    
    //isReloadingLabels is true, if the timer process reloads the overview text and labels of this view
    self.isReloadingLabels = FALSE;
    
    //isReloadingData is true, if data reload is active
    self.isReloadingData = FALSE;
    
    //Set title of this view
    self.title = session_overview_en;  
    
    
    //Add a swipe gesture recognizer (to the left) to get back to the view before
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(handleSwiping)];

    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeRecognizer];
    [swipeRecognizer release];
    
    
    //Add a rotation gesture recognizer to manually reload data
    UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation)];
    [self.view addGestureRecognizer:rotationRecognizer];
    [rotationRecognizer release];
    
    
    //Setup the NSURLs to all online data
    self.usersURL = [NSURL URLWithString:@""];
    self.sessionURL = [NSURL URLWithString:@""];
    self.venueURL = [NSURL URLWithString:@""];
    self.sponsorURL = [NSURL URLWithString:@""];
    
    
    //Lock the core data access, means to guarantee that only one process is working at core data each time
    [self.tableViewContext lock];
    
    //Get all conference data
    NSFetchRequest* getAllNeededData = [[NSFetchRequest alloc] init];
    getAllNeededData.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.tableViewContext];
    getAllNeededData.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
    
    NSError *fetchingAllDataError = nil;;
    NSArray *allDataArray = [self.tableViewContext executeFetchRequest:getAllNeededData error:&fetchingAllDataError];
    
    if(fetchingAllDataError)
    {
        //If an error occured, inform the user
        UIAlertView* fetchingError = [[UIAlertView alloc] initWithTitle:access_problem_header_en message:access_problem_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [fetchingError show];
        [fetchingError release];
    }
    if(allDataArray == nil)
    {
        //If no data were found
        NSLog(@"Keine Daten dazu gefunden!");
    }
    else if(allDataArray.count > 1)
    {
        //If more than one conference with the same name were found, something is wrong because each conference needs a unique name
        UIAlertView* tooManyResults = [[UIAlertView alloc] initWithTitle:too_many_results_header_en message:too_many_results_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [tooManyResults show];
        [tooManyResults release];
    }
    else
    {
        //Else, get the conference details
        Conference* watchingConference = [allDataArray objectAtIndex:0];
        
        //Set the data URLs
        self.usersURL = [NSURL URLWithString:watchingConference.userxmlurl];
        self.sessionURL = [NSURL URLWithString:watchingConference.sessionxmlurl];
        self.venueURL = [NSURL URLWithString:watchingConference.venuexmlurl];
        self.sponsorURL = [NSURL URLWithString:watchingConference.sponsorxmlurl];
    }
    
    [getAllNeededData release];
    
    //Unlock core data access to be open
    [self.tableViewContext unlock];
    
    //Adding store to persistentStoreCoordinator
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    NSString* storeFileName = [NSString stringWithFormat:@"%@",self.conferenceName];
    self.storeURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:storeFileName]];
    
    [self.tableViewContext lock];
    [[self.tableViewContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:nil];
    [self.tableViewContext unlock];
    
    //Build searchBar
    self.sessionSearchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 50.0, 320.0, 50.0)] autorelease];
    [self.sessionSearchBar setBackgroundColor:[UIColor whiteColor]];
    [self.sessionSearchBar setDelegate:self];
    [self.sessionSearchBar setBarStyle:UIBarStyleBlackTranslucent];  
    
    //Delete default searchbar background due to design issues
    for (UIView *view in self.sessionSearchBar.subviews)
    {
        if ([view isKindOfClass:NSClassFromString
             (@"UISearchBarBackground")])
        {
            [view removeFromSuperview];
            break;
        }
    }
    
    //Set the search bar as the tableView header view
    self.tableView.tableHeaderView = self.sessionSearchBar;
    
    
    //Set the calls of the right header button (fav/unfaved view) to zero
    rightButtonCalls = 0;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //Set delegate to an instance of the ProgressHUD class (is shown during reloading procedure)
    self.delegate = [[[ProgressHUD alloc] init] autorelease];
    
    //Run showHud method
    [self showHud];
    
}



- (void) showFav
{
    //This method gets fired when the user switchs between favorised sessions and general overview. The switching is defined over a counting variable rightButtonCalls. If the number is even, the method prepares for faved overview, if it is odd for general view
    switch(rightButtonCalls%2)
    {
            case 0: //even case
            
            //Set title to faved overview
            self.title = faved_session_overview_en;
            
            //If user is currently searching in searchbar and clicks on fav overview, the title only changes together with a blank searchbar and blank searchtext. Hence we force to fire the textDidChange method of the searchbar to transport this searchtext again to the searchbar.
            
            if(!isSearching)
                [self.tableView reloadData];
            else
                [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
            
            //Increment right button calls
            rightButtonCalls +=1;
            
            //Lock access again to core data to this class instance            
            [self.tableViewContext lock];
            
            //Get data of wanted sessions (first sessions which are already faved and maybe (if hideOldSessions variable is true, only sessions which are not finished yet)
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
            [request setEntity:entity];
            
            if(self.hideOldSessions)
                request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@ AND alreadyover = %@", [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
            else
                request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@", [NSNumber numberWithBool:YES]];
            
            NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
            NSSortDescriptor *sortDescriptorTime = [[NSSortDescriptor alloc] initWithKey:@"starttime" ascending:YES];
            NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorDate,sortDescriptorTime, nil];
            
            [request setSortDescriptors:sortDescriptors];
            
            [sortDescriptors release];
            
            [sortDescriptorDate release];
            [sortDescriptorTime release];
            NSError *error = nil;
            
            //Save the results
            self.mutableFetchResults = [[[self.tableViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
            
            //If result list is empty
            if (self.mutableFetchResults == nil) {
                
                // Handle the error.
                NSLog(@"Fav Array is empty");
                
            }
            [request release];
            [self.tableViewContext unlock];
            
            //And again reload view
            if(!isSearching)
                [self.tableView reloadData];
            else
                [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
            break;
            
            case 1: //odd case
            
            //Set title
            self.title = session_overview_en;
            
            
            //Reload view
            if(!isSearching)
                [self.tableView reloadData];
            else
                [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
            
            //Increment right button calls
            rightButtonCalls +=1;
                        
            [self.tableViewContext lock];
            
            //Again search for data, now for all sessions or all sessions wich are not finished yet
            NSFetchRequest *request_back = [[NSFetchRequest alloc] init];
            [request_back setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
            NSEntityDescription *entity_back = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
            [request_back setEntity:entity_back];
            
            
            if(self.hideOldSessions)
                request_back.predicate = [NSPredicate predicateWithFormat:@"alreadyover = %@",[NSNumber numberWithBool:NO]];
            
            
            NSSortDescriptor *sortDescriptor_back = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
            NSSortDescriptor *sortDescriptorTime_back = [[NSSortDescriptor alloc] initWithKey:@"starttime" ascending:YES];
            NSArray *sortDescriptors_back = [[NSArray alloc] initWithObjects:sortDescriptor_back,sortDescriptorTime_back, nil];
            
            [request_back setSortDescriptors:sortDescriptors_back];
            
            [sortDescriptors_back release];
            
            [sortDescriptor_back release];
            [sortDescriptorTime_back release];
            
            NSError *error_back = nil;
            
            //Save results
            self.mutableFetchResults = [[[self.tableViewContext executeFetchRequest:request_back error:&error_back] mutableCopy] autorelease];
            
            //If result list is empty
            if (self.mutableFetchResults == nil) {
                
                // Handle the error.
                NSLog(@"Result Array is empty");
                
            }
            [request_back release];    
            [self.tableViewContext unlock];
            
            //Reload view
            if(!isSearching)
                [self.tableView reloadData];
            else
                [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
            break;
            default:
            NSLog(@"Wrong number of rightButtonCalls");
            break;
    }
}

- (BOOL) isFileAtURLReachable:(NSURL *)fileURL 
{
    //Checks whether a URL returns 404 statuscode or not. If yes, returns false if not, returns true
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

//This is the large update procedure for all data
- (void) reloadXMLFilesWithBlock:(void (^)())reloadProcessBlock
{   
    //Start critical mode and blocking all other threads to reload during this reload
    self.isReloadingData = TRUE;
    
    [self.tableViewContext lock];
    
    //If internet connection is granted and text of the view is not reloaded right now, enter the data reload procedure
    if([self connected] && !self.isReloadingLabels)
    {
        //If syncing of data could not be done before
        if(isNotSyncing)
        {
            //set variable to false again, because internet connection is granted again
            self.isNotSyncing = FALSE;
            
            //Send social media messages which were created during offline mode
            [SHK flushOfflineQueue];
        }
        
        //if at least one file is reachable online
        if([self isFileAtURLReachable:self.usersURL] || [self isFileAtURLReachable:self.sessionURL] || [self isFileAtURLReachable:self.venueURL] || [self isFileAtURLReachable:self.sponsorURL])
        {
            //Set problemWithData variable to false
            self.problemWithData = FALSE;
            
            //First delete all tags from core data
            
            /* +-+--+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- */
            //Deleting all Tags
            /* +-+--+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- */ 
            
            NSFetchRequest *allTagsRequest = [[NSFetchRequest alloc] init];
            [allTagsRequest setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
            allTagsRequest.entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:self.tableViewContext];
            NSError *allTagsError = nil;
            NSArray* allTagsArray = [self.tableViewContext executeFetchRequest:allTagsRequest error:&allTagsError];
            [allTagsRequest release];
            if(!allTagsError)
            {
                 if([allTagsArray count] > 0)
                 {
                 //Delete all Sessions
                    for (Tag* currentTag in allTagsArray) {
                         [self.tableViewContext deleteObject:currentTag];
                     }   
                 }
             }
                
            
    
                
            /* +-+--+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- */
            //Create User data in Core Data
            /* +-+--+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- */ 

            
            if([self isFileAtURLReachable:self.usersURL])
            {
                //userURL exists
                NSLog(@"User-File path exists");
                
                //Delete old user database in Core Data
               
                NSFetchRequest *allUsers = [[NSFetchRequest alloc] init];
                NSLog(@"PersistentStoreCoordinator %@",[self.tableViewContext persistentStoreCoordinator]);
                [allUsers setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]]; //PROBLEM HERE!!!!!
                allUsers.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.tableViewContext];
                NSError *allUsersError = nil;
                NSArray* allUsersSet = [[self.tableViewContext executeFetchRequest:allUsers error:&allUsersError] retain];
                if(!allUsersError)
                {
                    if([allUsersSet count] > 0)
                    {
                        //Delete all Sessions
                        for (User* currentUser in allUsersSet) {
                            [self.tableViewContext deleteObject:currentUser];
                        }   
                    }
                }
                [allUsers release];
                [allUsersSet release];
               
                
                //... and parse the user file again
               
                //First we have to check whether it is a xml or csv file
                
                //Search for '.csv' in file path
                NSRange csvRange = [[self.usersURL absoluteString] rangeOfString:@".csv" options:NSCaseInsensitiveSearch];
                if(csvRange.location != NSNotFound)
                {
                    //If '.csv was found
                    NSAutoreleasePool *csvPool = [[NSAutoreleasePool alloc] init];
                    
                    //Allocate and initiate a CSV parser for the user file
                    UserCSVParser *parser = [[UserCSVParser alloc] init];
                    
                    //Save output
                    NSMutableArray* userArrayOutput = [[parser getUsersFromCSVFileAtURL:self.usersURL] autorelease];
                    
                    //If there is some output
                    if(userArrayOutput !=nil)
                    {
                        //Check for every user in this output...
                        for (NSDictionary* user in userArrayOutput) {
                            //whether the user has a valid userid
                            if(![[user objectForKey:@"userid"] isEqualToString:@"NULL"] && ![[user objectForKey:@"userid"] isEqualToString:@""] && [user objectForKey:@"userid"] != nil)
                            {
                                //If ID is available and valid
                                //... check whether there exists already a user with the same userid which is unique in gerneal                                  
                                NSFetchRequest *existsUserWithID = [[NSFetchRequest alloc] init];
                                [existsUserWithID setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                existsUserWithID.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.tableViewContext];
                                existsUserWithID.predicate = [NSPredicate predicateWithFormat:@"userid = %@", [user objectForKey:@"userid"]];
                                NSError *sameUserError = nil;
                                User *sameIDUser = [[self.tableViewContext executeFetchRequest:existsUserWithID error:&sameUserError] lastObject];                       
                                [existsUserWithID release];
                                if (!sameUserError && !sameIDUser)
                                {
                                    NSLog(@"User does not exist.");
                                    //User with same id does not exist, hence we have to save information in a new user profile
                                    //Create new user profile
                                    User* newUser = [User initUserWithContext:self.tableViewContext andStore:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]];
                                    newUser.userid = [user objectForKey:@"userid"];
                                    
                                    //Save changes
                                    NSError *error = nil;
                                    if (![self.tableViewContext save:&error]) {
                                        
                                        NSLog(@"Fehler beim Speichern");
                                        
                                    }
                                    
                                    //If the user has a role ...
                                    if(![[user objectForKey:@"role"] isEqualToString:@"NULL"] && ![[user objectForKey:@"role"] isEqualToString:@""] && [user objectForKey:@"role"] != nil )
                                    {
                                        //... set the new role type.
                                        newUser.role = [user objectForKey:@"role"];
                                        
                                        //Save changes
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        } 
                                    }
                                    else
                                    {
                                        //Else set to default role 'participant'
                                        newUser.role = @"participant";
                                        
                                        //Save changes.
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If user has specified email adress, save email details.
                                    if(![[user objectForKey:@"email"] isEqualToString:@"NULL"] && ![[user objectForKey:@"email"] isEqualToString:@""] && [user objectForKey:@"email"] != nil)
                                    {
                                        newUser.email = [user objectForKey:@"email"];
                                        //Save changes
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If user has specified a firstname, save it.
                                    if(![[user objectForKey:@"firstname"] isEqualToString:@"NULL"] && ![[user objectForKey:@"firstname"] isEqualToString:@""] && [user objectForKey:@"firstname"] != nil)
                                    {
                                        newUser.firstname = [user objectForKey:@"firstname"];
                                        //Save changes
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If user has specified a lastname, save it.
                                    if(![[user objectForKey:@"lastname"] isEqualToString:@"NULL"] && ![[user objectForKey:@"lastname"] isEqualToString:@""] && [user objectForKey:@"lastname"] != nil)
                                    {
                                        
                                        newUser.lastname = [user objectForKey:@"lastname"];
                                        
                                        //Änderungen abspeichern
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If user has a homepage URL, save it.
                                    if(![[user objectForKey:@"homepageurl"] isEqualToString:@"NULL"] && ![[user objectForKey:@"homepageurl"] isEqualToString:@""] && [user objectForKey:@"homepageurl"] != nil)
                                    {
                                        newUser.homepageurl = [user objectForKey:@"homepageurl"];
                                        
                                        NSError *error = nil;
                                        if(![self.tableViewContext save:&error])
                                        {
                                            NSLog(@"Fehler beim Speichern!");
                                        }
                                    }
                                    
                                    //If user has specified age information, save it.
                                    if(![[user objectForKey:@"age"] isEqualToString:@"NULL"] && [user objectForKey:@"age"] != nil)
                                    {
                                        if(![[user objectForKey:@"age"] isEqualToString:@""])
                                        {
                                            //Wenn Alter angegeben und ungleich ""
                                            NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
                                            [f setNumberStyle:NSNumberFormatterNoStyle];
                                            NSNumber * myNumber = [f numberFromString:[user objectForKey:@"age"]];
                                            [f release];
                                            if(myNumber)
                                            {
                                                //If it is a valid integer number
                                                
                                                //Set it to the properties
                                                newUser.age = myNumber;
                                                
                                                //Save it
                                                NSError *error = nil;
                                                if (![self.tableViewContext save:&error]) {
                                                    
                                                    NSLog(@"Fehler beim Speichern");
                                                    
                                                }
                                            }
                                            else
                                            {
                                                NSLog(@"Given age has a wrong number format.");
                                            }
                                            
                                        }
                                    }
                                    else
                                    {
                                        NSLog(@"No age is given.");
                                    }
                                    
                                    
                                    //If user has specified a short description of himself, save it.
                                    if(![[user objectForKey:@"shortdescription"] isEqualToString:@"NULL"] && ![[user objectForKey:@"shortdescription"] isEqualToString:@""] && [user objectForKey:@"shortdescription"] != nil)
                                    {
                                        newUser.shortdescription = [user objectForKey:@"shortdescription"];
                                        
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                        }
                                    }
                                    
                                    //If user has specified a URL to a picture, save it.
                                    if(![[user objectForKey:@"pictureurl"] isEqualToString:@"NULL"] && ![[user objectForKey:@"pictureurl"] isEqualToString:@""] && [user objectForKey:@"pictureurl"] != nil)
                                    {
                                        newUser.pictureurl = [user objectForKey:@"pictureurl"];
                                        
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If user has specified a vcard URL, save it.
                                    if(![[user objectForKey:@"vcardurl"] isEqualToString:@"NULL"] && ![[user objectForKey:@"vcardurl"] isEqualToString:@""] && [user objectForKey:@"vcardurl"] != nil)
                                    {
                                        newUser.vcardurl = [user objectForKey:@"vcardurl"];
                                        
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If user has specified a cv URL, save it!
                                    if(![[user objectForKey:@"cv"] isEqualToString:@"NULL"] && ![[user objectForKey:@"cv"] isEqualToString:@""] && [user objectForKey:@"cv"] != nil)
                                    {
                                        newUser.cv = [user objectForKey:@"cv"];
                                     
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If the user has specified some descriptive tags....
                                    if(![[user objectForKey:@"tags"] isEqualToString:@"NULL"] && ![[user objectForKey:@"tags"] isEqualToString:@""] && [user objectForKey:@"tags"] != nil)
                                    {
                                        NSArray *tags = [[user objectForKey:@"tags"] componentsSeparatedByString:@", "];
                                        //Check for each tag...
                                        for (NSString *currentTag in tags) {
                                            //... if there exists already a tag with the same name
                                            NSFetchRequest *tagWithSameNameAlreadyExistsRequest = [[NSFetchRequest alloc] init];
                                            [tagWithSameNameAlreadyExistsRequest setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                            tagWithSameNameAlreadyExistsRequest.entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:self.tableViewContext];
                                            tagWithSameNameAlreadyExistsRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@",currentTag];
                                            NSError *tagWithSameNameError = nil;
                                            
                                            Tag* tagWithSameName = [[self.tableViewContext executeFetchRequest:tagWithSameNameAlreadyExistsRequest error:&tagWithSameNameError] lastObject];
                                            [tagWithSameNameAlreadyExistsRequest release];
                                            
                                            if(!tagWithSameNameError)
                                            {
                                                //If there occurred no error...
                                                if(tagWithSameName != nil)
                                                {
                                                    // and tag already exists in Core Data ...
                                                    
                                                    //.. match newUser with this tag
                                                    [newUser addHasTagsObject:tagWithSameName];
                                                    NSError *savingError;
                                                    if(![self.tableViewContext save:&savingError])
                                                    {
                                                        NSLog(@"Error while adding a new tag to the user!");
                                                    }
                                                }
                                                else
                                                {
                                                    //tag does not exist already ...
                                                    
                                                    //Create a new tag....
                                                    Tag *newTag = [Tag initTagWithContext:self.tableViewContext andStore:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]];
                                                    //.. and add a name to this tag
                                                    newTag.name = currentTag;
                                                    
                                                    //Then add this tag to the new user
                                                    [newUser addHasTagsObject:newTag];
                                                    NSError *savingError;
                                                    
                                                    //And save it
                                                    if(![self.tableViewContext save:&savingError])
                                                    {
                                                        NSLog(@"Error while creating and adding tag to the user!");
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }   
                    else
                    {
                        NSLog(@"Problem with CSV Parse! Control User-CSV file.");
                    }
                    
                    [parser release];
                    [csvPool drain]; 
                }
                
                
                //Check whether the user file is a xml file
                NSRange xmlRange = [[self.usersURL absoluteString] rangeOfString:@".xml" options:NSCaseInsensitiveSearch];
                if(xmlRange.location != NSNotFound)
                {
                    //If it is a XML file...
                    TBXML* tbxml = [TBXML tbxmlWithURL:usersURL];
                    TBXMLElement * root = tbxml.rootXMLElement;
                    
                    if (root)
                    {
                        //... and if the root of the file was found.
                        NSLog(@"XML Root exists!");
                        TBXMLElement *user = [TBXML childElementNamed:@"user" parentElement:root];
                        while(user != nil)
                        {
                            NSLog(@"User found!");
                            //Do for every user the same as above (now by parsing XML instead of CSV file)
                            TBXMLElement *userid = [TBXML childElementNamed:@"userid" parentElement:user];
                            if(userid && ![[TBXML textForElement:userid] isEqualToString:@""])
                            {
                                NSLog(@"UserID is %@",[TBXML textForElement:userid]);
                                                              
                                //Check with a fetch request whether user already exists
                                NSFetchRequest *existsUserWithID = [[NSFetchRequest alloc] init];
                                [existsUserWithID setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                existsUserWithID.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.tableViewContext];
                                existsUserWithID.predicate = [NSPredicate predicateWithFormat:@"userid = %@", [TBXML textForElement:userid]];
                                NSError *sameUserError = nil;
                                User *sameIDUser = [[self.tableViewContext executeFetchRequest:existsUserWithID error:&sameUserError] lastObject];                       
                                [existsUserWithID release];
                                if (!sameUserError && !sameIDUser)
                                {
                                    NSLog(@"User does not exist yet!");
                                    //No error occurred and there is actually no user with the same id in core data.
                                    
                                    //Create a new user
                                    User* newUser = [User initUserWithContext:self.tableViewContext andStore:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]];
                                    newUser.userid = [TBXML textForElement:userid];
                                    
                                    //Save changes
                                    NSError *error = nil;
                                    if (![self.tableViewContext save:&error]) {
                                        
                                        NSLog(@"Fehler beim Speichern");
                                        
                                    }
                                    
                                    //Set role type
                                    TBXMLElement *roleType = [TBXML childElementNamed:@"role" parentElement:user];
                                    if(roleType && ![[TBXML textForElement:roleType] isEqualToString:@""])
                                    {
                                        //If role type is specified, set it.
                                        newUser.role = [TBXML textForElement:roleType];
                                        
                                        //Save settings
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    else
                                    {
                                        //Else set default value to 'participantÄ
                                        newUser.role = @"participant";
                                        
                                        //Save settings
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If user specified mail adress, save it.
                                    TBXMLElement *emailAdress = [TBXML childElementNamed:@"email" parentElement:user];
                                    if(emailAdress && ![[TBXML textForElement:emailAdress]isEqualToString:@""])
                                    {
                                        newUser.email = [TBXML textForElement:emailAdress];

                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }

                                    //If the user specified his/her name, save it.
                                    TBXMLElement *username = [TBXML childElementNamed:@"name" parentElement:user];
                                    if(username)
                                    {
                                        TBXMLElement* firstname = [TBXML childElementNamed:@"firstname" parentElement:username];
                                        if(firstname)
                                        {
                                            //If surname is specified, save it.
                                            newUser.firstname = [TBXML textForElement:firstname];
                                            
                                            //Save changes
                                            NSError *error = nil;
                                            if (![self.tableViewContext save:&error]) {
                                                
                                                NSLog(@"Fehler beim Speichern");
                                                
                                            }
                                        }
                                        
                                        TBXMLElement* lastname = [TBXML childElementNamed:@"lastname" parentElement:username];
                                        if(lastname)
                                        {
                                            //If lastname is specified, save it
                                            newUser.lastname = [TBXML textForElement:lastname];
                                            
                                            //Save changes
                                            NSError *error = nil;
                                            if (![self.tableViewContext save:&error]) {
                                                
                                                NSLog(@"Fehler beim Speichern");
                                                
                                            }
                                        }
                                    }
                                    
                                    //If age is specified, save it
                                    TBXMLElement* age = [TBXML childElementNamed:@"age" parentElement:user];
                                    if(age)
                                    {
                                        if(![[TBXML textForElement:age] isEqualToString:@""])
                                        {
                                            NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
                                            [f setNumberStyle:NSNumberFormatterNoStyle];
                                            NSNumber * myNumber = [f numberFromString:[TBXML textForElement:age]];
                                            [f release];
                                            if(myNumber)
                                            {
                                                //If age has a valid number format.
                                                
                                                //Save it
                                                newUser.age = myNumber;
                                                
                                                NSError *error = nil;
                                                if (![self.tableViewContext save:&error]) {
                                                    
                                                    NSLog(@"Fehler beim Speichern");
                                                    
                                                }
                                            }
                                            else
                                            {
                                                NSLog(@"Age has a wrong number format.");
                                            }
                                            
                                        }
                                    }
                                    else
                                    {
                                        NSLog(@"No age was specified.");
                                    }
                                    
                                    //If short description is specified, save it.
                                    TBXMLElement* userDescription = [TBXML childElementNamed:@"shortdescription" parentElement:user];
                                    if(userDescription)
                                    {
                                        newUser.shortdescription = [TBXML textForElement:userDescription];
                                        
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If homepageURL is specified, save it.
                                    TBXMLElement* homepageURL = [TBXML childElementNamed:@"homepageurl" parentElement:user];
                                    if(homepageURL)
                                    {
                                        newUser.homepageurl = [TBXML textForElement:homepageURL];
                                        
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If tags were specified
                                    TBXMLElement *tags = [TBXML childElementNamed:@"tags" parentElement:user];
                                    if(tags)
                                    {
                                        TBXMLElement *tag = [TBXML childElementNamed:@"tag" parentElement:tags];
                                        while(tag)
                                        {
                                            //For each tag
                                            
                                            //... check whether there exists already a tag with the same naame.
                                            NSFetchRequest *tagWithSameNameAlreadyExistsRequest = [[NSFetchRequest alloc] init];
                                            [tagWithSameNameAlreadyExistsRequest setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                            tagWithSameNameAlreadyExistsRequest.entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:self.tableViewContext];
                                            tagWithSameNameAlreadyExistsRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@",[TBXML textForElement:tag]];
                                            NSError *tagWithSameNameError = nil;
                                            Tag* tagWithSameName = [[self.tableViewContext executeFetchRequest:tagWithSameNameAlreadyExistsRequest error:&tagWithSameNameError] lastObject];
                                            [tagWithSameNameAlreadyExistsRequest release];
                                            if(!tagWithSameNameError)
                                            {
                                                //No error while requesting the fetch
                                                if(tagWithSameName != nil)
                                                {
                                                    //Tag is already created
                                                    
                                                    //.. combine user with this tag.
                                                    [newUser addHasTagsObject:tagWithSameName];
                                                    NSError *savingError;
                                                    if(![self.tableViewContext save:&savingError])
                                                    {
                                                        NSLog(@"Error while adding a tag to the user.");
                                                    }
                                                }
                                                else
                                                {
                                                    //Tag does not exist yet.
                                                    
                                                    //Tag has to be created
                                                    Tag *newTag = [Tag initTagWithContext:self.tableViewContext andStore:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]];
                                                    //.. save the name
                                                    newTag.name = [TBXML textForElement:tag];
                                                    
                                                    //And combine user with this tag.
                                                    [newUser addHasTagsObject:newTag];
                                                    NSError *savingError;
                                                    if(![self.tableViewContext save:&savingError])
                                                    {
                                                        NSLog(@"Error while creating and adding a tag to the user!");
                                                    }
                                                }
                                            }
                                            tag = [TBXML nextSiblingNamed:@"tag" searchFromElement:tag];
                                        }
                                    }
                                    
                                    //If user picture URL is specified, save it
                                    TBXMLElement* userPictureURL = [TBXML childElementNamed:@"pictureurl" parentElement:user];
                                    if(userPictureURL)
                                    {
                                        newUser.pictureurl = [TBXML textForElement:userPictureURL];
                                        
                                        //Save settings
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                        
                                    }
                                    
                                    //If user vCard URL is specified, save it.
                                    TBXMLElement* vCardURL = [TBXML childElementNamed:@"vcardurl" parentElement:user];
                                    if(vCardURL)
                                    {
                                        newUser.vcardurl = [TBXML textForElement:vCardURL];
                                        
                                        //Save setting
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    //If user specified cv url, save it.
                                    TBXMLElement* cvURL = [TBXML childElementNamed:@"cv" parentElement:user];
                                    if(cvURL)
                                    {
                                        newUser.cv = [TBXML textForElement:cvURL];
                                        
                                        //save setting
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                }   
                            }
                            user = [TBXML nextSiblingNamed:@"user" searchFromElement:user];
                        }
                    }
                }
            }
            
            
            /* +-+--+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- */
            //Create Sponsor data in Core Data
            /* +-+--+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- */
            
            if([self isFileAtURLReachable:self.sponsorURL])
            {
                //If sponsor XML file is reachable online...
                
                //... first get a list of all saved sponsor data
                NSFetchRequest *allSponsors = [[NSFetchRequest alloc] init];
                [allSponsors setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                allSponsors.entity = [NSEntityDescription entityForName:@"Sponsor" inManagedObjectContext:self.tableViewContext];
                NSError *allSponsorsError = nil;
                NSArray *allSponsorsSet = [self.tableViewContext executeFetchRequest:allSponsors error:&allSponsorsError];
                [allSponsors release];
                if(!allSponsorsError)
                {
                    //If no error occured...
                    if([allSponsorsSet count] > 0)
                    {
                        //... and there are some sponsor informations
                        for(Sponsor* currentSponsor in allSponsorsSet)
                        {
                            //... delete them
                            [self.tableViewContext deleteObject:currentSponsor];
                        }
                    }
                } 
                
                //Parse new sponsor informations by setting up the XML parser and give it the XML URL.
                
                TBXML* tbxml = [[TBXML tbxmlWithURL:self.sponsorURL] retain];
                TBXMLElement *root = tbxml.rootXMLElement;
                if(root)
                {
                    //If root in XML document was found
                    TBXMLElement* sponsor = [TBXML childElementNamed:@"sponsor" parentElement:root];
                    while (sponsor != nil)
                    {
                        //Do for every sponsor
                    
                        TBXMLElement *sponsorName = [TBXML childElementNamed:@"name" parentElement:sponsor];
                        if(sponsorName)
                        {
                            //If sponsor name was found, check whether sponsor already exists
                            NSFetchRequest *sponsorWithSameName = [[NSFetchRequest alloc] init];
                            [sponsorWithSameName setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                            sponsorWithSameName.entity = [NSEntityDescription entityForName:@"Sponsor" inManagedObjectContext:self.tableViewContext];
                            sponsorWithSameName.predicate = [NSPredicate predicateWithFormat:@"name = %@",[TBXML textForElement:sponsorName]];
                            NSError *nameComparisonError = nil;;
                            
                            Sponsor *sponsorWithName = [[self.tableViewContext executeFetchRequest:sponsorWithSameName error:&nameComparisonError] lastObject];
                            
                            [sponsorWithSameName release];
                            
                            if(!nameComparisonError && !sponsorWithName)
                            {
                                //Sponsor does not exist, hence create a new one and set all properties (if provided).
                                Sponsor *newSponsor = [Sponsor initSponsorWithContext:self.tableViewContext andStore:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]];
                                
                                TBXMLElement *sponsorURLElement = [TBXML childElementNamed:@"sponsorurl" parentElement:sponsor];
                                TBXMLElement *logoURLElement = [TBXML childElementNamed:@"logourl" parentElement:sponsor];
                                if(sponsorName)
                                    newSponsor.name = [TBXML textForElement:sponsorName];
                                
                                if(sponsorURLElement && ![[TBXML textForElement:sponsorURLElement] isEqualToString:@""])
                                {
                                    newSponsor.sponsorurl = [TBXML textForElement:sponsorURLElement];
                                }
                                
                                if(logoURLElement && ![[TBXML textForElement:logoURLElement] isEqualToString:@""])
                                    newSponsor.logourl = [TBXML textForElement:logoURLElement];
                                
                                NSError *error = nil;
                                if (![self.tableViewContext save:&error]) {
                                    
                                    NSLog(@"Fehler beim Speichern");
                                    
                                }
                            }    
                        }
                        sponsor = [TBXML nextSiblingNamed:@"sponsor" searchFromElement:sponsor];
                    }
                }
                [tbxml release];
            }
                
                
            /* +-+--+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- */
            //Create Venues in Core Data
            /* +-+--+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- */
            
            if([self isFileAtURLReachable:self.venueURL])
            {
                //If venue XML document is reachable at the internet
                
                //... delete all saved venue items by first searching for all saved data about venues

                NSFetchRequest* allVenues = [[NSFetchRequest alloc] init];
                [allVenues setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                allVenues.entity = [NSEntityDescription entityForName:@"Venue" inManagedObjectContext:self.tableViewContext];
                NSError *allVenuesError = nil;
                NSArray* allVenuesArray = [self.tableViewContext executeFetchRequest:allVenues error:&allVenuesError];
                [allVenues release];
                if(!allVenuesError)
                {
                    if([allVenuesArray count] > 0)
                    {
                        //If there are saved venues, delete all of them
                        for(Venue* currentVenue in allVenuesArray)
                        {
                            [self.tableViewContext deleteObject:currentVenue];
                        }
                    }
                }    
                
                //.. and start parsing the venue xml file
                TBXML *tbxml = [TBXML tbxmlWithURL:venueURL];
                TBXMLElement *root = tbxml.rootXMLElement;
                if(root)
                {
                    //If root in XML document was found....
                    TBXMLElement* venue = [TBXML childElementNamed:@"venue" parentElement:root];
                    while(venue != nil)
                    {
                        //do for every venue the following
                        TBXMLElement* venueName = [TBXML childElementNamed:@"name" parentElement:venue];
                        if(venueName && ![[TBXML textForElement:venueName] isEqualToString:@""])
                        {
                            //If venue has a name, check whether venue already exists
                            NSFetchRequest* venueWithSameName = [[NSFetchRequest alloc] init];
                            [venueWithSameName setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                            venueWithSameName.entity = [NSEntityDescription entityForName:@"Venue" inManagedObjectContext:self.tableViewContext];
                            venueWithSameName.predicate = [NSPredicate predicateWithFormat:@"name = %@",[TBXML textForElement:venueName]];
                            NSError *venueWithSameNameError = nil;
                            
                            Venue* venueWithSameNameElement = [[self.tableViewContext executeFetchRequest:venueWithSameName error:&venueWithSameNameError] lastObject];
                            
                            [venueWithSameName release];
                            
                            if(!venueWithSameNameError && !venueWithSameNameElement)
                            {
                                //Venue does not exist and there was no error. Then create a new venue
                                Venue *newVenue = [Venue initVenueWithContext:self.tableViewContext andStore:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]];
                                
                                //Set name of venue
                                if(venueName)
                                    newVenue.name = [TBXML textForElement:venueName];
                                
                                //Save changes
                                NSError *savingError = nil;
                                if (![self.tableViewContext save:&savingError]) {
                                    
                                    NSLog(@"Fehler beim Speichern");
                                    
                                }
                                
                                //Check website URL and set it, if specified
                                TBXMLElement* websiteURL = [TBXML childElementNamed:@"websiteurl" parentElement:venue];
                                if(websiteURL)
                                {
                                    NSLog(@"Ort hat Website angegeben.");
                                    newVenue.websiteurl = [TBXML textForElement:websiteURL];
                                    NSError *savingError = nil;
                                    if (![self.tableViewContext save:&savingError]) {
                                        
                                        NSLog(@"Fehler beim Speichern");
                                        
                                    }
                                }
                                
                                //Check location informations
                                TBXMLElement* location = [TBXML childElementNamed:@"location" parentElement:venue];
                                if(location != nil)
                                {
                                    //If location information was found, take a deeper look to longitude and latitude values
                                    TBXMLElement* longitude = [TBXML childElementNamed:@"longitude" parentElement:location];
                                    TBXMLElement* latitude = [TBXML childElementNamed:@"latitude" parentElement:location];
                                    if(longitude && ![[TBXML textForElement:longitude] isEqualToString:@""] && latitude && ![[TBXML textForElement:latitude] isEqualToString:@""])
                                    {
                                        
                                        //If longitude and latitude was found, transform characters into a decimal number for processing this values.
                                        
                                        NSDecimalNumber* longitudeNumber = [[NSDecimalNumber alloc] initWithString:[TBXML textForElement:longitude]];
                                        
                                        //Check whether longitude values are valid to display values in google maps
                                        if([longitudeNumber doubleValue]>=-180.0 && [longitudeNumber doubleValue]<180.0)
                                        {
                                            //If longitude value is valid for google maps usage, set the value
                                            newVenue.longitude = longitudeNumber;
                                            NSError *savingError = nil;
                                            
                                            //Save changes
                                            if (![self.tableViewContext save:&savingError]) {
                                                
                                                NSLog(@"Fehler beim Speichern");
                                                
                                            }
                                        }
                                        [longitudeNumber release];
                                        
                                        
                                        //Transform latitude characters into a decimal number
                                        NSDecimalNumber* latitudeNumber = [[NSDecimalNumber alloc] initWithString:[TBXML textForElement:latitude]];
                                        
                                        //GOOGLE CHECK
                                        //Check whether latitude number is valid for google maps (projection problems for values greater/less than +- 85.05113
                                        if([latitudeNumber doubleValue] >=-85.0511 && [latitudeNumber doubleValue] <= 85.05113)
                                        {
                                            //If latitude value is valid for Google Maps, set the value
                                            
                                            newVenue.latitude = latitudeNumber;
                                            NSError *savingError = nil;
                                            if (![self.tableViewContext save:&savingError]) {
                                                
                                                NSLog(@"Fehler beim Speichern");
                                                
                                            }
                                        }
                                        [latitudeNumber release]; 
                                    }
                                    else
                                    {
                                        //else set the location variables to nil
                                        newVenue.longitude = nil;
                                        newVenue.latitude = nil;
                                    }
                                }
                                else
                                {
                                    //If no location block exists in xml file, set variables to nil.
                                    newVenue.longitude = nil;
                                    newVenue.latitude = nil;
                                }
                                
                                //Check whether some info text about the venue was specified
                                TBXMLElement* infotext = [TBXML childElementNamed:@"infotext" parentElement:venue];
                                if(infotext)
                                {
                                    //If this is the case, set the values
                                    newVenue.infotext = [TBXML textForElement:infotext];
                                    NSError *savingError = nil;
                                    if(![self.tableViewContext save:&savingError])
                                    {
                                        NSLog(@"Fehler beim Speichern!");
                                    }
                                }
                                
                                //Same for floorPlanURL
                                TBXMLElement* floorPlanURL = [TBXML childElementNamed:@"floorplan" parentElement:venue];
                                if(floorPlanURL)
                                {
                                    newVenue.floorplan = [TBXML textForElement:floorPlanURL];
                                    NSError *savingError = nil;
                                    if(![self.tableViewContext save:&savingError])
                                    {
                                        NSLog(@"Fehler beim Speichern!");
                                    }
                                }
                            }   
                        }
                        venue = [TBXML nextSiblingNamed:@"venue" searchFromElement:venue];
                    }
                }       
            }
            
            /* +-+--+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- */
            //Create Sessions in Core Data
            /* +-+--+-+-+-++-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- */
            

            if([self isFileAtURLReachable:self.sessionURL])
            {
                //If session file is reachable on the internet
                
                //... then first grab all saved session informations...
                NSMutableDictionary *favedDictionary = [[NSMutableDictionary alloc] init];
                
                NSFetchRequest *allSessions = [[NSFetchRequest alloc] init];
                [allSessions setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                allSessions.entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
                NSError *allSessionsError = nil;
                NSArray* allSessionsSet = [self.tableViewContext executeFetchRequest:allSessions error:&allSessionsError];
                [allSessions release];
                if(!allSessionsError)
                {
                    if([allSessionsSet count] > 0)
                    {
                        //... and delete all of them
                        for (Session* currentSession in allSessionsSet) {
                            if(currentSession.isfaved != nil)
                            {
                                [favedDictionary setObject:currentSession.isfaved forKey:currentSession.sessionid];
                            }
                            else
                            {
                                [favedDictionary setObject:[NSNumber numberWithBool:NO] forKey:currentSession.sessionid];
                            }
                            [self.tableViewContext deleteObject:currentSession];
                        }
                    }
                }
                
                [self.tableViewContext unlock];
               
                
                //... and parse session file again
                
                //First check out whether it is a .csv file
                NSRange csvRange = [[self.sessionURL absoluteString] rangeOfString:@".csv" options:NSCaseInsensitiveSearch];
                
                if(csvRange.location != NSNotFound)
                {
                    //If it is a csv file...
                    NSAutoreleasePool *csvPool = [[NSAutoreleasePool alloc] init];
                    
                    //... allocate and initate an instance of SessionCSVParser
                    SessionCSVParser *parser = [[SessionCSVParser alloc] init];
                    
                    //Grab all sessions saved in this file by running the parser
                    NSMutableArray* sessionArrayOutput = [[parser getSessionsFromCSVFileAtURL:self.sessionURL] autorelease];
                    if(sessionArrayOutput !=nil)
                    {
                        for (NSDictionary *session in sessionArrayOutput)
                        {
                            //For each saved session check whether session already exists
                            NSFetchRequest *isEqual = [[NSFetchRequest alloc] init];
                            [isEqual setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                            isEqual.entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
                            isEqual.predicate = [NSPredicate predicateWithFormat:@"sessionid = %@",[session valueForKey:@"sessionid"]];
                            NSError *sameIDError = nil;
                            Session *sameIDSession = [[self.tableViewContext executeFetchRequest:isEqual error:&sameIDError] lastObject];
                            NSLog(@"SessionID of sameSession %@ and name %@",sameIDSession.sessionid, sameIDSession.title);
                            [isEqual release];
                            
                            if (!sameIDError && !sameIDSession && ![[session valueForKey:@"sessionid"] isEqualToString:@""] && ![[session valueForKey:@"sessionid"] isEqualToString:@"NULL"] && [session valueForKey:@"sessionid"] != nil)
                            {
                                //If session ID is valid and session with this ID does not exists
                                
                                //... create new session data
                                Session* newSession = [Session initSessionInContext:self.tableViewContext andStore:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]];
                                
                                //... and set all properties like title, abstract....
                                newSession.sessionid = [session valueForKey:@"sessionid"];
                                
                                if(![[session valueForKey:@"title"] isEqualToString:@"NULL"])
                                    newSession.title = [session valueForKey:@"title"];
                                
                                if(![[session valueForKey:@"abstract"] isEqualToString:@"NULL"])
                                    newSession.abstract = [session valueForKey:@"abstract"];
                                
                                //Set the alreadyover property to false here. Whether the session is already finished will be checked in another method.
                                [newSession setAlreadyover:[NSNumber numberWithBool:NO]];
                                
                                //Set the faved state 
                                newSession.isfaved = [favedDictionary objectForKey:[session valueForKey:@"sessionid"]];
                                
                                
                                //Save settings
                                NSError *error = nil;
                                if (![self.tableViewContext save:&error]) {
                                    
                                    NSLog(@"Fehler beim Speichern");
                                    
                                }
                                
                                //If some speaker informations are set
                                if(![[session objectForKey:@"speakers"] isEqualToString:@"NULL"] && ![[session objectForKey:@"speakers"] isEqualToString:@""] && [session objectForKey:@"speakers"] != nil)
                                {
                                    //Get all specified speakers
                                    NSArray *speakerIDs = [[[session objectForKey:@"speakers"] stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@","];
                                    
                                    //For each speaker
                                    for (NSString *speakerID in speakerIDs)
                                    {                                        
                                        //... check whether user with same ID already exists.
                                        NSFetchRequest *existsSpeakerWithID = [[NSFetchRequest alloc] init];
                                        [existsSpeakerWithID setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                        existsSpeakerWithID.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.tableViewContext];
                                        existsSpeakerWithID.predicate = [NSPredicate predicateWithFormat:@"userid = %@", speakerID];
                                        NSError *sameSpeakerError = nil;
                                        
                                        User *sameIDUser = [[self.tableViewContext executeFetchRequest:existsSpeakerWithID error:&sameSpeakerError] lastObject];                       
                                        
                                        [existsSpeakerWithID release];
                                        
                                        if(!sameSpeakerError && sameIDUser)
                                        {
                                            //If user with the same ID exists ...
                                            //... check whether the user has role 'speaker'
                                            
                                            if([sameIDUser.role isEqualToString:@"speaker"] || [sameIDUser.role isEqualToString:@"invited_speaker"])
                                            {
                                                //If this is the case all requirements are fulfilled
                                                
                                                //Add speaker to the session data
                                                [newSession addHasSpeakersObject:sameIDUser];
                                                
                                            
                                                //Save settings
                                                NSError *error = nil;
                                                if (![self.tableViewContext save:&error]) {
                                                    
                                                    NSLog(@"Fehler beim Speichern");
                                                    
                                                }
                                            }
                                        }
                                        else
                                        {
                                            NSLog(@"Error or speaker does not exist.");
                                        }
                                    }
                                }
                                
                                NSString* dateString = [session valueForKey:@"date"];
                                NSLog(@"Session date: %@", dateString);
                                if(![dateString isEqualToString:@""] && ![dateString isEqualToString:@"NULL"] && dateString != nil)
                                {
                                    //If date string is given, compute a NSDate...
                                    NSDateFormatter* dateConstructor = [[NSDateFormatter alloc] init];
                                    [dateConstructor setDateFormat:@"YYYY:MM:dd"];
                                    NSDate* sessionDate = [dateConstructor dateFromString:dateString];
                                    [dateConstructor release];
                                    
                                    NSDateFormatter* stringFromOriginalDate = [[NSDateFormatter alloc] init];
                                    [stringFromOriginalDate setDateFormat:@"YYYY:MM:dd"];
                                    NSString* originalDateString = [stringFromOriginalDate stringFromDate:sessionDate];
                                    [stringFromOriginalDate release];
                                    
                                    if(originalDateString != nil)
                                    {
                                        NSDateComponents* dateThereComponents = [[NSDateComponents alloc] init];
                                        dateThereComponents.day = [[originalDateString substringWithRange:NSMakeRange(8, 2)] intValue];
                                        dateThereComponents.month = [[originalDateString substringWithRange:NSMakeRange(5, 2)] intValue];
                                        dateThereComponents.year = [[originalDateString substringWithRange:NSMakeRange(0, 4)] intValue];
                                        
                                        NSCalendar* transformationCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                                        NSDate* finalDate = [transformationCalendar dateFromComponents:dateThereComponents];
                                        [dateThereComponents release];
                                        [transformationCalendar release];
                                        
                                        
                                        //... set it
                                        newSession.date = finalDate;
                                    }
                                    else
                                        newSession.date = nil;
                                    
                                    
                                    //... and save it
                                    NSError *error = nil;
                                    if (![self.tableViewContext save:&error]) {
                                        
                                        NSLog(@"Fehler beim Speichern");
                                        
                                    }
                                }
                                
                                //If starttime is specified
                                if(![[session valueForKey:@"starttime"] isEqualToString:@"NULL"] && ![[session valueForKey:@"starttime"] isEqualToString:@""] && [session valueForKey:@"starttime"] != nil)
                                {
                                    NSString* startTimeString = [session valueForKey:@"starttime"];
                                    if(![startTimeString isEqualToString:@""])
                                    {
                                        //Create NSDate
                                        NSDateFormatter* startTimeConstructor = [[NSDateFormatter alloc] init];
                                        [startTimeConstructor setDateFormat:@"HH:mm"];
                                        NSDate* sessionStartTime = [startTimeConstructor dateFromString:startTimeString];
                                        
                                        //Set it
                                        newSession.starttime = sessionStartTime;
                                        [startTimeConstructor release];
                                        
                                        //Save it
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                }
                                else
                                {
                                    NSLog(@"Kein Starttime gefunden!");
                                }
                                
                                //If duration is given, save it!
                                if(![[session valueForKey:@"duration"] isEqualToString:@"NULL"] && ![[session valueForKey:@"duration"] isEqualToString:@""] && [session valueForKey:@"duration"] != nil)
                                {
                                    newSession.duration = [session valueForKey:@"duration"];
                                    NSError *error = nil;
                                    if (![self.tableViewContext save:&error]) {
                                        
                                        NSLog(@"Fehler beim Speichern");
                                        
                                    }
                                }
                                
                                //If roomname is given, save it!
                                if(![[session valueForKey:@"roomname"] isEqualToString:@"NULL"] && ![[session valueForKey:@"roomname"] isEqualToString:@""] && [session valueForKey:@"roomname"] != nil)
                                {
                                    NSLog(@"Raumname entdeckt!");
                                    newSession.roomname = [session valueForKey:@"roomname"]; 
                                    NSError *error = nil;
                                    if (![self.tableViewContext save:&error]) {
                                        
                                        NSLog(@"Fehler beim Speichern");
                                        
                                    }
                                }
                                
                                //If venue is given
                                if(![[session valueForKey:@"venue"] isEqualToString:@"NULL"] && ![[session valueForKey:@"venue"] isEqualToString:@""] && [session valueForKey:@"venue"] != nil)
                                {
                                    //Check whether a venue with such a name exists in core data.
                                    NSFetchRequest *existsVenueWithThisNameRequest = [[NSFetchRequest alloc] init];
                                    [existsVenueWithThisNameRequest setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                    existsVenueWithThisNameRequest.entity = [NSEntityDescription entityForName:@"Venue" inManagedObjectContext:self.tableViewContext];
                                    existsVenueWithThisNameRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@",[session valueForKey:@"venue"]];
                                    NSError* existsError = nil;
                                    
                                    Venue *venueWithThisName = [[self.tableViewContext executeFetchRequest:existsVenueWithThisNameRequest error:&existsError] lastObject];
                                    [existsVenueWithThisNameRequest release];
                                    
                                    if(!existsError && venueWithThisName)
                                    {
                                        //If there was no error and venue exists, save it to the invenue property
                                        newSession.invenue = venueWithThisName;
                                        
                                        //Save all changes
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                }
                                
                                
                                //If tags are given
                                if(![[session objectForKey:@"tags"] isEqualToString:@"NULL"] && [session objectForKey:@"tags"] != nil)
                                {
                                    //Get the array of all tags specified for this session
                                    NSArray *tags = [[session objectForKey:@"tags"] componentsSeparatedByString:@", "];
                                    for (NSString *currentTag in tags) {
                                        //For each tag check whether such a tag exists in core data
                                        
                                        NSFetchRequest *tagWithSameNameAlreadyExistsRequest = [[NSFetchRequest alloc] init];
                                        [tagWithSameNameAlreadyExistsRequest setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                        tagWithSameNameAlreadyExistsRequest.entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:self.tableViewContext];
                                        tagWithSameNameAlreadyExistsRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@",currentTag];
                                        NSError *tagWithSameNameError = nil;
                                        
                                        Tag* tagWithSameName = [[self.tableViewContext executeFetchRequest:tagWithSameNameAlreadyExistsRequest error:&tagWithSameNameError] lastObject];
                                        [tagWithSameNameAlreadyExistsRequest release];
                                        
                                        if(!tagWithSameNameError)
                                        {
                                            //If there was no error...
                                            if(tagWithSameName != nil)
                                            {
                                                //.. and tag exists
                                                
                                                //Set relation between session and tag
                                                
                                                [newSession addHasTagsObject:tagWithSameName];
                                                NSError *savingError;
                                                if(![self.tableViewContext save:&savingError])
                                                {
                                                    NSLog(@"Error while adding a tag to the session!");
                                                }
                                            }
                                            else
                                            {
                                                //Else tag does not exist yet
                                                
                                                //Create the tag
                                                Tag *newTag = [Tag initTagWithContext:self.tableViewContext andStore:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]];
                                                //.. gib neuem Tag den Namen
                                                newTag.name = currentTag;
                                                
                                                //Add relation between session and tag
                                                [newSession addHasTagsObject:newTag];
                                                
                                                //Save changes
                                                NSError *savingError;
                                                if(![self.tableViewContext save:&savingError])
                                                {
                                                    NSLog(@"Error while creating a tag to add it to the session!");
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        NSLog(@"Parsing of session.csv failed!");
                    }
                    [parser release];
                    [csvPool drain];
                }
                
                NSRange xmlRange = [[self.sessionURL absoluteString] rangeOfString:@".xml" options:NSCaseInsensitiveSearch];
                
                if(xmlRange.location != NSNotFound)
                {
                    //If session file is given in XML format, set up the XML parser
                    TBXML* tbxml = [[TBXML tbxmlWithURL:self.sessionURL] retain];
                    TBXMLElement * root = tbxml.rootXMLElement;
                    
                    if (root)
                    {
                        //If root was found in XML document structure
                        
                        TBXMLElement* session = [TBXML childElementNamed:@"session" parentElement:root];
                        while (session != nil)
                        {
                            NSLog(@"Session found!");
                            //Do for every session the following
                            
                            TBXMLElement* sessionid = [TBXML childElementNamed:@"sessionid" parentElement:session];
                            if(sessionid && ![[TBXML textForElement:sessionid] isEqualToString:@""])
                            {
                                //Check whether session already exists
                                NSFetchRequest *isEqual = [[NSFetchRequest alloc] init];
                                [isEqual setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                isEqual.entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
                                isEqual.predicate = [NSPredicate predicateWithFormat:@"sessionid = %@",[TBXML textForElement:sessionid]];
                                NSError *sameIDError = nil;
                               
                                Session *sameIDSession = [[self.tableViewContext executeFetchRequest:isEqual error:&sameIDError] lastObject];
                                [isEqual release];
                                
                                if (!sameIDError && !sameIDSession && ![[TBXML textForElement:sessionid] isEqualToString:@""])
                                {                  
                                    NSLog(@"Add new session!");
                                    //Session with same ID does not exists, hence create new session and set properties
                                    Session* newSession = [Session initSessionInContext:self.tableViewContext andStore:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]];
                                    
                                    //Set ID
                                    newSession.sessionid = [TBXML textForElement:sessionid];
                                    
                                    //Set title and abstract
                                    TBXMLElement* title = [TBXML childElementNamed:@"title" parentElement:session];
                                    TBXMLElement* abstract = [TBXML childElementNamed:@"abstract" parentElement:session];
                                    
                                    if(title)
                                    {
                                        newSession.title = [TBXML textForElement:title];
                                    }
                                    
                                    if(abstract)
                                    {
                                        newSession.abstract = [TBXML textForElement:abstract];
                                    }                                    
                                    
                                    //Set already over property to false here. Whether session is already finished will be checked in another method.
                                    [newSession setAlreadyover:[NSNumber numberWithBool:NO]];
                                    
                                    //Set fav state
                                    newSession.isfaved = [favedDictionary objectForKey:[TBXML textForElement:sessionid]];
                                    
                                    //Save settings
                                    NSError *error = nil;
                                    if (![self.tableViewContext save:&error]) {
                                        
                                        NSLog(@"Fehler beim Speichern");
                                        
                                    }
                                    
                                    TBXMLElement* speakers = [TBXML childElementNamed:@"speakers" parentElement:session];
                                    if(speakers)
                                    {
                                        TBXMLElement* speakerid = [TBXML childElementNamed:@"speakerid" parentElement:speakers];
                                        while(speakerid != nil)
                                        {
                                            //For each speaker
                                            
                                            //... check whether there is a user with the same ID
                                            NSFetchRequest *existsSpeakerWithID = [[NSFetchRequest alloc] init];
                                            [existsSpeakerWithID setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                            existsSpeakerWithID.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.tableViewContext];
                                            existsSpeakerWithID.predicate = [NSPredicate predicateWithFormat:@"userid = %@", [TBXML textForElement:speakerid]];
                                            NSError *sameSpeakerError = nil;
                                            User *sameIDUser = [[self.tableViewContext executeFetchRequest:existsSpeakerWithID error:&sameSpeakerError] lastObject];                       
                                            [existsSpeakerWithID release];
                                            if(!sameSpeakerError && sameIDUser)
                                            {
                                                //If such a user exists, check whether user has role named 'speaker'.
                                                
                                                if([sameIDUser.role isEqualToString:@"speaker"] || [sameIDUser.role isEqualToString:@"invited_speaker"])
                                                {
                                                    //If this is the case, set the user as the speaker of the session

                                                    [newSession addHasSpeakersObject:sameIDUser];
                                                    
                                                    
                                                    //Save settings
                                                    NSError *error = nil;
                                                    if (![self.tableViewContext save:&error]) {
                                                        
                                                        NSLog(@"Fehler beim Speichern");
                                                        
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                NSLog(@"Error or speaker does not exist yet.");
                                            }
                                            
                                            speakerid = [TBXML nextSiblingNamed:@"speakerid" searchFromElement:speakerid];
                                        }
                                    }
                                    
                                    TBXMLElement* dateElement = [TBXML childElementNamed:@"date" parentElement:session];
                                    
                                    if(dateElement != nil && ![[TBXML textForElement:dateElement] isEqualToString:@""])
                                    {
                                        NSString* dateString = [TBXML textForElement:dateElement];
                                        NSLog(@"Angegebenes Datum: %@", dateString);
                                        
                                        //If date string is set, compute NSDate
                                        NSDateFormatter* dateConstructor = [[NSDateFormatter alloc] init];
                                        [dateConstructor setDateFormat:@"YYYY:MM:dd"];
                                        NSDate* sessionDate = [dateConstructor dateFromString:dateString];
                                        [dateConstructor release];
                                        
                                        NSDateFormatter* stringFromOriginalDate = [[NSDateFormatter alloc] init];
                                        [stringFromOriginalDate setDateFormat:@"YYYY:MM:dd"];
                                        NSString* originalDateString = [stringFromOriginalDate stringFromDate:sessionDate];
                                        [stringFromOriginalDate release];
                                        
                                        if(originalDateString != nil)
                                        {
                                            NSDateComponents* dateThereComponents = [[NSDateComponents alloc] init];
                                            dateThereComponents.day = [[originalDateString substringWithRange:NSMakeRange(8, 2)] intValue];
                                            dateThereComponents.month = [[originalDateString substringWithRange:NSMakeRange(5, 2)] intValue];
                                            dateThereComponents.year = [[originalDateString substringWithRange:NSMakeRange(0, 4)] intValue];
                                            
                                            NSCalendar* transformationCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                                            NSDate* finalDate = [transformationCalendar dateFromComponents:dateThereComponents];
                                            [dateThereComponents release];
                                            [transformationCalendar release];
                                            
                                            //and save it to the date property
                                            newSession.date = finalDate; 
                                        }
                                        else
                                            newSession.date = nil;
                                        
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }                   
                                    
                                    
                                    TBXMLElement* startTimeElement = [TBXML childElementNamed:@"starttime" parentElement:session];
                                    if(startTimeElement && ![[TBXML textForElement:startTimeElement] isEqualToString:@""])
                                    {
                                        //If starttime of session is specified
                                        NSString* startTimeString = [TBXML textForElement:startTimeElement];
                                        if(![startTimeString isEqualToString:@""])
                                        {
                                            //Compute NSDate out of it
                                            NSDateFormatter* startTimeConstructor = [[NSDateFormatter alloc] init];
                                            [startTimeConstructor setDateFormat:@"HH:mm"];
                                            NSDate* sessionStartTime = [startTimeConstructor dateFromString:startTimeString];
                                            
                                            //Set it as the property
                                            newSession.starttime = sessionStartTime;
                                            [startTimeConstructor release];
                                            
                                            //Save changes
                                            NSError *error = nil;
                                            if (![self.tableViewContext save:&error]) {
                                                
                                                NSLog(@"Fehler beim Speichern");
                                                
                                            }
                                        }
                                    }
                                    else
                                    {
                                        NSLog(@"Kein Starttime gefunden!");
                                    }
                                    
                                    
                                    TBXMLElement* durationElement = [TBXML childElementNamed:@"duration" parentElement:session];
                                    if(durationElement && ![[TBXML textForElement:durationElement] isEqualToString:@""])
                                    {
                                        //If duration is specified, set it as the duration property
                                        newSession.duration = [TBXML textForElement:durationElement];
                                        
                                        //Save it.
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    
                                    TBXMLElement* roomname = [TBXML childElementNamed:@"roomname" parentElement:session];
                                    if(roomname && ![[TBXML textForElement:roomname] isEqualToString:@""])
                                    {
                                        //If roomname is specified, set it as the corresponding property.
                                        newSession.roomname = [TBXML textForElement:roomname]; 
                                        NSError *error = nil;
                                        if (![self.tableViewContext save:&error]) {
                                            
                                            NSLog(@"Fehler beim Speichern");
                                            
                                        }
                                    }
                                    
                                    TBXMLElement* venue = [TBXML childElementNamed:@"venue" parentElement:session];
                                    
                                    if(venue)
                                    {
                                        //If venue is specified, search for the same venue name in saved data
                                        NSFetchRequest *existsVenueWithThisNameRequest = [[NSFetchRequest alloc] init];
                                        [existsVenueWithThisNameRequest setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                        existsVenueWithThisNameRequest.entity = [NSEntityDescription entityForName:@"Venue" inManagedObjectContext:self.tableViewContext];
                                        existsVenueWithThisNameRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@",[TBXML textForElement:venue]];
                                        NSError* existsError = nil;
                                        
                                        Venue *venueWithThisName = [[self.tableViewContext executeFetchRequest:existsVenueWithThisNameRequest error:&existsError] lastObject];
                                        [existsVenueWithThisNameRequest release];
                                        
                                        if(!existsError && venueWithThisName)
                                        {
                                            //If there was no error and venue exists, set the property and save changes.
                                            newSession.invenue = venueWithThisName;
                                            NSError *error = nil;
                                            if (![self.tableViewContext save:&error]) {
                                                
                                                NSLog(@"Fehler beim Speichern");
                                                
                                            }
                                        }
                                    }
                                    
                                    TBXMLElement *tags = [TBXML childElementNamed:@"tags" parentElement:session];
                                    if(tags)
                                    {
                                        //If the session is tagged
                                        
                                        TBXMLElement *tag = [TBXML childElementNamed:@"tag" parentElement:tags];
                                        while(tag)
                                        {
                                            //Check for each tag, whether there exists such a tag in saved data
                                            
                                            NSFetchRequest *tagWithSameNameAlreadyExistsRequest = [[NSFetchRequest alloc] init];
                                            [tagWithSameNameAlreadyExistsRequest setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
                                            tagWithSameNameAlreadyExistsRequest.entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:self.tableViewContext];
                                            tagWithSameNameAlreadyExistsRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@",[TBXML textForElement:tag]];
                                            NSError *tagWithSameNameError = nil;
                                            
                                            Tag* tagWithSameName = [[self.tableViewContext executeFetchRequest:tagWithSameNameAlreadyExistsRequest error:&tagWithSameNameError] lastObject];
                                            [tagWithSameNameAlreadyExistsRequest release];
                                            
                                            if(!tagWithSameNameError)
                                            {
                                                //If there was no error...
                                                if(tagWithSameName != nil)
                                                {
                                                    //... and tag already exists.
                                                    
                                                    //Set relationship beween session and tag.
                                                    [newSession addHasTagsObject:tagWithSameName];
                                                    
                                                    //Save changes
                                                    NSError *savingError;
                                                    if(![self.tableViewContext save:&savingError])
                                                    {
                                                        NSLog(@"Error while setting relationship between tag and session");
                                                    }
                                                }
                                                else
                                                {
                                                    //If tag does not exist yet... create it!
                                                    Tag *newTag = [Tag initTagWithContext:self.tableViewContext andStore:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]];

                                                    //Set the name of the tag
                                                    newTag.name = [TBXML textForElement:tag];
                                                    
                                                    //Set relationship between tag and session
                                                    [newSession addHasTagsObject:newTag];
                                                    
                                                    //Save changes
                                                    NSError *savingError;
                                                    if(![self.tableViewContext save:&savingError])
                                                    {
                                                        NSLog(@"Fehler beim Erstellen & Hinzufügen eines Tags zum Benutzer!");
                                                    }
                                                }
                                            }
                                            tag = [TBXML nextSiblingNamed:@"tag" searchFromElement:tag];
                                        }
                                    }
                                }
                            }
                            session = [TBXML nextSiblingNamed:@"session" searchFromElement:session];
                        }
                    }
                    
                    [tbxml release];
                }
                
                [favedDictionary release];
            }
            
            
            reloadProcessBlock();
        }
        else
        {
            //If no file was reachable online...
            if(!self.problemWithData)
            {
                //... and there was no problem with data before --> inform the user
                UIAlertView* canNotReloadAlertView = [[UIAlertView alloc] initWithTitle:loading_data_error_header_en message:loading_data_error_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [canNotReloadAlertView show];
                [canNotReloadAlertView release];
            }
            
            //Set the problemWithData property to yes.
            self.problemWithData = YES;
            
            //Fire the reloadProcessBlock
             reloadProcessBlock();
        }        
    }
    else
    {       
        //If connection failed...
        if(!self.isNotSyncing)
        {
            //... and App was syncing before, inform the user
            UIAlertView* canNotReloadAlertView = [[UIAlertView alloc] initWithTitle:no_internet_connection_header_en message:no_internet_connection_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [canNotReloadAlertView show];
            [canNotReloadAlertView release];
        }
        
        //Update the property
        self.isNotSyncing = TRUE;

        //Fire the reloadProcessBlock
        reloadProcessBlock();
    }
    
    //Open access to core data again, because all core data changes were done
    [self.tableViewContext unlock];
    
    //Set isReloadingData to false, because reload is over now
    self.isReloadingData = FALSE;
    
    //Block further processing for 0.01 seconds to update the view
    [NSThread sleepForTimeInterval: 0.01];
    
    //Remove update screen from view and show general overview table to the user
    [self dismissModalViewControllerAnimated:YES];
}


- (NSString *) setDetailTextLabelForIndexPath:(NSIndexPath *)indexPath OrSession:(Session *)inputSession
{
    /*
     
            This method to respond on requests of showing all informations about a session (title, speakers etc.) which is the printVersion and for requesting a countdown update (means how long it takes that the session starts (not printingVersion).
     
     */
    
    //Create the output string
    NSString *detailTextLabel = [[[NSString alloc] init] autorelease];
    
    //Create a bool to represent whether the method is in print mode or not    
    BOOL printVersion;
    
    //If a session was submitted with the request, it is a countdown request. Otherwise it's a request for a print version. 
    
    if(indexPath != nil || inputSession != nil)
    {
        Session *viewingSession;
        if(indexPath != nil)
        {
            viewingSession = [self.mutableFetchResults objectAtIndex:indexPath.row];
            printVersion = true;
        }
        
        if(inputSession != nil)
        {
            viewingSession = inputSession;
            printVersion = false;
        }
    
    //If a print version is needed
    if(printVersion)
    {
        //If the session has already speakers specified
        if([viewingSession.hasSpeakers count] != 0)
        {
            NSMutableString* detailedText = [[NSMutableString alloc] init];
            int speakerloop = 0;
            for(User* speakerOfSession in viewingSession.hasSpeakers)
            {
                //For each user
                if (speakerloop < 3) //Label with only allows to print out three speakers
                {
                    //If it's the first, second or third processed speaker
                    
                    if(speakerloop > 0 && speakerloop != 3)
                    {
                        //If it's the second or third speaker, add a semicolon in front
                        [detailedText appendString:@", "];
                    }
                    //For each speaker do a label with type 'firstname lastname' and concatenate them with a semicolon
                    
                    if(speakerOfSession.firstname)  
                        [detailedText appendString:speakerOfSession.firstname];
                    
                    if(speakerOfSession.firstname && speakerOfSession.lastname)
                        [detailedText appendString:@" "];                    
                    
                    if(speakerOfSession.lastname)
                        [detailedText appendString:speakerOfSession.lastname];
                }
                else
                {
                    //If there are already three printed speaker labels, add 'et al.' and break out of the loop
                    [detailedText appendString:@" et al."];
                    break;
                }
                speakerloop = speakerloop + 1;
            }
            
            //Add a line break
            [detailedText appendString:@"\n"];
            detailTextLabel = [[detailedText copy] autorelease];
            [detailedText release];
        }
        else
        {
            //If session has no speakers, print out a corresponding label
            detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%@ \n",no_speakers_english];
        }
    }
    
    
    NSString* sessionDateString = @"";
    NSString* sessionTimeString = @"";
    if(viewingSession.date != nil)
    {
        //If session has specified a date, print it in format 'dd.MM.YYYY '
        
        
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd.MM.YYYY"];
        sessionDateString = [dateFormatter stringFromDate:viewingSession.date];
        detailTextLabel = [detailTextLabel stringByAppendingString:[dateFormatter stringFromDate:viewingSession.date]];
        [dateFormatter release];
        detailTextLabel = [detailTextLabel stringByAppendingString:@" "];
    }
    
    if(viewingSession.starttime != nil)
    {
        //If session has specified a start time add it behind the 'dd.MM.YYYY ' label
        
        NSDateFormatter* startTimeFormatter = [[NSDateFormatter alloc] init];
        [startTimeFormatter setDateFormat:@"HH:mm"];
        
        sessionTimeString = [startTimeFormatter stringFromDate:viewingSession.starttime];
        detailTextLabel = [detailTextLabel stringByAppendingString:[startTimeFormatter stringFromDate:viewingSession.starttime]];
        [startTimeFormatter release];
    }
    
    //Try to fetch conference details
    [self.tableViewContext lock];
    NSFetchRequest *getConferenceRequest = [[NSFetchRequest alloc] init];
    getConferenceRequest.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.tableViewContext];
    getConferenceRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
       
    NSError* getConferenceError = nil;

    Conference *viewingConference = [[self.tableViewContext executeFetchRequest:getConferenceRequest error:&getConferenceError] lastObject];
        
    if(viewingConference != nil)
    {
        if(viewingConference.timezone != nil && ![viewingConference.timezone isEqualToString:@""])
        {
            //If conference has specified a timezone string where the name of the timezone is described, get NSTimeZone value of it by comparing with list of all timezones available in iOS
            NSArray* timeZonesArray = [NSTimeZone knownTimeZoneNames];
            
            bool timeZoneIsSet = false;
            for (NSString* timeZoneInArray in timeZonesArray)
            {
                if([timeZoneInArray isEqualToString:viewingConference.timezone])
                {
                    //If there is a match, set self.conferenceTimeZone value
                    self.conferenceTimeZone = [[[NSTimeZone alloc] initWithName:timeZoneInArray] autorelease];
                    timeZoneIsSet = true;
                }
            }
                
            if(!timeZoneIsSet)
            {
                //If there is no timezone specified, set as default the system time zone of the smartphone
                self.conferenceTimeZone = [NSTimeZone systemTimeZone];
            }
         }
    }
        
    [getConferenceRequest release];
        
    [self.tableViewContext unlock];
    
    if(!([sessionDateString isEqualToString:@""] && [sessionTimeString isEqualToString:@""]))
    {
        if(![sessionDateString isEqualToString:@""])
        {
            //If session date is set...
            if(![sessionTimeString isEqualToString:@""])
            {
                //if starttime is set
                NSCalendar* myHomeCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                NSDate* nowHere = [NSDate date];
                
                //Combine sessiondate and sessiontime in a new NSDate variable dateThere including the conference timezone. So it describes the date there where the conference takes place
                
                NSDateComponents* dateThereComponents = [[myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:viewingSession.date] retain];
                dateThereComponents.hour = [[sessionTimeString substringWithRange:NSMakeRange(0, 2)] intValue];
                dateThereComponents.minute = [[sessionTimeString substringWithRange:NSMakeRange(3, 2)] intValue];
                dateThereComponents.timeZone = self.conferenceTimeZone;
                
                //Create date, which represents the local date where the conference takes place
                NSDate* dateThere = [myHomeCalendar dateFromComponents:dateThereComponents];
                [dateThereComponents release];
                
                //Compare the date here (where the smartphone is located) and the date when & where the conference takes place
                NSTimeInterval dateDifference = [dateThere timeIntervalSinceDate:nowHere];
                
                NSDate *date1 = [[NSDate alloc] init];
                NSDate *date2 = [[NSDate alloc] initWithTimeInterval:dateDifference sinceDate:date1]; 
                
                //Get back the countdown time until session takes place
                NSDateComponents* difference = [myHomeCalendar components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit  fromDate:date1 toDate:date2 options:0];
                [date1 release];
                [date2 release];
                
                [myHomeCalendar release];
                
                //Then finally bring these informations to a label
                
                bool liegtInVergangenheit = false;
                if(difference.second < 0 || difference.minute < 0 || difference.hour < 0 || difference.day < 0 || difference.month < 0 || difference.year < 0)
                    liegtInVergangenheit = true;
                
                if(!liegtInVergangenheit)
                {
                    if(printVersion)
                    {
                        //If date is not over yet
                        bool isYearZero, isMonthZero, isDayZero, isHourZero, isMinuteZero, isSecondZero;
                        isYearZero = false;
                        isMonthZero = false;
                        isDayZero = false;
                        isHourZero = false;
                        isMinuteZero = false;
                        isSecondZero = false;
                        
                        switch (difference.year) {
                            case 0:
                                isYearZero = true;
                                break;
                            case 1:
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", year_en];
                                break;
                            default:
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ", difference.year ,years_en];
                                break;
                        }
                        
                        switch (difference.month) {
                            case 0:
                                isMonthZero = true;
                                break;       
                            case 1:
                                if(isYearZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", month_en];
                                break;
                            default:
                                if(isYearZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ", difference.month  , months_en];
                                break;
                        }
                        
                        switch (difference.day) {
                            case 0:
                                isDayZero = true;
                                break;       
                            case 1:
                                if(isYearZero && isMonthZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", day_en];
                                break;
                            default:
                                if(isYearZero && isMonthZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ", difference.day ,days_en];
                                break;
                        }
                        
                        switch (difference.hour) {
                            case 0:
                                isHourZero = true;
                                break;       
                            case 1:
                                if(isYearZero && isMonthZero && isDayZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ",hour_en];
                                break;
                            default:
                                if(isYearZero && isMonthZero && isDayZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ", difference.hour ,hours_en];
                                break;
                        }
                        
                        switch (difference.minute) {
                            case 0:
                                isMinuteZero = true;
                                break;       
                            case 1:
                                if(isYearZero && isMonthZero && isDayZero && isHourZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", minute_en];
                                break;
                            default:
                                if(isYearZero && isMonthZero && isDayZero && isHourZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ", difference.minute , minutes_en];
                                break;
                        }
                        
                        switch (difference.second) {
                            case 0:
                                isSecondZero = true;
                                break;       
                            case 1:
                                break;
                            default:
                                break;
                        }
                        
                        //If startdate is exactly reached
                        if(isYearZero && isMonthZero && isDayZero && isHourZero && isMinuteZero && isSecondZero)
                            detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@",starts_now_en]; 
                    }
                }
                else
                {
                    //If session started already
                    NSCalendar* myHomeCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                    NSDate* nowHere = [NSDate date];
                    
                    //Combine session date and time plus duration of the session and compute enddate
                    
                    NSDateComponents* dateThereComponents = [[myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:viewingSession.date] retain];
                    dateThereComponents.hour = [[sessionTimeString substringWithRange:NSMakeRange(0, 2)] intValue];
                    dateThereComponents.minute = [[sessionTimeString substringWithRange:NSMakeRange(3, 2)] intValue];
                    
                    
                    int duration_all = [viewingSession.duration intValue];
                    int duration_hours = duration_all/60;
                    int duration_minutes = [viewingSession.duration intValue] - duration_hours * 60;
                                        
                    dateThereComponents.hour = dateThereComponents.hour + duration_hours;
                    dateThereComponents.minute = dateThereComponents.minute + duration_minutes;
                    dateThereComponents.timeZone = self.conferenceTimeZone;
                    
                    //Create end date where the conference takes place
                    NSDate* dateThere = [myHomeCalendar dateFromComponents:dateThereComponents];
                    [dateThereComponents release];
                    
                    NSTimeInterval dateDifference = [dateThere timeIntervalSinceDate:nowHere];
                    
                    NSDate *date1 = [[NSDate alloc] init];
                    NSDate *date2 = [[NSDate alloc] initWithTimeInterval:dateDifference sinceDate:date1]; 
                    
                    //Compute countdown time again
                    NSDateComponents* difference = [myHomeCalendar components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit  fromDate:date1 toDate:date2 options:0];
                    [date1 release];
                    [date2 release];
                    
                    [myHomeCalendar release];
                    
                    bool liegtKomplettInVergangenheit = false;
                    if(difference.second < 0 || difference.minute < 0 || difference.hour < 0 || difference.day < 0 || difference.month < 0 || difference.year < 0)
                        liegtKomplettInVergangenheit = true;
                    
                    if(!liegtKomplettInVergangenheit)
                    {
                        if(printVersion)
                        {
                            //If session end is not past now
                            bool isYearZero, isMonthZero, isDayZero, isHourZero, isMinuteZero, isSecondZero;
                            isYearZero = false;
                            isMonthZero = false;
                            isDayZero = false;
                            isHourZero = false;
                            isMinuteZero = false;
                            isSecondZero = false;
                            
                            switch (difference.year) {
                                case 0:
                                    isYearZero = true;
                                    break;
                                case 1:
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ",still_running_en];
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", year_en];
                                    break;
                                default:
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_running_en];
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ",difference.year, years_en];
                                    break;
                            }
                            
                            switch (difference.month) {
                                case 0:
                                    isMonthZero = true;
                                    break;       
                                case 1:
                                    if(isYearZero)
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ",still_running_en];
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", month_en];
                                    break;
                                default:
                                    if(isYearZero)
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ",still_running_en];
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ",difference.month, months_en];
                                    break;
                            }
                            
                            switch (difference.day) {
                                case 0:
                                    isDayZero = true;
                                    break;       
                                case 1:
                                    if(isYearZero && isMonthZero)
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ",still_running_en];
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", day_en];
                                    break;
                                default:
                                    if(isYearZero && isMonthZero)
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ",still_running_en];
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ",difference.day, days_en];
                                    break;
                            }
                            
                            switch (difference.hour) {
                                case 0:
                                    isHourZero = true;
                                    break;       
                                case 1:
                                    if(isYearZero && isMonthZero && isDayZero)
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ",still_running_en];
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", hour_en];
                                    break;
                                default:
                                    if(isYearZero && isMonthZero && isDayZero)
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ",still_running_en];
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ",difference.hour, hours_en];
                                    break;
                            }
                            
                            switch (difference.minute) {
                                case 0:
                                    isMinuteZero = true;
                                    break;       
                                case 1:
                                    if(isYearZero && isMonthZero && isDayZero && isHourZero)
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ",still_running_en];
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", minute_en];
                                    break;
                                default:
                                    if(isYearZero && isMonthZero && isDayZero && isHourZero)
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ",still_running_en];
                                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ",difference.minute, minutes_en];
                                    break;
                            }
                                                       
                            switch (difference.second) {
                                case 0:
                                    isSecondZero = true;
                                    break;       
                                case 1:
                                    break;
                                default:
                                    break;
                            }
                            
                            //If enddate is exactly now
                            if(isYearZero && isMonthZero && isDayZero && isHourZero && isMinuteZero && isSecondZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@",just_over_en];
                        }
                    }
                    else
                    {
                        //If session is already over
                        detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ",already_over_en];
                        
                        //Set the already over property
                        [viewingSession setAlreadyover:[NSNumber numberWithBool:YES]];
                        NSError *saveError = nil;
                        if(![self.tableViewContext save:&saveError])
                            NSLog(@"Fehler beim Speichern des alreadyOver Wertes! %@",saveError.description);
                    }
                }
                
            }
            else
            {          
                
                //If no time was set. Compute difference based on days.
                NSCalendar* myHomeCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                NSDate* nowHere = [NSDate date];
                
                NSDateComponents* dateHereWithoutTime = [[myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:nowHere] retain];
                dateHereWithoutTime.timeZone = [NSTimeZone systemTimeZone];
                NSDate* dateHereWithOutTimeDate = [myHomeCalendar dateFromComponents:dateHereWithoutTime];
                [dateHereWithoutTime release];
                               
                NSDateComponents* dateThereComponents = [[myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:viewingSession.date] retain];
                dateThereComponents.timeZone = self.conferenceTimeZone;
                
                
                //Create local date where the conference takes place
                NSDate* dateThere = [myHomeCalendar dateFromComponents:dateThereComponents];
                [dateThereComponents release];
                
                //Compute the countdown
                NSTimeInterval dateDifference = [dateThere timeIntervalSinceDate:dateHereWithOutTimeDate];
                
                NSDate *date1 = [[NSDate alloc] init];
                NSDate *date2 = [[NSDate alloc] initWithTimeInterval:dateDifference sinceDate:date1]; 
                
                NSDateComponents* difference = [myHomeCalendar components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date1 toDate:date2 options:0];
                [date1 release];
                [date2 release];
                
                [myHomeCalendar release];
                
                //Compute labels
                
                bool liegtInVergangenheit = false;
                if(difference.day < 0 || difference.month < 0 || difference.year < 0)
                    liegtInVergangenheit = true;
                
                if(!liegtInVergangenheit)
                {
                    if(printVersion)
                    {
                        bool isYearZero, isMonthZero, isDayZero;
                        isYearZero = false;
                        isMonthZero = false;
                        isDayZero = false;
                        //If session has not begun yet
                        
                        switch (difference.year) {
                            case 0:
                                isYearZero = true;
                                break;
                            case 1:
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", year_en];
                                break;
                            default:
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ",difference.year, years_en];
                                break;
                        }
                        
                        switch (difference.month) {
                            case 0:
                                isMonthZero = true;
                                break;       
                            case 1:
                                if(isYearZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", month_en];
                                break;
                            default:
                                if(isYearZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n %@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ",difference.month, months_en];
                                break;
                        }
                        
                        switch (difference.day) {
                            case 0:
                                isDayZero = true;
                                break;       
                            case 1:
                                if(isYearZero && isMonthZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"1 %@ ", day_en];
                                break;
                            default:
                                if(isYearZero && isMonthZero)
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@ ", still_en];
                                detailTextLabel = [detailTextLabel stringByAppendingFormat:@"%i %@ ",difference.day, days_en];
                                break;
                        }
                        
                        if(isDayZero && isMonthZero && isYearZero)
                        {
                            //If session takes place today
                            detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n%@", today_en];
                        }
                    }
                    
                }
                else
                {
                    //If session date is in the past
                    detailTextLabel = [detailTextLabel stringByAppendingFormat:@"\n %@ ", already_over_en];
                    
                    //set the already over property
                    [viewingSession setAlreadyover:[NSNumber numberWithBool:YES]];
                    NSError *saveError = nil;
                    if(![self.tableViewContext save:&saveError])
                        NSLog(@"Fehler beim Speichern des alreadyOver Wertes!");
                }
            }
        }
    }
    return detailTextLabel;
    [detailTextLabel release];
  }
    return nil;
}

- (void)reloadStream
{
    //This method provides a code block which gets active after reloading data
    self.hideOldSessions = FALSE;
    [self reloadXMLFilesWithBlock:^(){
    if(self.isDelegated)
    {
        //If upload process was forced by SpeakerTableView, set delegate again to false, because upload is over and inform the speaker instances that the update is finished.
        self.isDelegated = FALSE;
        if(self.delegater != nil)
        {
             NSLog(@"Update is finished!");
             [self.delegater updateIsFinished];
        }
            
    }
    
    //If the number of clicks on the right fav button is odd, show only faved sessions, else show general overview of all sessions (including/excluding sessions which are already finished)
    if(rightButtonCalls % 2 == 1)
    {
        [self.tableViewContext lock];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
        [request setEntity:entity];
        
        if(self.hideOldSessions)
            request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@ AND alreadyover = %@", [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
        else
            request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@", [NSNumber numberWithBool:YES]];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
        NSSortDescriptor *sortDescriptorTime = [[NSSortDescriptor alloc] initWithKey:@"starttime" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor,sortDescriptorTime, nil];
        
        [request setSortDescriptors:sortDescriptors];
        
        [sortDescriptors release];
        
        [sortDescriptor release];
        [sortDescriptorTime release];
        NSError *error = nil;

        self.mutableFetchResults = [[[self.tableViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
        
        if (self.mutableFetchResults == nil) {
            
            // Handle the error.
            NSLog(@"Fav Array is empty");
            
        }
        [request release];
        [self.tableViewContext unlock];
       
        if(!isSearching)
            [self.tableView reloadData];
        else
            [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
        
    }
    else
    {
        [self.tableViewContext lock];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
        [request setEntity:entity];
        
        if(self.hideOldSessions)
            request.predicate = [NSPredicate predicateWithFormat:@"alreadyover = %@", [NSNumber numberWithBool:NO]];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
        NSSortDescriptor *sortDescriptorTime = [[NSSortDescriptor alloc] initWithKey:@"starttime" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, sortDescriptorTime, nil];
        
        [request setSortDescriptors:sortDescriptors];
        
        [sortDescriptors release];
        
        [sortDescriptor release];
        [sortDescriptorTime release];
        NSError *error = nil;
        
        self.mutableFetchResults = [[[self.tableViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
        
        if (self.mutableFetchResults == nil) {
            
            // Handle the error.
            NSLog(@"Result Array is empty");
            
        }
        [request release];
        
        for (Session* currentSession in self.mutableFetchResults) {
            [self setDetailTextLabelForIndexPath:nil OrSession:currentSession];
        }      
        
        [self.tableViewContext unlock];
        
        
        if(!isSearching)
            [self.tableView reloadData];
        else
            [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
        
    }
                       
    }];
}

- (void)showHud
{
        //This method controls the timer (which runs tick method each minute in general) during reload by deactivate it before updating
        //Deaktiviere Timer 
        [reloadLabelTimer invalidate];
        reloadLabelTimer = nil;
    
        //Initiate reload process
        [self reloadStream];
            
        //Reactivate the reloadLabelTimer
        [reloadLabelTimer invalidate];
        reloadLabelTimer = [NSTimer timerWithTimeInterval:60.0 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:reloadLabelTimer forMode:NSRunLoopCommonModes]; //COMMMON MODE IST IRGENDWIE WICHTIG WEGEN DIDBECOMEACTIVE ETC.
        [reloadLabelTimer fire]; 
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.tableViewContext = nil;
    self.titleLabel = nil;
    self.favButton = nil;
    self.showOldSessionsButton = nil;
    self.sessionSearchBar = nil;
    //self.navigationItem.rightBarButtonItem = nil;
}

- (void)tick:(NSTimer *)theTimer
{
    //This method is called every minute during using this view. Hence it updates the countdown timer of each session every minute.
    
    //Set isReloadingLabels to true, because reload will be initiated now
    self.isReloadingLabels = TRUE;

    //If there is no data reload procedure
    if(!isReloadingData)
    {
        //Update the countdown labels of each session displayed currently (saved in mutableFetchResults
        for (Session* mySession in self.mutableFetchResults) {
            [self setDetailTextLabelForIndexPath:nil OrSession:mySession];
        }
        
        if(!isSearching)
            [self.tableView reloadData];
        else
            [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
        
    }
    
    //After update the countdown labels set the reloadingLabels variable to false again
    self.isReloadingLabels = FALSE;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"View will appear: sessiontableview!");
    [super viewWillAppear:animated];
    
    //After view appeared show actual saved data
    if(!isSearching)
        [self.tableView reloadData];
    else
        [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
    
    
    //Initiate the countdown label timer after view appeared
    [reloadLabelTimer invalidate];
    reloadLabelTimer = [NSTimer timerWithTimeInterval:60.0 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:reloadLabelTimer forMode:NSRunLoopCommonModes]; //COMMMON MODE IST IRGENDWIE WICHTIG WEGEN DIDBECOMEACTIVE ETC.
    [reloadLabelTimer fire]; 
        
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"View will disappear: sessiontableview!");
    [super viewWillDisappear:animated];
    
    //If view will disappear deactivate the timer
    
    [reloadLabelTimer invalidate];
    reloadLabelTimer = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (UIButton *)generateMeAButtonForTheHeader
{
    //This method returns a favorise button dynamically according to the current number of clicks on the button
    
    //First generate a UIButtun
    UIButton *favoritenButton = [[[UIButton alloc] initWithFrame:CGRectMake(270.0, 0.0, 40.0, 40.0)] autorelease];
    
    //If button is clicked, initiate showFav method
    [favoritenButton addTarget:self action:@selector(showFav) forControlEvents:UIControlEventTouchUpInside];
    
    //Make Button visible and user interaction enabled
    favoritenButton.alpha = 1.0;
    favoritenButton.enabled = TRUE;
    
    //Switch design between half filled star and filled star according to the number of clicks
    switch(rightButtonCalls%2)
    {
        case 0:
            [favoritenButton setImage:[UIImage imageNamed:@"half_checked.png"] forState:UIControlStateNormal];
            break;
            
        case 1:
            [favoritenButton setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateNormal];
            break;
    } 
    
    //Return the button
    return favoritenButton;
}

- (void) changeHideVariable
{
    //This method gets called when the user clicks on the hide/unhide old sessions button
    
    //First change bool variable to the negated value (from true to false and vice versa)
    self.hideOldSessions = !self.hideOldSessions; 
    
    [self.tableViewContext lock];
    
    //Then fetch the wanted entries
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
    [request setEntity:entity];
    if(rightButtonCalls%2 == 1)
    {
        //Will Favoriten sehen
        if(self.hideOldSessions)
            request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@ AND alreadyover = %@", [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
        else
            request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@", [NSNumber numberWithBool:YES]];
    }
    else
    {
        //Will keine Favoriten sehen
        if(self.hideOldSessions)
            request.predicate = [NSPredicate predicateWithFormat:@"alreadyover = %@", [NSNumber numberWithBool:NO]];
    }
    
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
    NSSortDescriptor *sortDescriptorTime = [[NSSortDescriptor alloc] initWithKey:@"starttime" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorDate,sortDescriptorTime, nil];
    
    [request setSortDescriptors:sortDescriptors];
    
    [sortDescriptors release];
    
    [sortDescriptorDate release];
    [sortDescriptorTime release];
    NSError *error = nil;
    
    //Save the wanted entries in the self.mutableFetchResults
    self.mutableFetchResults = [[[self.tableViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
    if (self.mutableFetchResults == nil) {
        
        // Handle the error.
        NSLog(@"Result Array is empty");
        
    }
    [request release];
    
    [self.tableViewContext unlock];
    
    
    //Then reload view with actual core data
    if(!isSearching)
        [self.tableView reloadData];
    else
        [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
    
    
    if(self.hideOldSessions)
        NSLog(@"Hide variable TRUE");
    else
        NSLog(@"Hide variable FALSE");
}

- (UIButton *)generateMeAButtonForHidingOldSssions
{
    //This method dynamically generates a hide button for the left side of the UITableView
    
    //First create new UIButton
    UIButton *hideButton = [[[UIButton alloc] initWithFrame:CGRectMake(10.0, 0.0, 40.0, 40.0)] autorelease];
    
    //Setup that changeHideVariable method gets called when the user clicks on the button
    [hideButton addTarget:self action:@selector(changeHideVariable) forControlEvents:UIControlEventTouchUpInside];
    
    //Set the button visible and user interaction enabled
    hideButton.alpha = 1.0;
    hideButton.enabled = TRUE;
    
    
    //Set the right picture according to the hide bool variable
    if(self.hideOldSessions)
    {
        [hideButton setImage:[UIImage imageNamed:@"hide.png"] forState:UIControlStateNormal];
    }
    else
    {
        [hideButton setImage:[UIImage imageNamed:@"dont_hide.png"] forState:UIControlStateNormal];
    }
    
    //Return the button
    return hideButton;
}

- (NSString *)getHeaderTitle
{
    //This method returns the header title of the view according to the number of clicks on the session overview
    switch (rightButtonCalls%2) {
        case 0:
            return session_overview_en;
            break;
            
        default:
            return faved_session_overview_en;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    //This method generates the main header view with all hide and fav buttons
	UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 40.0)];
    [customView setBackgroundColor:[UIColor whiteColor]];

	//Get Header Label
	self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	self.titleLabel.backgroundColor = [UIColor clearColor];
	self.titleLabel.opaque = NO;
	self.titleLabel.textColor = [UIColor blackColor];
	self.titleLabel.highlightedTextColor = [UIColor whiteColor];
	self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.titleLabel.frame = CGRectMake(290.0/4, 0.0, 300.0, 44.0);
    self.titleLabel.text = [self getHeaderTitle];
    
	// If you want to align the header text as centered
	// headerLabel.frame = CGRectMake(150.0, 0.0, 300.0, 44.0);
    
    //Create Fav-Button
    self.favButton = [[self generateMeAButtonForTheHeader] autorelease];
    
    //Create Hide/Show-Old-Sessions Button
    self.showOldSessionsButton = [[self generateMeAButtonForHidingOldSssions] autorelease];
   
    //Add all views to current view
	[customView addSubview:self.titleLabel];
    [customView addSubview:self.favButton];
    [customView addSubview:self.showOldSessionsButton];
    
    //Return the headerView
	return customView;
    [customView release];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //If 'search' button is clicked the focus gets out of the searchbar textfield
    [self.sessionSearchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    //User has begun to enter a search term
    
    //Hence show cancel button to cancel search
    self.sessionSearchBar.showsCancelButton = YES;
    
    //Don't autocorrect entries
    self.sessionSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    
    //Set isSearching variable to true
    self.isSearching = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    //If the user clicks on the cancel button, hence wants to cancel search
    
    //Set isSearching to false
    self.isSearching = FALSE;
    
    //Reset searchtext
    self.sessionSearchBar.text = @"";
    
    //Remove cancel button
    self.sessionSearchBar.showsCancelButton = NO;
    
    [self.tableViewContext lock];
    
    
    //Get all entries back
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
    [request setEntity:entity];
    if(rightButtonCalls%2 == 1)
    {
        //Will Favoriten sehen
        if(self.hideOldSessions)
            request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@ AND alreadyover = %@", [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
        else
            request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@", [NSNumber numberWithBool:YES]];
    }
    else
    {
        //Will keine Favoriten sehen
        if(self.hideOldSessions)
            request.predicate = [NSPredicate predicateWithFormat:@"alreadyover = %@", [NSNumber numberWithBool:NO]];
    }
    
    NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
    NSSortDescriptor *sortDescriptorTime = [[NSSortDescriptor alloc] initWithKey:@"starttime" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorDate,sortDescriptorTime, nil];
    
    [request setSortDescriptors:sortDescriptors];
    
    [sortDescriptors release];
    
    [sortDescriptorDate release];
    [sortDescriptorTime release];
    NSError *error = nil;
    
    //Save all session entries in the mutableFetchResults
    self.mutableFetchResults = [[[self.tableViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
    if (self.mutableFetchResults == nil) {
        
        // Handle the error.
        NSLog(@"Fav Array ist leer");
        
    }
    [request release];
    
    [self.tableViewContext unlock];
    
    //Remove focus from searchbar textfield
    [self.sessionSearchBar resignFirstResponder];
    
    
    //reload view with actual saved content
    if(!isSearching)
        [self.tableView reloadData];
    else
        [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //This method gets called when the user changes the text in the searchbar textfield
    
    //Delete white space characters at the beginning of each searchtext
    NSRange alphaNumericRange = [searchText rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]];
    if(alphaNumericRange.location < searchText.length)
    {
        searchText = [searchText substringFromIndex:alphaNumericRange.location];
    }
    else
        searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
 
    NSLog(@"Text did change with searchtext: %@",searchText);
    

    [self.mutableFetchResults removeAllObjects];// remove all data that belongs to previous search
    
    if([searchText isEqualToString:@""] || searchText==nil)
    {
        [self.tableViewContext lock];
        
        //If search text is empty, get all general results
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
        [request setEntity:entity];
        if(rightButtonCalls%2 == 1)
        {
            //Will Favoriten sehen
            if(self.hideOldSessions)
                request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@ AND alreadyover = %@", [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
            else
                request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@", [NSNumber numberWithBool:YES]];
        }
        else
        {
            //Will keine Favoriten sehen
            if(self.hideOldSessions)
                request.predicate = [NSPredicate predicateWithFormat:@"alreadyover = %@", [NSNumber numberWithBool:NO]];
        }
        
        NSSortDescriptor *sortDescriptorDate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
        NSSortDescriptor *sortDescriptorTime = [[NSSortDescriptor alloc] initWithKey:@"starttime" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptorDate,sortDescriptorTime, nil];
        
        [request setSortDescriptors:sortDescriptors];
        
        [sortDescriptors release];
        
        [sortDescriptorDate release];
        [sortDescriptorTime release];
        NSError *error = nil;
        
        self.mutableFetchResults = [[[self.tableViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
        
        if (self.mutableFetchResults == nil) {
            
            // Handle the error.
            NSLog(@"Result Array is empty");
            
        }
        [request release];
        [self.tableViewContext unlock];
        
        [self.tableView reloadData];
        return;
    }
    
    [self.tableViewContext lock];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
    [request setEntity:entity];
    if(rightButtonCalls%2 == 1)
    {
        //Favorite View
        if(self.hideOldSessions)
            request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@ AND alreadyover = %@", [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]];
        else
            request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@", [NSNumber numberWithBool:YES]];
    }
    else
    {
        //General View
        if(self.hideOldSessions)
            request.predicate = [NSPredicate predicateWithFormat:@"alreadyover = %@", [NSNumber numberWithBool:NO]];
    }
    
    NSError *error = nil;
    
    //Get all general information for each searchtext change
    NSArray* allAppropriateSessionItems = [[[self.tableViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
    if (allAppropriateSessionItems == nil) {
        
        // Handle the error.
        NSLog(@"Something went wrong");
        
    }
    [request release];
    
    
    //and search for each session in this list whether it matches the criteria
    for(Session *session in allAppropriateSessionItems)
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
        
        //Set up a bool variable which is true if session matches criteria, set it default to false
        bool sessionAlreadySet = false;
        
        //Match searchtext with session title character fragments
        NSRange r = [session.title rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if(r.location != NSNotFound)
        {
            //If searchtext is part of the session title
            
            if(r.location== 0)
            {
                //If searchtext is the beginning character set of the title
                [self.mutableFetchResults addObject:session];
                
                //set bool variable to true
                sessionAlreadySet = true;
            }
        }
        
        //match through all tags of the session
        for (Tag *currentTag in session.hasTags) {
            
            NSRange tagRange = [currentTag.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(tagRange.location != NSNotFound && !sessionAlreadySet)
            {
                if(tagRange.location == 0)
                {
                    [self.mutableFetchResults addObject:session];
                    sessionAlreadySet = true;
                }
            }
        }
        
        //match for speakers of session
        for (User *currentUser in session.hasSpeakers)
        {
            NSRange speakerRangeFirstName = [currentUser.firstname rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange speakerRangeLastName = [currentUser.lastname rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(speakerRangeFirstName.location != NSNotFound && !sessionAlreadySet)
            {
                if(speakerRangeFirstName.location == 0)
                {
                    [self.mutableFetchResults addObject:session];
                    sessionAlreadySet = true;
                }
            }
            
            if(speakerRangeLastName.location != NSNotFound && !sessionAlreadySet)
            {
                if(speakerRangeLastName.location == 0)
                {
                    [self.mutableFetchResults addObject:session];
                    sessionAlreadySet = true;                    
                }
            }
        }
        
        [pool release];
    }
    [self.tableViewContext unlock];
    
    [self.tableView reloadData];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    //If text editing ended remove cancel button and reload view to current results
    self.sessionSearchBar.showsCancelButton = NO;
    [self.tableView reloadData];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 40.0;
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
    return [self.mutableFetchResults count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //This method prepares each cell (row) of the view
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSLog(@"Neue Zelle angelegt");
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    //Set number of lines of each row to 5
    cell.detailTextLabel.numberOfLines = 5;
    
    //Set lineBreakMode to wrap words at line breaks
    cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    
    //Set detailtextlabel to empty string
    cell.detailTextLabel.text = @"";
    
    //Set black text color
    cell.detailTextLabel.textColor = [UIColor blackColor];
    
    // Configure the cell...
    
    //Load corresponding session for this row
    Session* viewingSession = [self.mutableFetchResults objectAtIndex:indexPath.row];

    //Set title as textlabel
    cell.textLabel.text= viewingSession.title;
    
    //Set text for detailedtextlabel
    if([self setDetailTextLabelForIndexPath:indexPath OrSession:nil] != nil)
        cell.detailTextLabel.text = [self setDetailTextLabelForIndexPath:indexPath OrSession:nil];
    
    //Set checked.png image if session was faved and unchecked.png if session was not faved 
    UIImage *image = ([[[self.mutableFetchResults objectAtIndex:indexPath.row] isfaved] boolValue]) ? [UIImage   imageNamed:@"checked.png"] : [UIImage imageNamed:@"unchecked.png"];
    
    //Create button with this image
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
    button.frame = frame;
    [button setBackgroundImage:image forState:UIControlStateNormal];
    
    //If button is clicked run checkButtonTapped method
    [button addTarget:self action:@selector(checkButtonTapped:event:)  forControlEvents:UIControlEventTouchUpInside];
    button.backgroundColor = [UIColor clearColor];
    cell.accessoryView = button;
    
    return cell;
}


- (void) isThereAnOverlayByFavingSession:(Session *)currentSession
{
    //This method checks whether there is an time overlay by faving currentSession
    
    //First set up a bool variable which represents whether there is an overlay or not. Set it to false.
    BOOL completeOverlay = false;
    
    //Then set up a string where the session which is overlayed by current session is stored
    NSString *overlaySessions = [[[NSString alloc] init] autorelease];
    
    //If new session has specified a date and a starttime
    if(currentSession.date != nil && currentSession.starttime != nil)
    {
        //Then get all already faved sessions
        [self.tableViewContext lock];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setAffectedStores:[NSArray arrayWithObject:[[self.tableViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.tableViewContext];
        [request setEntity:entity];
        //Will Favoriten sehen
        
        request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@", [NSNumber numberWithBool:YES]];
        
        NSError *error = nil;
        
        //and save them in this variable
        NSArray* allFavedSessions = [[[self.tableViewContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
        if (allFavedSessions == nil || error != nil) {
            
            // Handle the error.
            NSLog(@"Something went wrong");
            
        }
        [request release];
        
        
        //For each already favorized Session
        for(Session *session in allFavedSessions)
        {
            //Set up a variable whether this session is overlayed by currentSession
            BOOL sessionOverlay = false;
            if(session.date != nil && session.starttime != nil)
            { 
                //If date of both sessions is the same and say start at the same time -> this is a clear overlay
                if([session.date compare:currentSession.date] == NSOrderedSame && [session.starttime compare:currentSession.starttime] == NSOrderedSame)
                {
                    sessionOverlay = true;
                }
                
                //If a duration for already favorised session was specified
                if(session.duration != nil && ![session.duration isEqualToString:@""] && !sessionOverlay)
                {
                    //First compute start and enddate of the new session
                    NSCalendar* myHomeCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                    NSDateComponents *dateSession = [myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:session.date];
                    NSDateComponents *timeSession = [myHomeCalendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:session.starttime];
                    
                    dateSession.hour = timeSession.hour;
                    dateSession.minute = timeSession.minute;
                    
                    NSDate* startDateOfSession = [myHomeCalendar dateFromComponents:dateSession];
                    
                    int duration_all = [session.duration intValue];
                    int duration_hours = duration_all/60;
                    int duration_minutes = [session.duration intValue] - duration_hours * 60;
                                        
                    dateSession.hour = dateSession.hour + duration_hours;
                    dateSession.minute = dateSession.minute + duration_minutes;
                    //dateSession.timeZone = self.conferenceTimeZone;
                    
                    //Erzeuge Datum, dass das Datum am Veranstaltungsort repräsentiert
                    NSDate* endDateOfSession = [myHomeCalendar dateFromComponents:dateSession];
                    
                    //If the current session (which the user wants to favorise) has a duration
                    if(currentSession.duration != nil && ![currentSession.duration isEqualToString:@""])
                    {
                        
                        NSDateComponents *dateCurrentSession = [myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:currentSession.date];
                        NSDateComponents *timeCurrentSession = [myHomeCalendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:currentSession.starttime];
                        
                        dateCurrentSession.hour = timeCurrentSession.hour;
                        dateCurrentSession.minute = timeCurrentSession.minute;
                        
                        NSDate* startDateOfCurrentSession = [myHomeCalendar dateFromComponents:dateCurrentSession];
                        
                        int duration_all = [currentSession.duration intValue];
                        int duration_hours = duration_all/60;
                        int duration_minutes = [currentSession.duration intValue] - duration_hours * 60;
                                                
                        dateCurrentSession.hour = dateCurrentSession.hour + duration_hours;
                        dateCurrentSession.minute = dateCurrentSession.minute + duration_minutes;
                        //dateCurrentSession.timeZone = self.conferenceTimeZone;
                        
                        //Create endDate of the current session
                        NSDate* endDateOfCurrentSession = [myHomeCalendar dateFromComponents:dateCurrentSession];
                        
                        if([endDateOfSession compare:startDateOfCurrentSession] == NSOrderedDescending && [endDateOfSession compare:endDateOfCurrentSession] == NSOrderedAscending && !sessionOverlay)
                        {
                            //Enddate of session is younger than startdate of currentsession and older than endDate of currentSession
                            sessionOverlay = true;
                            
                        }
                        
                        if([endDateOfCurrentSession compare:startDateOfSession] == NSOrderedDescending && [endDateOfCurrentSession compare:endDateOfSession] == NSOrderedAscending && !sessionOverlay)
                        {
                            //Enddate of currentsession is younger than startdate of session and older than endDate of Session
                            sessionOverlay = true;
                            
                        }
                        
                        if([startDateOfSession compare:startDateOfCurrentSession] == NSOrderedDescending && [endDateOfSession compare:endDateOfCurrentSession] == NSOrderedAscending && !sessionOverlay)
                        {
                            //startdate of session is younger than startdate of current and enddate of session is older than enddate of current session
                            sessionOverlay = true;
                        }
                        
                        if([startDateOfCurrentSession compare:startDateOfSession] == NSOrderedDescending && [endDateOfCurrentSession compare:endDateOfSession] == NSOrderedAscending && !sessionOverlay)
                        {
                            //startdate of currentsession is younger than startdate of session and enddate of currentsession is older than enddate of session
                            sessionOverlay = true;
                        }                                
                    }
                    else
                    {
                        //currentSession has no duration, merge startdate and starttime in one variable called dateOfCurrentSession
                        NSDateComponents *dateCurrentSession = [myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:currentSession.date];
                        NSDateComponents *timeCurrentSession = [myHomeCalendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:currentSession.starttime];
                        
                        dateCurrentSession.hour = timeCurrentSession.hour;
                        dateCurrentSession.minute = timeCurrentSession.minute;
                        //dateCurrentSession.timeZone = self.conferenceTimeZone;
                        NSDate* dateOfCurrentSession = [myHomeCalendar dateFromComponents:dateCurrentSession];
                        
                        if([startDateOfSession compare:dateOfCurrentSession] == NSOrderedAscending && [endDateOfSession compare:dateOfCurrentSession] == NSOrderedDescending && !sessionOverlay )
                        {
                            //If already favorised session starts before currentSession and ends after it
                            sessionOverlay = true;
                        }
                        
                        
                    }
                    [myHomeCalendar release];
                }
                else
                {
                    //If already faved session has no duration
                    if(currentSession.duration != nil && ![currentSession.duration isEqualToString:@""])
                    {
                        //But currentSession has duration
                        
                        if([session.date compare:currentSession.date] == NSOrderedDescending)
                        {
                            //Session date is more recent than beginning of currentSession, compute end of currentSession
                            NSDateFormatter* startTimeFormatterCurrentSession = [[NSDateFormatter alloc] init];
                            [startTimeFormatterCurrentSession setDateFormat:@"HH:mm"];
                            
                            NSString* sessionTimeString = [startTimeFormatterCurrentSession stringFromDate:currentSession.starttime];
                            
                            NSCalendar* myHomeCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                                                        
                            NSDateComponents* dateThereComponentsCurrentSession = [[myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:currentSession.date] retain];
                            dateThereComponentsCurrentSession.hour = [[sessionTimeString substringWithRange:NSMakeRange(0, 2)] intValue];
                            dateThereComponentsCurrentSession.minute = [[sessionTimeString substringWithRange:NSMakeRange(3, 2)] intValue];
                            
                            
                            int duration_all = [currentSession.duration intValue];
                            int duration_hours = duration_all/60;
                            int duration_minutes = [currentSession.duration intValue] - duration_hours * 60;
                                                       
                            dateThereComponentsCurrentSession.hour = dateThereComponentsCurrentSession.hour + duration_hours;
                            dateThereComponentsCurrentSession.minute = dateThereComponentsCurrentSession.minute + duration_minutes;
                            //dateThereComponentsCurrentSession.timeZone = self.conferenceTimeZone;
                            
                            //Save the end date of current Session
                            NSDate* dateThereCurrentSession = [myHomeCalendar dateFromComponents:dateThereComponentsCurrentSession];
                            [dateThereComponentsCurrentSession release];
                            
                            
                            //Merge date and starttime of already faved session and save it in finalDateOfSession
                            NSDateComponents *dateSession = [myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:session.date];
                            NSDateComponents *timeSession = [myHomeCalendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:session.starttime];
                            
                            dateSession.hour = timeSession.hour;
                            dateSession.minute = timeSession.minute;
                            
                            NSDate* finalDateOfSession = [myHomeCalendar dateFromComponents:dateSession];
                            
                            if([finalDateOfSession compare:dateThereCurrentSession] == NSOrderedAscending && !sessionOverlay)
                            {
                                NSLog(@"7");
                                //session startdate is older then the enddate of current session, hence already faved session lies within the currentsession time
                                sessionOverlay = true;
                            }
                            
                            [myHomeCalendar release];
                            [startTimeFormatterCurrentSession release];
                        }
                        else
                        {
                            //session takes place before current session --> Cancel, because we don't know how long this session takes place
                        }
                    }
                }
            }
            
            if(sessionOverlay)
            {
                //If there is an session overlay by the session, set completeOverlay variable to true
                completeOverlay = true;
                
                //If there was already a session overlay before with another faved session, concatenate strings, else set the session title as string
                if(overlaySessions.length)
                    overlaySessions = [overlaySessions stringByAppendingFormat:@", %@",session.title];
                else
                    overlaySessions = session.title;
                
                
            }
        }
        
        [self.tableViewContext unlock];
        
        //If there is a overlay with one of the faved sessions, show info on screen
        if(completeOverlay)
        {
            UIAlertView *dateOverlay = [[UIAlertView alloc] initWithTitle:time_overlay_header_en message:[NSString stringWithFormat:time_overlay_en,overlaySessions] delegate:self cancelButtonTitle:@"Okay!" otherButtonTitles:nil, nil];
            [dateOverlay show];
            [dateOverlay release];
        }
        else
        {
            //Else favorite currentSession
            [currentSession setIsfaved:[NSNumber numberWithBool:YES]];
            NSError *error;
            if (![self.tableViewContext save:&error]) {
                // Handle the error.
                NSLog(@"Saving changes failed: %@", error.description);
                
            }
            
        }
    }
}


- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    //This method is called when the user clicks on the fav button.
    Session *currentSession = [[self.mutableFetchResults objectAtIndex:indexPath.row] retain];
    
    /*Say what to do, if accessoryButton was clicked*/
    
    //If session was faved and should be unfaved, unfavorise it, else check for an overlay. If there is no overlay the session will be favorite in the isThereAnOverlayFavingSession method.
    if([[currentSession isfaved] boolValue])
        [currentSession setIsfaved:[NSNumber numberWithBool:NO]];
    else
    {
        [self isThereAnOverlayByFavingSession:currentSession];
    }
    if(!isSearching)
        [self.tableView reloadData];
    else
        [self searchBar:self.sessionSearchBar textDidChange:self.sessionSearchBar.text];
    [currentSession release];
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
    
        //This method gets called when the user clicks on a row (a session)
    
        //Fetch the session on which the user clicked
        Session* watchedSession = [self.mutableFetchResults objectAtIndex:indexPath.row];
        
        //Allocate and initiate a SessionViewController 
        SessionViewController* detailedView = [[SessionViewController alloc] initWithSessionID:watchedSession.sessionid andManagedObjectContext:self.tableViewContext andConference:self.conferenceName];
        
        [detailedView setTitle:watchedSession.title];
        detailedView.view.bounds = self.navigationController.view.bounds;
    
        //Show it on screen
        [self.navigationController pushViewController:detailedView animated:YES];
        [detailedView release];
}

@end
