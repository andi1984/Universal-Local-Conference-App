//  ConferenceTableViewController.m
//  ConferenceApp

#import "ConferenceTableViewController.h"
#import "Conference.h"
#import "AddConferenceViewController.h"
#import "SessionTableView.h"
#import "SpeakerTableView.h"
#import "ConferenceInformationController.h"
#import "MoreViewController.h"
#import "TBXML.h"
#import "MBProgressHUD.h"

//Definition of all translation variables 
#define conference_overview_de @"Konferenz Übersicht"
#define conference_overview_en @"Conference Overview"

#define more_de @"Mehr..."
#define more_en @"More..."

#define import_aborted_de @"Import abgebrochen"
#define import_aborted_en @"Import aborted"

#define xml_file_error_de @"Die XML-Datei ist fehlerhaft."
#define xml_file_error_en @"There is an error with this XML-File."

#define xml_file_could_not_be_found_de @"XML Datei konnte unter der URL %@ nicht gefunden werden."
#define xml_file_could_not_be_found_en @"The XML File could not be found under the URL %@"

@implementation ConferenceTableViewController
@synthesize conferenceContext, fetchedConferencesResult, reloadHud;
@synthesize tabBarController=_tabBarController;
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc
{
    //Dealloc all retained variables
    [conferenceContext release];
    [fetchedConferencesResult release];
    [reloadHud release];
    [_tabBarController release];
    [super dealloc];
}
    
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) reloadConferenceFile
{
    //Try to get access to CoreData
    if([self.conferenceContext tryLock])
    {
        //If access is granted...
        //... setup a request to get all the conferences saved in CoreData
        NSFetchRequest* allConferencesRequest = [[NSFetchRequest alloc] init];
        allConferencesRequest.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.conferenceContext];
        
        NSError* fetchConferencesError=nil;
        NSArray *allExistantConferences = [NSMutableArray arrayWithArray:[self.conferenceContext executeFetchRequest:allConferencesRequest error:&fetchConferencesError]];
        [allConferencesRequest release];
        if(!fetchConferencesError)
        {
            //If there was no error
            for (Conference *currentConf in allExistantConferences) {
                //For all conferences...
                
                //... first get the URL where the conference.xml is saved
                NSString* conferenceXMLPath;
                
                // and delete empty space characters (e.g. created by mistyping)
                conferenceXMLPath = [currentConf.conferencexmlurl stringByReplacingOccurrencesOfString:@" " withString:@""];
                
                //Show the reloadHud during reloading data, so unhide it
                self.reloadHud.hidden = false;
                
                //and show it on screen
                [self.reloadHud show:YES];
                
                //Then...
                dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    //... reload the xmlData in background (without blocking main thread)
                    NSData* xmlData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:conferenceXMLPath]];
                    dispatch_async( dispatch_get_main_queue(), ^{
                        //... and reload data in main thread if xmlData is not nil (so some data is saved there)
                        if(xmlData != nil)
                        {
                            //First save URL of file in an instance of class TBXML
                            TBXML* tbxml = [TBXML tbxmlWithURL:[NSURL URLWithString:conferenceXMLPath]];
                            //then set the root of the XML file
                            TBXMLElement * root = tbxml.rootXMLElement;
                            
                            if (root)
                            {
                                //If root exists
                                //... read out all XML-Data with the XML-Parser
                                TBXMLElement* conferenceName = [TBXML childElementNamed:@"name" parentElement:root];
                                TBXMLElement* startDateOfConference = [TBXML childElementNamed:@"startdate" parentElement:root];
                                TBXMLElement* durationOfConference = [TBXML childElementNamed:@"duration" parentElement:root];
                                TBXMLElement* topicOfConference = [TBXML childElementNamed:@"topic" parentElement:root];
                                TBXMLElement* contactForConference = [TBXML childElementNamed:@"contact" parentElement:root];
                                TBXMLElement* homepageURLOfConference = [TBXML childElementNamed:@"homepageurl" parentElement:root];
                                TBXMLElement* imprintOfConference = [TBXML childElementNamed:@"imprint" parentElement:root];
                                
                                
                                //... and replace the data of current conference with the data in the public conference file 
                                if(conferenceName)
                                    currentConf.name = [TBXML textForElement:conferenceName];
                                
                                if(topicOfConference)
                                    currentConf.topic = [TBXML textForElement:topicOfConference];
                                
                                if(contactForConference)
                                    currentConf.contact = [TBXML textForElement:contactForConference];
                                
                                if(homepageURLOfConference)
                                    currentConf.homepageurl = [TBXML textForElement:homepageURLOfConference];
                                
                                if(imprintOfConference)
                                    currentConf.imprint = [TBXML textForElement:imprintOfConference];
                                
                                currentConf.conferencexmlurl = conferenceXMLPath;
                                
                                //If XML-Entry with start date of conference given
                                if(![[TBXML textForElement:startDateOfConference] isEqualToString:@""] && startDateOfConference != nil)
                                {
                                    //Save the content of the date XML-tag in a string
                                    NSString* dateString = [TBXML textForElement:startDateOfConference];
                                    
                                    //Then transform characters in a NSDate and transform it back to characters. With this transformations characters are tried to match the format YYYY:MM:dd as specified in the documentation. If possible, the result is a valid date string. If not the originalDateString is nil.
                                    
                                    NSDateFormatter* dateConstructor = [[NSDateFormatter alloc] init];
                                    [dateConstructor setDateFormat:@"YYYY:MM:dd"];
                                    NSDate* sessionDate = [dateConstructor dateFromString:dateString];
                                    [dateConstructor release];
                                    
                                    NSDateFormatter* stringFromOriginalDate = [[NSDateFormatter alloc] init];
                                    [stringFromOriginalDate setDateFormat:@"YYYY:MM:dd"];
                                    NSString* originalDateString = [stringFromOriginalDate stringFromDate:sessionDate];
                                    [stringFromOriginalDate release];
                                    
                                    //If the date is valid
                                    if(originalDateString != nil)
                                    {
                                        //Cut out the day, month and year from it
                                        NSDateComponents* dateThereComponents = [[NSDateComponents alloc] init];
                                        dateThereComponents.day = [[originalDateString substringWithRange:NSMakeRange(8, 2)] intValue];
                                        dateThereComponents.month = [[originalDateString substringWithRange:NSMakeRange(5, 2)] intValue];
                                        dateThereComponents.year = [[originalDateString substringWithRange:NSMakeRange(0, 4)] intValue];
                                        
                                        
                                        //Allocate and initiate a NSCalendar and transform characters again to final NSDate instance and save as the conference startdate
                                        NSCalendar* transformationCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                                        NSDate* finalDate = [transformationCalendar dateFromComponents:dateThereComponents];
                                        [dateThereComponents release];
                                        [transformationCalendar release];
                                        
                                        currentConf.startdate = finalDate;
                                    }
                                    else
                                    {
                                        //If date is not valid set startdate to nil.
                                        currentConf.startdate = nil;
                                    }
                                        
                                        
                                    /*NSError *error = nil;
                                     if (![self.addContext save:&error]) {
                                     
                                     NSLog(@"Fehler beim Speichern");
                                     
                                     }*/
                                }                   
                                
                                //If duration of conference is given in XML file
                                if(durationOfConference != nil && ![[TBXML textForElement:durationOfConference] isEqualToString:@""])
                                {
                                    //Transform characters with NSNumberFormatter...
                                    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                                    
                                    //to a decimal number
                                    [f setNumberStyle:NSNumberFormatterDecimalStyle];
                                    
                                    //and set it as the currentConf duration.
                                    currentConf.duration = [f numberFromString:[TBXML textForElement:durationOfConference]];
                                    [f release];
                                }
                                
                                
                                /*NSError *savingError;
                                 if(![self.addContext save:&savingError])
                                 {
                                 NSLog(@"Speichern der neuen Konferenz ging nicht!");
                                 }*/
                                
                                //At the end check the optional entries
                                
                                TBXMLElement* conditionsForConference = [TBXML childElementNamed:@"conditions" parentElement:root];
                                if(conditionsForConference)
                                    currentConf.conditions = [TBXML textForElement:conditionsForConference];
                                else
                                    currentConf.conditions = nil;
                                
                                
                                TBXMLElement* recommendedHotelsForeConference = [TBXML childElementNamed:@"recommendedhotels" parentElement:root];
                                if(recommendedHotelsForeConference)
                                    currentConf.recommendedhotels = [TBXML textForElement:recommendedHotelsForeConference];
                                else
                                    currentConf.recommendedhotels = nil;
                                
                                TBXMLElement* conferenceLogoUrl = [TBXML childElementNamed:@"conferencelogourl" parentElement:root];
                                if(conferenceLogoUrl)
                                    currentConf.conferencelogourl = [TBXML textForElement:conferenceLogoUrl];
                                else
                                    currentConf.conferencelogourl = nil;
                                
                                TBXMLElement* sponsorXMLURLForConference = [TBXML childElementNamed:@"sponsorxmlurl" parentElement:root];
                                if(sponsorXMLURLForConference && ![[TBXML textForElement:sponsorXMLURLForConference] isEqualToString:@""])
                                    currentConf.sponsorxmlurl = [TBXML textForElement:sponsorXMLURLForConference];
                                else
                                    currentConf.sponsorxmlurl = nil;
                                
                                TBXMLElement* venueXMLURLForConference = [TBXML childElementNamed:@"venuexmlurl" parentElement:root];
                                if(venueXMLURLForConference && ![[TBXML textForElement:venueXMLURLForConference] isEqualToString:@""])
                                    currentConf.venuexmlurl = [TBXML textForElement:venueXMLURLForConference];
                                else
                                    currentConf.venuexmlurl = nil;
                                
                                TBXMLElement* sessionXMLURLForConference = [TBXML childElementNamed:@"sessionxmlurl" parentElement:root];
                                if(sessionXMLURLForConference && ![[TBXML textForElement:sessionXMLURLForConference] isEqualToString:@""])
                                    currentConf.sessionxmlurl = [TBXML textForElement:sessionXMLURLForConference];
                                else
                                    currentConf.sessionxmlurl = nil;
                                
                                TBXMLElement* userXMLURLForConference = [TBXML childElementNamed:@"userxmlurl" parentElement:root];
                                if(userXMLURLForConference && ![[TBXML textForElement:userXMLURLForConference] isEqualToString:@""])
                                    currentConf.userxmlurl = [TBXML textForElement:userXMLURLForConference];
                                else
                                    currentConf.userxmlurl = nil;
                                
                                TBXMLElement* targetedaudienceOfConference = [TBXML childElementNamed:@"targetedaudience" parentElement:root];
                                if(targetedaudienceOfConference)
                                    currentConf.targetedaudience = [TBXML textForElement:targetedaudienceOfConference];
                                else
                                    currentConf.targetedaudience = nil;
                                
                                TBXMLElement *sloganOfConference = [TBXML childElementNamed:@"slogan" parentElement:root];
                                if(sloganOfConference)
                                    currentConf.slogan = [TBXML textForElement:sloganOfConference];
                                else
                                    currentConf.slogan = nil;
                                
                                
                                TBXMLElement* timeZoneOfConference = [TBXML childElementNamed:@"timezone" parentElement:root];
                                if(timeZoneOfConference)
                                    currentConf.timezone = [TBXML textForElement:timeZoneOfConference];
                                else
                                    currentConf.timezone = nil;
                                
                                TBXMLElement* registrationURLForConference = [TBXML childElementNamed:@"registrationurl" parentElement:root];
                                if(registrationURLForConference)
                                    currentConf.registrationurl = [TBXML textForElement:registrationURLForConference];
                                else
                                    currentConf.registrationurl = nil;
                                
                                TBXMLElement* acronymOfConference = [TBXML childElementNamed:@"acronym" parentElement:root];
                                if(acronymOfConference)
                                    currentConf.acronym = [TBXML textForElement:acronymOfConference];
                                else
                                    currentConf.acronym = nil;
                                
                                TBXMLElement* newsFeedURLForConference = [TBXML childElementNamed:@"newsfeedurl" parentElement:root];
                                if(newsFeedURLForConference)
                                    currentConf.newsfeedurl = [TBXML textForElement:newsFeedURLForConference];
                                else
                                    currentConf.newsfeedurl = nil;
                                
                                                                
                                TBXMLElement* journeyPlanOfConference = [TBXML childElementNamed:@"journeyplan" parentElement:root];
                                if(journeyPlanOfConference)
                                    currentConf.journeyplan = [TBXML textForElement:journeyPlanOfConference];
                                else
                                    currentConf.journeyplan = nil;
                                
                                
                                TBXMLElement* welcomeMessageElement = [TBXML childElementNamed:@"welcomemessage" parentElement:root];
                                if(welcomeMessageElement)
                                    currentConf.welcomemessage = [TBXML textForElement:welcomeMessageElement];
                                else
                                    currentConf.welcomemessage = nil;
                                
                                TBXMLElement* welcomeVideoElement = [TBXML childElementNamed:@"welcomevideo" parentElement:root];
                                if(welcomeVideoElement)
                                    currentConf.welcomevideo = [TBXML textForElement:welcomeVideoElement];
                                else
                                    currentConf.welcomevideo = nil;
                                
                                
                                //At the end save all currentConf properties added before.
                                NSError *savingError2;
                                if(![self.conferenceContext save:&savingError2])
                                {
                                    NSLog(@"Speichern der neuen Konferenz ist fehlgeschlagen!");
                                }
                                
                                //Then reload the current active view
                                [self.tableView reloadData];
                                [self.tableView setNeedsLayout];
                                [self.tableView setNeedsDisplay];
                            }
                            else
                            {
                                //If root of XML file not found, the file structure doesn't confirm a typical XML structure
                                UIAlertView* wrongXMLStructure = [[UIAlertView alloc] initWithTitle:import_aborted_en message:xml_file_error_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                                [wrongXMLStructure show];
                                [wrongXMLStructure release];
                            }
                        }
                        else
                        {
                            //If no xml data were received the file could not be found.
                            UIAlertView* importingAborted = [[UIAlertView alloc] initWithTitle:import_aborted_en message:[NSString stringWithFormat:xml_file_could_not_be_found_en, conferenceXMLPath] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                            [importingAborted show];
                            [importingAborted release];
                        }
                        [xmlData release];
                        
                        //At the end of the update hide the reloadHud again.
                        self.reloadHud.hidden = true;
                        [self.reloadHud  show:NO];
                    });
                });
            }
        }
    }
}


#pragma mark - View lifecycle
- (void) handleRotation
{
    //If user makes rotation gesture on screen the app reloads all conferences' details
    
    //Fetch rotation gesture if UIRotationGestureRecognizer is in state UIGestureRecognizerStateEnded (means rotation gesture was done right now)
    for (UIRotationGestureRecognizer* recognizer in [self.view gestureRecognizers]) {
        if(recognizer.state == UIGestureRecognizerStateEnded)
        {
            NSLog(@"Rotation is done!");
            //Rotation gesture was done...
            //... so initiate the method to reload the ConferenceFiles
            [self reloadConferenceFile];
        }
    }
}

- (void)addConference
{
    //This method is initiated when a user clicks on the plus button on screen to add a conference to his conference overview
    //So allocate memory and initiate a new instance of the class AddConferenceViewController where the user can input the conference.xml URL.
    AddConferenceViewController* addConferenceController = [[AddConferenceViewController alloc] init];
    
    //Set the managedObjectContext of the new viewController to the actual managedObjectContext
    addConferenceController.addContext = self.conferenceContext;
    
    //Add the new view to the navigationController
    [self.navigationController pushViewController:addConferenceController animated:YES];
    
    //Hide the navigaionBar
    self.navigationController.navigationBarHidden = TRUE;
    
    //Release retained addConferenceController because it's no longer needed in the method addConference. The navigationBar has overtaken the addConferenceController instance with the pushViewController method
    [addConferenceController release];
}

- (void)startEditingMode
{
    //This method gets invoked if the user clicks on the left button in the navBar called EDIT Button
    
    //if the editing mode was not active before
    if(self.tableView.editing == NO)
    {
        //Activate it...
        [self.tableView setEditing:YES animated:YES];
        //and reload the view
        [self.tableView reloadData];
    }
    else
    {
        //else deactivate the editing mode
        [self.tableView setEditing:NO animated:YES];
        //and reload the view
        [self.tableView reloadData];
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
    //Allocate and initiate a instance of MBProgressHUD to show during reloading conference data from the web.
    self.reloadHud = [[[MBProgressHUD alloc] initWithView:self.navigationController.view] autorelease];
    
    //Add the reloadHud to the navigationController
    [self.navigationController.view addSubview:self.reloadHud];
    
    //Set current view's title.
    self.title = conference_overview_en;
    
    //Create the Add-Button as the rightBarButtonItem of the navigationController. If button is clicked, run addConference method.
    UIBarButtonItem* addcurrentConfItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addConference)];
    self.navigationItem.rightBarButtonItem = addcurrentConfItem;
    [addcurrentConfItem release];
    
    //Create the Delete-Button as the leftBarButtonItem of the navigationController. If button is clicked, run startEditingMode method.
    UIBarButtonItem* deleteConferenceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditingMode)];
    self.navigationItem.leftBarButtonItem = deleteConferenceButton;
    [deleteConferenceButton release];
    
    //Add a UIRotationGestureRecognizer to be able to recognize rotation gestures done by the user. If rotation gesture is triggered, run handleRotation method.
    UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation)];
    [self.view addGestureRecognizer:rotationRecognizer];
    [rotationRecognizer release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Hide navigationBar
    self.navigationController.navigationBarHidden = NO;
    
    NSLog(@"View Will Appear");
    
    //Try to get access to coreData (if no other process is accessing core data values right now)
    if([self.conferenceContext tryLock])
    {
        //If access is granted...
        //... start a request to collect all conferences which are saved as CoreData
        
        //Stat by allocate and initiating a NSFetchRequest
        NSFetchRequest* allConferencesRequest = [[NSFetchRequest alloc] init];
        
        //Set the entity to the 'Conference' entity in our managedObjectContext
        allConferencesRequest.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.conferenceContext];
        
        //Sort Descriptor has caused problem with deletion of an element added on top. Commented code out.
        //NSSortDescriptor* conferenceSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        //allConferencesRequest.sortDescriptors = [NSArray arrayWithObject:conferenceSortDescriptor];
        //[conferenceSortDescriptor release];
        
        //Set a new error variable to nil
        NSError* fetchConferencesError=nil;
        
        //Execute the request and save the result array (with all the saved conferences in it) as self.fetchedConferencesResult
        self.fetchedConferencesResult = [[[NSMutableArray arrayWithArray:[self.conferenceContext executeFetchRequest:allConferencesRequest error:&fetchConferencesError]]mutableCopy] autorelease];
        
        NSLog(@"Anzahl der Konferenzen: %i",[self.fetchedConferencesResult count]);
        
        //If the fetchedConferencesResult is nil or an error occured
        if (self.fetchedConferencesResult == nil || fetchConferencesError!=nil) {
            
            // Handle the error.
            NSLog(@"Fehler beim Laden der Konferenzen!");
        }
        [allConferencesRequest release]; 
    }
   
    //After fetching results reload complete view to display the new data correctly.
    [self.tableView reloadData];
    [self.tableView setNeedsDisplay];
    [self.tableView setNeedsLayout];
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


- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 200.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.fetchedConferencesResult count];
}

- (void) showInfoButton:(id)sender
{
    //This method gets invoked if the user clicks on the info button of a saved conference.
    
    //To redirect this request we have to extract the cell (row) where the info button was clicked.
    UITableViewCell *myCell = (UITableViewCell *)[sender superview];
    
    //Then we can extract the indexPath where informations about the row are saved.
    NSIndexPath *indexPath = [self.tableView indexPathForCell:myCell];
    
    //And at the end we invoke the accessoryButton method with the indexPath
    [self tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configuring the view of each row in the table
    
    //First find out which conference should be displayed in the row indexpath.row
    Conference* currentWatchingConference = [self.fetchedConferencesResult objectAtIndex:indexPath.row];
    
    //After that set as main label the conference's name.
    cell.textLabel.text = currentWatchingConference.name;
    
    //And as sublabel the homepage URL if there exists one
    cell.detailTextLabel.text = @"";
    
    if(currentWatchingConference.homepageurl != nil)
    {
        cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@"%@",currentWatchingConference.homepageurl];
    }
    
    //For more conference information add a button on the right side of each row.
    //For this first create a button with an dark info sign on it.
    UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    
    //Set the frame of the button to x=0.0, y=0.0 and with 40 pixels height and width
    accessoryButton.frame = CGRectMake(0, 0, 40, 40);
    
    //If button is clicked (UIControlEventTouchUpInside) run showInfoButton method
    [accessoryButton addTarget:self action:@selector(showInfoButton:) forControlEvents:UIControlEventTouchUpInside];
    
    //Add the accessoryButton as the accessoryView of each row.
    cell.accessoryView = accessoryButton;
   
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


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView reloadData];
    if (editingStyle == UITableViewCellEditingStyleDelete && [self.conferenceContext tryLock])
    {
        //If delete action is initiated in a cell (UITableViewCellEditingStyleDelete) and CoreData access is granted
        //Find out which is the corresponding conference
        Conference* conferenceToDelete = [self.fetchedConferencesResult objectAtIndex:indexPath.row];
        
        //Remove the conference in the official results list 
        [self.fetchedConferencesResult removeObjectAtIndex:indexPath.row];
        
        //Remove the conference from context
        [self.conferenceContext deleteObject:[self.conferenceContext objectWithID:[conferenceToDelete objectID]]];
        
        //And delete the corresponding persistent store coordinator with the store url storeURL from the persistent store coordinator
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = [searchPaths objectAtIndex:0];
        NSString* storeFileName = [NSString stringWithFormat:@"%@",conferenceToDelete.name];
        NSURL* storeURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:storeFileName]];
        
        //If there exists a store at this URL delete the store
        if([[[self.conferenceContext persistentStoreCoordinator] persistentStores] count] > 1)
        {            
            NSError* deletionError = nil;
            NSLog(@"Persistent Stores before deletion %i",[[[self.conferenceContext persistentStoreCoordinator] persistentStores] count]);
            @try {
                [[self.conferenceContext persistentStoreCoordinator] removePersistentStore:[[self.conferenceContext persistentStoreCoordinator] persistentStoreForURL:storeURL]  error:&deletionError];
            }
            @catch (NSException *exception) {
            }
            @finally {
            }
            NSLog(@"Persistent Stores after deletion %i",[[[self.conferenceContext persistentStoreCoordinator] persistentStores] count]);
        }
        
        //Finally remove file at storeURL completely
        NSError *error = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
            if (![[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            } 
        }

        //At the end delete the corresponding row in the tableView
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
        //Save the changes.
        NSError* savingError;
        if(![self.conferenceContext save:&savingError])
            NSLog(@"Fehler beim Speichern.");
        
    }   
}


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
    
    //This method gets activated if a user selects a conference in the tableView. First we have to find out which conference it was. This is simply the conference in the array at the same index (row).
    Conference* choosenConference = [self.fetchedConferencesResult objectAtIndex:indexPath.row];
    
    //Then hide navigationBar
    self.navigationController.navigationBarHidden = YES;
    
    
    //Allocate and initiate a tabBar.
    _tabBarController = [[[UITabBarController alloc] init] autorelease];
    
    //and setup three different tabs
    
    //First a tab with all sessions (SessionTableView class)
    SessionTableView* tabOne = [[SessionTableView alloc] init];
     tabOne.tableViewContext = self.conferenceContext;
    tabOne.conferenceName = choosenConference.name;
    tabOne.title = @"Agenda";
     //tabOne.view.bounds = self.navController.view.bounds;

    //Then a tab with all speakers in it (SpeakerTableView class) 
    SpeakerTableView* tabTwo = [[SpeakerTableView alloc] init];
     tabTwo.speakerViewContext = self.conferenceContext;
    tabTwo.conferenceName = choosenConference.name;
    tabTwo.delegate = tabOne;
     tabTwo.title = @"Speakers Corner";
     
    //And then a more tab with more options in it (MoreViewController class)
    MoreViewController* more = [[MoreViewController alloc] init];
    more.ourContext = self.conferenceContext;
    more.conferenceName = choosenConference.name;
    more.title = more_en;
    
    //Finally link them all to the tabBarController
    [_tabBarController setViewControllers:[NSArray arrayWithObjects:tabOne, tabTwo, more, nil]];
    [more release];
    [tabTwo release];
    [tabOne release];

    //And put the tabBarController on screen by adding it to the navigationBar
    [self.navigationController pushViewController:_tabBarController animated:YES];
    
    
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    //After the user clicked on an info button of a saved conference this method gets indirectly invoked
    
    //First the corresponding method needs to be defined by the row where the button was activated
    Conference *tappedConference = [self.fetchedConferencesResult objectAtIndex:indexPath.row];
    
    //Then an instance of the class ConferenceInformationController gets allocated and initiated
    ConferenceInformationController *conferenceInformation = [[ConferenceInformationController alloc] init];
    
    //Then the name of the conference gets forwarded and the current managedObjectContext
    conferenceInformation.conferenceName = tappedConference.name;
    conferenceInformation.conferenceContext = self.conferenceContext;
    
    //Furthermore the navigationController gets hidden and the new view comes in front to the smartphone UI.
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController pushViewController:conferenceInformation animated:YES];
    [conferenceInformation release];
}

@end
