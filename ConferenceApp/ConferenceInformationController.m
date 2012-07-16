//  ConferenceInformationController.m
//  ConferenceApp

#import "ConferenceInformationController.h"
#import "Conference.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>


//Definition of all translation variables 

#define conferencename_label_de @"Konferenz-Name"
#define conferencename_label_en @"Conference Name"

#define conference_topic_label_de @"Thema"
#define conference_topic_label_en @"Topic"

#define contact_label_de @"Kontakt"
#define contact_label_en @"Contact"

#define website_label_de @"Webseite"
#define website_label_en @"Website"

#define timezone_label_de @"Zeitzone"
#define timezone_label_en @"Timezone"

#define conference_period_de @"Konferenz-Zeitraum"
#define conference_period_en @"Conference Period"

#define conference_targeted_audience_de @"Zielgruppe"
#define conference_targeted_audience_en @"Targeted Audience"


#define conference_registration_de @"Anmeldung"
#define conference_registration_en @"Registration"

#define conference_hashtag_de @"Konferenz-Kürzel"
#define conference_hashtag_en @"Conference Hashtag"

#define conference_hotel_recommendations_de @"Empfohlene Übernachtungsmöglichkeiten"
#define conference_hotel_recommendations_en @"Recommended Hotels"





@implementation ConferenceInformationController
@synthesize conferenceContext, conferenceData, conferenceName, sectionHeaders;
@synthesize conferenceLogoImage;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [conferenceData release];
    [conferenceContext release];
    [conferenceName release];
    [sectionHeaders release];
    [conferenceLogoImage release];
    [super dealloc];
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
    
    //Allocate and initiate two arrays where the informations about the conference (conferenceData) and the section header labels (sectionHeaders) are stored.
    self.conferenceData = [[[NSMutableArray alloc] init] autorelease];
    self.sectionHeaders = [[[NSMutableArray alloc] init] autorelease];
    
    //Allocate and initiate a swipeGestureRecognizer.
    UISwipeGestureRecognizer* swipingToTheRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwiping)];
    swipingToTheRight.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipingToTheRight];
    [swipingToTheRight release];
    
    //Allocate and initiate a NSFetchRequest to get the conference data
    NSFetchRequest* getConferenceData = [[NSFetchRequest alloc] init];
    
    //Set 'Conference' as the entity
    getConferenceData.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.conferenceContext];
    
    //Find Conference with name = self.conferenceName
    getConferenceData.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
    
    NSError *gettingDataError = nil;
    Conference* thisConference = [[self.conferenceContext executeFetchRequest:getConferenceData error:&gettingDataError] lastObject];
    [getConferenceData release];
    if(!gettingDataError && thisConference != nil)
    {
        //If conference exists and there was no error, proceed    
        
        if(thisConference.conferencelogourl != nil && ![thisConference.conferencelogourl isEqualToString:@""])
        {
            //If logo URL of conference is not nil and not empty character, load image data in background
            dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError* loadImageError = nil;
                NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:thisConference.conferencelogourl] options:NSDataReadingUncached error:&loadImageError];
                dispatch_async( dispatch_get_main_queue(), ^{
                    if(imageData != nil && !loadImageError)
                    {
                        //If imagedata is not nil and there was no error
                        NSLog(@"Setze Bild!!!!!");
                        //Save image in tempImage
                        UIImage* tempImage = [[UIImage imageWithData:imageData] retain];
                        //Calculate imageRatio
                        float imageRatio = tempImage.size.height/tempImage.size.width;
                        //Build thumbnailImage with width 80 pixel and 80*ratio height and save new thumbnail image at conferenceLogoImage variable
                        self.conferenceLogoImage = [self makeThumbnailFromImage:tempImage ToSize:CGSizeMake(80, 80*imageRatio)];
                        [tempImage release];
                        //After all changes reload view
                        [self.tableView reloadData];
                    }
                });
                [imageData release];
            });
        }
        
        
        if(thisConference.name != nil && ![thisConference.name isEqualToString:@""])
        {
            //If conference name is given (not nil and not empty)
            //Allocate and initiate two Arrays: One for content and one for the header.
            NSMutableArray *contentOfFirstSection = [[NSMutableArray alloc] init];
            NSMutableArray *headerOfFirstSection = [[NSMutableArray alloc] init];
            
            //Add the name string to the contentArray
            [contentOfFirstSection addObject:thisConference.name];
            
            //Add the content array the the conferenceData
            [self.conferenceData addObject:contentOfFirstSection];
            
            //Add header to header array
            [headerOfFirstSection addObject:conferencename_label_en];
            
            //Add the headerArray to section headers array
            [self.sectionHeaders addObject:headerOfFirstSection];
            //[self.sectionHeaders setValue:headerOfFirstSection forKey:@"0"];
            
            [contentOfFirstSection release];
            [headerOfFirstSection release];
        }
        
        //This procedure works analog for all other properties
        
        if(thisConference.topic != nil && ![thisConference.topic isEqualToString:@""])
        {
            NSMutableArray *contentOfSecondSection = [[NSMutableArray alloc] init];
            NSMutableArray *headerOfSecondSection = [[NSMutableArray alloc] init];
            
            [contentOfSecondSection addObject:thisConference.topic];
            [self.conferenceData addObject:contentOfSecondSection];
            
            [headerOfSecondSection addObject:conference_topic_label_en];
            [self.sectionHeaders addObject:headerOfSecondSection];
            
            [contentOfSecondSection release];
            [headerOfSecondSection release];
        }
        
        
        if(thisConference.slogan != nil && ![thisConference.slogan isEqualToString:@""])
        {
            NSMutableArray *contentOfThirdSection = [[NSMutableArray alloc] init];
            NSMutableArray *headerOfThirdSection = [[NSMutableArray alloc] init];
            
            [contentOfThirdSection addObject:thisConference.slogan];
            [self.conferenceData addObject:contentOfThirdSection];
             
            [headerOfThirdSection addObject:@"Slogan"];
            [self.sectionHeaders addObject:headerOfThirdSection];
                        
            [contentOfThirdSection release];
            [headerOfThirdSection release];
        }
        
        //The contact section can consist out of multiple data (contact details, imprint)
        
        //First allocate and initiate the content- and header arrays.
        NSMutableArray *contentOfFourthSection = [[NSMutableArray alloc] init];
        NSMutableArray *headerOfFourthSection = [[NSMutableArray alloc] init];
        
        //To know whether contact data is provided, the isContact bool variable is set.
        bool isContact = false;
        
        if(thisConference.contact != nil && ![thisConference.contact isEqualToString:@""])
        {   
            //If contact information are given, set isContact to true
            isContact = true;
            NSString* contactString = @"";
            
            //The contact information can be given further informations for line breaks by adding characters '\\'. First get the string components by separating with this characters '\\'.
            NSArray* componentsOfContactString = [thisConference.contact componentsSeparatedByString:@"\\"];
            
            //For each single component
            for (NSString* singleComponent in componentsOfContactString) 
            {
                //If single component consists of real characters (string length is greater than 0 after deleting white space characters)
                if(![[singleComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
                {
                    contactString = [contactString stringByAppendingString:[singleComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                    contactString = [contactString stringByAppendingString:@" \n"];
                }
            }
            
            //Add contact details to content array
            [contentOfFourthSection addObject:contactString];
        }
        
        if(thisConference.imprint != nil && ![thisConference.imprint isEqualToString:@""])
        {
            //If imprint information is given, set isContact to true
            isContact = true;
            
            NSString* imprintString = @"";
            NSArray* componentsOfImprintString = [thisConference.imprint componentsSeparatedByString:@"\\"];
            for (NSString* singleComponent in componentsOfImprintString) {
                if(![[singleComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
                {
                    imprintString = [imprintString stringByAppendingString:[singleComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                    imprintString = [imprintString stringByAppendingString:@" \n"];
                }
            }
            
            [contentOfFourthSection addObject:imprintString];
        }
        
        if(isContact)
        {
            //If some contact information is given, set header
            [headerOfFourthSection addObject:contact_label_en];
            
            //And add content and header to the conferenceData and sectionHeaders array
            [self.conferenceData addObject:contentOfFourthSection];  
            [self.sectionHeaders addObject:headerOfFourthSection];
        }
        
        [contentOfFourthSection release];
        [headerOfFourthSection release];
        
        NSMutableArray *contentOfFourthAndAHalfSection = [[NSMutableArray alloc] init];
        NSMutableArray *headerOfFourthAndAHalfSection = [[NSMutableArray alloc] init];
        
        if(thisConference.homepageurl != nil && ![thisConference.homepageurl isEqualToString:@""])
        {
            [contentOfFourthAndAHalfSection addObject:thisConference.homepageurl];
            [headerOfFourthAndAHalfSection addObject:website_label_en];
            
            [self.conferenceData addObject:contentOfFourthAndAHalfSection];
            [self.sectionHeaders addObject:headerOfFourthAndAHalfSection];
        }
        
        [contentOfFourthAndAHalfSection release];
        [headerOfFourthAndAHalfSection release];
        
        if(thisConference.startdate != nil)
        {    
            //If startdate is given, allocate and initiate content- and headerarray
            NSMutableArray *contentOfFifthSection = [[NSMutableArray alloc] init];
            NSMutableArray *headerOfFifthSection = [[NSMutableArray alloc] init];
            
            //Get string from startdate (NSDate)
            NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"dd.MM.YYYY"];
            NSString* fromDateToDate = [[[NSString alloc] init] autorelease];
            fromDateToDate = [dateFormatter stringFromDate:thisConference.startdate];
            [dateFormatter release];
            
            if(thisConference.duration != nil)
            {
                //If duration of conference is given, add a end date, by first adding a separator sign
                fromDateToDate = [fromDateToDate stringByAppendingString:@" - "];
                
                //And then calculate the end date by
                NSCalendar *neededCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                //First get date components (year, month, day) components from startdate
                NSDateComponents* newDateComponents = [neededCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:thisConference.startdate];
                //And add the number given by the duration property
                newDateComponents.day = newDateComponents.day + [thisConference.duration intValue];
                NSDate* conferenceEndDate = [neededCalendar dateFromComponents:newDateComponents];
                [neededCalendar release];
                
                
                //Get the string of the enddate and add it to the fromDateToDate string
                NSDateFormatter* endDateFormatter = [[NSDateFormatter alloc] init];
                [endDateFormatter setDateFormat:@"dd.MM.YYYY"];
                fromDateToDate = [fromDateToDate stringByAppendingString:[endDateFormatter stringFromDate:conferenceEndDate]];
                [endDateFormatter release];
            }
            
            //If timezone is given...
            if(thisConference.timezone != nil && ![thisConference.timezone isEqualToString:@""])
            {
                //Add timezone description to the date label
                fromDateToDate = [fromDateToDate stringByAppendingFormat:@" \n%@: %@",timezone_label_en,thisConference.timezone];
            }
            
            //Add string to content array
            [contentOfFifthSection addObject:fromDateToDate];
            
            //Add content array to conferenceData array
            [self.conferenceData addObject:contentOfFifthSection];
            
            //Add header to headerOfFifthSection array
            [headerOfFifthSection addObject:conference_period_en];
            
            //Add header array of date to the sectionHeaders
            [self.sectionHeaders addObject:headerOfFifthSection];
        
            [contentOfFifthSection release];
            [headerOfFifthSection release];
        }
        
        if(thisConference.targetedaudience != nil && ![thisConference.targetedaudience isEqualToString:@""])
        {
            NSMutableArray *contentOfSixthSection = [[NSMutableArray alloc] init];
            NSMutableArray *headerOfSixthSection = [[NSMutableArray alloc] init];
            
            [contentOfSixthSection addObject:thisConference.targetedaudience];
            [headerOfSixthSection addObject:conference_targeted_audience_en];
            
            [self.conferenceData addObject:contentOfSixthSection];
            [self.sectionHeaders addObject:headerOfSixthSection];
            
            [contentOfSixthSection release];
            [headerOfSixthSection release];
        }
        
        NSMutableArray *contentOfSeventhSection = [[NSMutableArray alloc] init];
        NSMutableArray *headerOfSeventhSection = [[NSMutableArray alloc] init];
        bool isRegistration = false;
        
        if(thisConference.conditions != nil && ![thisConference.conditions isEqualToString:@""])
        {
            isRegistration = true;
            
            [contentOfSeventhSection addObject:thisConference.conditions];
        }
        
        if(thisConference.registrationurl != nil && ![thisConference.registrationurl isEqualToString:@""])
        {
            isRegistration = true;
            [contentOfSeventhSection addObject:thisConference.registrationurl];
        }
        
        if(isRegistration)
        {
            [self.conferenceData addObject:contentOfSeventhSection];
            
            [headerOfSeventhSection addObject:conference_registration_en];
            [self.sectionHeaders addObject:headerOfSeventhSection];
        }
        
        [contentOfSeventhSection release];
        [headerOfSeventhSection release];
               
        if(thisConference.acronym != nil && ![thisConference.acronym isEqualToString:@""])
        {
            
            NSMutableArray *contentOfEigthSection = [[NSMutableArray alloc] init];
            NSMutableArray *headerOfEigthSection = [[NSMutableArray alloc] init];
            
            [contentOfEigthSection addObject:thisConference.acronym];
            [headerOfEigthSection addObject:conference_hashtag_en];
            
            [self.conferenceData addObject:contentOfEigthSection];
            [self.sectionHeaders addObject:headerOfEigthSection];
        
            
            [contentOfEigthSection release];
            [headerOfEigthSection release];
        }
        
        if(thisConference.recommendedhotels != nil && ![thisConference.recommendedhotels isEqualToString:@""])
        {
            
            NSMutableArray *contentOfNinthSection = [[NSMutableArray alloc] init];
            NSMutableArray *headerOfNinthSection = [[NSMutableArray alloc] init];
            
            NSString* hotelsString = @"";
            NSArray* componentsOfHotelString = [thisConference.recommendedhotels componentsSeparatedByString:@"\\"];
            for (NSString* singleComponent in componentsOfHotelString) {
                NSLog(@"Single Component: %@ \n",singleComponent);
                if(![[singleComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
                {
                    hotelsString = [hotelsString stringByAppendingString:[singleComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                    hotelsString = [hotelsString stringByAppendingString:@" \n"];
                }
            }
            [contentOfNinthSection addObject:hotelsString];
            [headerOfNinthSection addObject:conference_hotel_recommendations_en];
            
            [self.conferenceData addObject:contentOfNinthSection];
            [self.sectionHeaders addObject:headerOfNinthSection];
            
            [contentOfNinthSection release];
            [headerOfNinthSection release];
        }
    }
    else
        NSLog(@"Fehler beim Übertragen der Daten an ConferenceInformation");
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    //return [[self.conferenceData allKeys] count];
    return [self.sectionHeaders count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //return [[self.conferenceData mutableArrayValueForKey:[NSString stringWithFormat:@"%i",section]] count];
    return [[self.conferenceData objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    //NSMutableArray *objectsInThisSection = [self.conferenceData mutableArrayValueForKey:[NSString stringWithFormat:@"%i",indexPath.section]];
    NSMutableArray *objectsInThisSection = [self.conferenceData objectAtIndex:indexPath.section];
    cell.textLabel.numberOfLines = 5;
    cell.textLabel.text = [objectsInThisSection objectAtIndex:indexPath.row];
    
    if (self.conferenceLogoImage != nil)
    {
        cell.imageView.image = self.conferenceLogoImage;
    }
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //return [[self.sectionHeaders mutableArrayValueForKey:[NSString stringWithFormat:@"%i",section]] lastObject];
    return [[self.sectionHeaders objectAtIndex:section] lastObject];
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
- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
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
    
    //This method gets activated when the user clicks on a row in the information view table.
    
    //The method gets useful when the user clicks on the conference website or the time period when the conference takes place. In the first case the website gets opened and in the second case the user can add a date for this time period in his calendar. But to get this done we have to check on which item the user clicked
    
    //Hence first get the sectionHeader where the clicked row belongs to...
    
    NSArray *sectionHeader = [self.sectionHeaders objectAtIndex:indexPath.section];
    
    //If the sectionHeader string matches conference period
    if([[sectionHeader lastObject] isEqualToString:conference_period_en] || [[sectionHeader lastObject] isEqualToString:conference_period_de])
    {
        //... open UI to add conference dates to calendar
        
        //First setup a NSFetchRequest to get all conference details for Conference entity with the name which is stored in variable self.conferenceName.
        NSFetchRequest* getConferenceData = [[NSFetchRequest alloc] init];
        getConferenceData.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.conferenceContext];
        getConferenceData.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
        
        NSError *gettingDataError = nil;
        Conference* thisConference = [[self.conferenceContext executeFetchRequest:getConferenceData error:&gettingDataError] lastObject];
        [getConferenceData release];
        
        if(thisConference.startdate != nil)
        {    
            //If the conference has a start date, allocate and init a EKEventStore (a store for calendar dates)
            EKEventStore *eventDB = [[EKEventStore alloc] init];
            
            //Create a new event in this calendar store
            EKEvent *myEvent  = [EKEvent eventWithEventStore:eventDB];
            
            //Give the event the same name as the conference's name
            myEvent.title = self.conferenceName;
            
            //If there is explicitly set a timezone where the conference takes place
            if(thisConference.timezone != nil && ![thisConference.timezone isEqualToString:@""])
            {
                NSArray* timeZonesArray = [NSTimeZone knownTimeZoneNames];
                
                bool timeZoneIsSet = false;
                
                //Search in the list of all available iOS timezones for this timezone string
                for (NSString* timeZoneInArray in timeZonesArray)
                {
                    if([timeZoneInArray isEqualToString:thisConference.timezone])
                    {
                        //If there is a match, set the event timezone to this matched timezone
                        myEvent.timeZone = [[[NSTimeZone alloc] initWithName:timeZoneInArray] autorelease];
                        timeZoneIsSet = true;
                    }
                }
                
                if(!timeZoneIsSet)
                {
                    //If there is no match, set the system timezone of the smartphone
                    myEvent.timeZone = [NSTimeZone systemTimeZone];
                }
            }
            
            //Finally set the start date of the event to the start date of the conference.
            myEvent.startDate = thisConference.startdate;
            
            
            //If there was duration defined
            if(thisConference.duration != nil)
            {   
                //Compute the conferenceEndDate
                NSCalendar *neededCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                NSDateComponents* newDateComponents = [neededCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:thisConference.startdate];
                newDateComponents.day = newDateComponents.day + [thisConference.duration intValue];
                NSDate* conferenceEndDate = [neededCalendar dateFromComponents:newDateComponents];
                [neededCalendar release];
                
                //And set the end date of the event to this computed once.
                myEvent.endDate = conferenceEndDate;
                
            }
            else
            {
                //Else the end date is equivalent to the start date.
                myEvent.endDate = myEvent.startDate;
            }
            
            //Set the event to occur the whole day (block all conference days in the calendar)
            myEvent.allDay = YES;
            
            //Now bring all these informations to the user with a new EKEventEditViewController
            EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
            addController.eventStore = eventDB;
            addController.event=myEvent;
            addController.title = @"Termin hinzufügen";
            
            //And present this view modally (means the background is still active)
            [self presentModalViewController:addController animated:YES];
            
            //And lets delegate the edit view by this class.
            addController.editViewDelegate = self;
            [addController release];
            [eventDB release];   
        }
    }
    
    //if the section header string matches the website header...
    if([[sectionHeader lastObject] isEqual:website_label_en] || [[sectionHeader lastObject] isEqual:website_label_de])
    {
        //get conference details
        NSFetchRequest* getConferenceData = [[NSFetchRequest alloc] init];
        getConferenceData.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.conferenceContext];
        getConferenceData.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
        
        NSError *gettingDataError = nil;
        Conference* thisConference = [[self.conferenceContext executeFetchRequest:getConferenceData error:&gettingDataError] lastObject];
        [getConferenceData release];
        
        //And open the website in safari browser
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:thisConference.homepageurl]];
        
        
    }
}

@end
