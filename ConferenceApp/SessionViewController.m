//  SessionViewController.m
//  ConferenceApp

#import "SessionViewController.h"
#import "User.h"
#import "Session.h"
#import "Tag.h"
#import "SpeakerPickerViewController.h"
#import "SpeakerViewController.h"
#import "VenueViewController.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "SHK.h"
#import "Conference.h"

//Multilinguale Einstellungen zur Darstellung
#define speakers_deutsch @"Referenten"
#define speakers_englisch @"Speakers"

#define no_speakers_deutsch @"Keine Referenten"
#define no_speakers_english @"No Speakers"

#define information_about_speakers_deutsch @"Weitere Infos zu den Refenten"
#define information_about_speakers_english @"More Informations about the Speakers"

#define room_german @"Raum"
#define room_english @"room"

#define no_date_given_header_de @"Keine Termindaten vorhanden!"
#define no_date_given_header_en @"No Date Given"

#define no_date_given_de @"Für diesen Vortrag liegen keine Termindaten vor. Hinzufügen eines Termins nicht möglich."
#define no_date_given_en @"For this session no dates are given. Hence adding a date is not possible."

#define time_overlay_header_de @"Zeitüberschneidung"
#define time_overlay_header_en @"Time Overlay"

#define time_overlay_de @"Es gibt eine Zeitüberschneidung mit den Session(s): %@"
#define time_overlay_en @"There is a time overlay with session(s): %@"

#define session_not_available_header_de @"Session nicht mehr verfügbar!"
#define session_not_available_header_en @"Session not available any more!"

#define session_not_available_de @"Verlassen Sie diese Ansicht und kehren Sie zurück zur Übersicht!"
#define session_not_available_en @"Exit this window and go back to the session overview!"

@implementation SessionViewController
@synthesize sessionTitleLabel, sessionTagsLabel, sessionDateLabel, descriptionLabel, favedButton, speakerButton, venueButton, tagButton, addEventButton, speakersLabel, venueAndRoomLabel, conferenceName, storeURL;
@synthesize sessionDescriptionString, sessionNSDate, sessionSpeakerSet, sessionTagSet, sessionStartTime, sessionTitleString, objectContext, sessionID, roomNameString, venueOfTheSession, sessionDuration;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (IBAction) shareSession:(UIButton *)sender
{
    NSFetchRequest* getAllNeededData = [[NSFetchRequest alloc] init];
    getAllNeededData.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.objectContext];
    getAllNeededData.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
    
    NSError *fetchingAllDataError = nil;
    Conference* ourConference = [[[self.objectContext executeFetchRequest:getAllNeededData error:&fetchingAllDataError] lastObject] retain];
    [getAllNeededData release];
    if(!fetchingAllDataError && ourConference != nil)
    {
        //Keine Fehlermeldung und conference existiert.
        
        //TODO
        // Create the item to share (in this example, a url)
        if(ourConference.acronym != nil && ![ourConference.acronym isEqualToString:@""])
        {
            //Wenn Hashtag existiert
            SHKItem *item = [SHKItem text:[NSString stringWithFormat:@"%@ #%@",self.sessionTitleString,ourConference.acronym]];
            // Get the ShareKit action sheet
            SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item]; 
            // Display the action sheet
            [actionSheet showInView:self.view];
        }
        else
        {
            SHKItem *item = [SHKItem text:self.sessionTitleString];
            // Get the ShareKit action sheet
            SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item]; 
            // Display the action sheet
            [actionSheet showInView:self.view];
        }
    }
    else
    {
        SHKItem *item = [SHKItem text:self.sessionTitleString];
        // Get the ShareKit action sheet
        SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item]; 
        // Display the action sheet
        [actionSheet showInView:self.view];
    }
    [ourConference release];
}


- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction) addToiOSCalendar:(UIButton *)sender
{
    //This method gets called when the user clicks on the calendar button to add the session to the internal iOS calendar
    
    //First request session data...
    NSFetchRequest* requestData = [[NSFetchRequest alloc] init];
    [requestData setAffectedStores:[NSArray arrayWithObject:[[self.objectContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    requestData.entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.objectContext];
    requestData.predicate = [NSPredicate predicateWithFormat:@"sessionid = %@", self.sessionID];
    NSError* errorDuringRequestingData = nil;
    
    //And save it.
    Session* sessionOfThisView = [[self.objectContext executeFetchRequest:requestData error:&errorDuringRequestingData] lastObject];
    [requestData release];
    if(!errorDuringRequestingData)
    {
        if (sessionOfThisView.date != nil) {
            //If there was no error while fetching data and session has specified a date.
            
            //Create a event storage
            EKEventStore *eventDB = [[EKEventStore alloc] init];
            
            //Then create a event (date)
            EKEvent *myEvent  = [EKEvent eventWithEventStore:eventDB];
            
            //Set session title as event title
            myEvent.title = sessionOfThisView.title;
            
            if(sessionOfThisView.starttime != nil)
            {
                //If a starttime is specified
                //... combine date and time in one NSDate
                NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                NSDateComponents *hourMinuteComponents = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:sessionOfThisView.starttime];
                NSDateComponents *startDateCompleteComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:sessionOfThisView.date];
                startDateCompleteComponents.hour = hourMinuteComponents.hour;
                startDateCompleteComponents.minute = hourMinuteComponents.minute;
                               

                NSDate *completeStartDate = [calendar dateFromComponents:startDateCompleteComponents];
                myEvent.startDate = [completeStartDate copy];
                myEvent.allDay = NO;
                [completeStartDate release];
                
                //Prepare NSFetchRequest to get all conference details
                NSFetchRequest* getAllNeededData = [[NSFetchRequest alloc] init];
                getAllNeededData.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.objectContext];
                getAllNeededData.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
                
                NSError *fetchingAllDataError = nil;
                
                //Save conference in thisConference variable and set timezone of date according to the timezone specified in conference data
                Conference* thisConference = [[[self.objectContext executeFetchRequest:getAllNeededData error:&fetchingAllDataError] lastObject] retain];
                [getAllNeededData release];
                if(thisConference != nil && !fetchingAllDataError)
                {
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
                }
                
                //If duration is specified compute enddate else set startdate as end date
                if(sessionOfThisView.duration != nil && ![sessionOfThisView.duration isEqualToString:@""])
                {
                    //Compute enddate and save it
                    int duration_all = [sessionOfThisView.duration intValue];
                    int duration_hours = duration_all/60;
                    int duration_minutes = [sessionOfThisView.duration intValue] - duration_hours * 60;
                    NSDateComponents *endDateComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:myEvent.startDate];
                    endDateComponents.hour = endDateComponents.hour + duration_hours;
                    endDateComponents.minute = endDateComponents.minute + duration_minutes;
                    myEvent.endDate = [calendar dateFromComponents:endDateComponents];
                }
                else
                    myEvent.endDate = myEvent.startDate;
                
                [calendar release];
            }
            else
            {
                //If not starttime is specified set allday to yes
                NSLog(@"Kein Startzeitpunkt vorhanden!");
                myEvent.startDate = sessionOfThisView.date;
                myEvent.endDate = myEvent.startDate;
                myEvent.allDay = YES;
            }
            
            //Set venue details to the event (date)
            myEvent.location = @"";
            if(venueOfTheSession != nil)
            {
                myEvent.location = venueOfTheSession.name;
                myEvent.location = [myEvent.location stringByAppendingString:@" "];
            }
            
            if(sessionOfThisView.roomname != nil && ![sessionOfThisView.roomname isEqualToString:@""])
                myEvent.location =[myEvent.location stringByAppendingFormat:@"%@: %@",room_english,sessionOfThisView.roomname];
            
            //Prepare view which is showing all information and makes it possible to store information in calendar
            EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
            addController.eventStore = eventDB;
            addController.event=myEvent;
            addController.title = @"Termin hinzufügen";
            [self presentModalViewController:addController animated:YES];
            
            addController.editViewDelegate = self;
            [addController release];
            
            [eventDB release];
        }
        else
        {
            //If no date is specified, show a message to the user.
            UIAlertView *noDateGiven = [[UIAlertView alloc] initWithTitle:no_date_given_header_en message:no_date_given_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [noDateGiven show];
            [noDateGiven release];
        }
    }
}

-  (SessionViewController *) initWithSessionID:(NSString *)inputSessionID andManagedObjectContext:(NSManagedObjectContext *)context andConference:(NSString *)targetedConferenceName
{
    //This method creates a new instance of this class with all informations about the session which should be displayed.
    
    //First set all attributes of the method to the corresponding variable
    self.sessionID = inputSessionID;
    self.objectContext = context;
    self.conferenceName = targetedConferenceName;
    
    //Add store to store coordinator
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    NSString* storeFileName = [NSString stringWithFormat:@"%@",self.conferenceName];
    self.storeURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:storeFileName]];
    [[self.objectContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:nil];
    
    //Then fetch session details
    NSFetchRequest* requestData = [[NSFetchRequest alloc] init];
    [requestData setAffectedStores:[NSArray arrayWithObject:[[self.objectContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    requestData.entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.objectContext];
    requestData.predicate = [NSPredicate predicateWithFormat:@"sessionid = %@", self.sessionID];
    NSError* errorDuringRequestingData = nil;
    
    //Save session
    Session* sessionOfThisView = [[self.objectContext executeFetchRequest:requestData error:&errorDuringRequestingData] lastObject];
    [requestData release];
    if(!errorDuringRequestingData)
    {
        if(sessionOfThisView != nil)
        {
            //If there was no error during fetching information and corresponding session was found, set all data to the corresponding variables
            
            self.sessionTitleString = sessionOfThisView.title;
            self.sessionDescriptionString = sessionOfThisView.abstract;
            self.sessionSpeakerSet = sessionOfThisView.hasSpeakers;
            self.sessionTagSet = sessionOfThisView.hasTags;
            self.sessionNSDate = sessionOfThisView.date;
            self.sessionStartTime = sessionOfThisView.starttime;
            self.roomNameString = sessionOfThisView.roomname;
            self.venueOfTheSession = sessionOfThisView.invenue;
            self.sessionDuration = sessionOfThisView.duration;            
        }
        else
        {
            NSLog(@"No session found.");
        }
    }
    else
    {
        NSLog(@"Error while fetching data");
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void) isThereAnOverlayByFavingSession:(Session *)currentSession WithSender:(UIButton *)sender
{
    //Prepare NSFetchRequest to get all conference details
    NSFetchRequest* getAllNeededData = [[NSFetchRequest alloc] init];
    getAllNeededData.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.objectContext];
    getAllNeededData.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
    
    NSError *fetchingAllDataError = nil;
    
    //Save conference in ourConference variable
    Conference* ourConference = [[[self.objectContext executeFetchRequest:getAllNeededData error:&fetchingAllDataError] lastObject] retain];
    [getAllNeededData release];
    if(ourConference != nil && !fetchingAllDataError)
    {
        //If conference is found
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
        
        //Set completeOverlay to false at beginning
        BOOL completeOverlay = false;
        NSString *overlaySessions = [[[NSString alloc] init] autorelease];

        if(currentSession.date != nil && currentSession.starttime != nil)
        {
            //Check whether the session, which the user wants to favorize, has specified a date and starttime. If so, load all already favorized sessions
            
                        
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setAffectedStores:[NSArray arrayWithObject:[[self.objectContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.objectContext];
            [request setEntity:entity];
            
            request.predicate = [NSPredicate predicateWithFormat:@"isfaved = %@", [NSNumber numberWithBool:YES]];
            
            NSError *error = nil;
            
            //Save all faved sessions in this variable
            NSArray* allFavedSessions = [[[self.objectContext executeFetchRequest:request error:&error] mutableCopy] autorelease];
            
            if (allFavedSessions == nil || error != nil) {
                
                // Handle the error.
                NSLog(@"No favorized sessions or something went wrong.");
                
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
        }
        
        if(completeOverlay)
        {
            //If there is an overlay, send a message to the user
            UIAlertView *dateOverlay = [[UIAlertView alloc] initWithTitle:time_overlay_header_en message:[NSString stringWithFormat:time_overlay_en,overlaySessions] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [dateOverlay show];
            [dateOverlay release];
        }
        else
        {
            //else fav currentSession
            [currentSession setIsfaved:[NSNumber numberWithBool:YES]];
            
            //Save changes
            NSError *error;
            if (![self.objectContext save:&error]) {
                // Handle the error.
                NSLog(@"Saving changes failed: %@", error.description);
                
            }                           
            [sender setSelected:YES];
        }
        
        [innerPool drain];
    }
    [ourConference release];
}
- (IBAction) changeFavState:(UIButton *)sender
{
    //This method gets called when the user clicks on the fav button
    if(![self.sessionID isEqualToString:@""] && self.objectContext != nil)
    {
        //Session ID is not empty and managedObjectContext exists
        NSFetchRequest* isFavedRequest = [[NSFetchRequest alloc] init];
        [isFavedRequest setAffectedStores:[NSArray arrayWithObject:[[self.objectContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
        isFavedRequest.entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.objectContext];
        isFavedRequest.predicate = [NSPredicate predicateWithFormat:@"sessionid = %@",self.sessionID];
        NSError* fetchError = nil;
        
        //Save session properties
        Session* sessionWithSameID = [[self.objectContext executeFetchRequest:isFavedRequest error:&fetchError] lastObject];
        [isFavedRequest release];
        if(!fetchError)
        {
            //There was no request error
            if(sessionWithSameID != nil)
            {
                //There is a session with the requested ID, check fav state. If session was faved, unfav it and if it was unfaved, call the method isThereAnOverlayByFavingSession which is checking for overlays which could occur with faving this session
                switch ([sessionWithSameID.isfaved boolValue]) {
                    case YES:
                        sessionWithSameID.isfaved = [NSNumber numberWithBool:NO];
                        NSError *savError = nil;
                        if(![self.objectContext save:&savError])
                            NSLog(@"Error while changing fav state.");
                        [sender setSelected:NO];
                        break;
                    
                    default:
                        
                        [self isThereAnOverlayByFavingSession:sessionWithSameID WithSender:sender];
                        break;
                }
            }
            else
                NSLog(@"Session could not be found.");
        }
    }
}

- (void) speakerPickerViewController:(SpeakerPickerViewController *)sender didChooseSpeakerWithID:(NSString *)chosenSpeakerID
{
    
    //This method gets called after the user has chosen a speaker in the picker view. Then a detailed view (instance of class SpeakerViewController) will be presented on screen.
    
    //First remove the picker view controller from screen directly
    [self dismissModalViewControllerAnimated:NO];
    
    //Allocate and initiate the detailed view controller
    SpeakerViewController* chosenSpeakerViewController = [[SpeakerViewController alloc] initWithSpeakerID:chosenSpeakerID andManagedObjectContext:self.objectContext andConference:self.conferenceName];
    
    //Add it to the view.
    [self.navigationController pushViewController:chosenSpeakerViewController animated:NO];
    [chosenSpeakerViewController release];
}

- (void) abortByPickerViewController:(SpeakerPickerViewController *)sender
{
    //If the user aborts during the picker view controller is shown, remove the picker view from screen.
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction) moreInformationAboutSpeaker:(UIButton *)sender
{
    //This method gets called when the user clicks on the button on the left side of the speaker names. A PickerView will be displayed (instance of class SpeakerPickerViewController) which shows all speakers of this view. Then the user can choose one and gets more information about this speaker.
    
    //Allocate and initiate a new SpeakerPickerViewController instance
    SpeakerPickerViewController *newPickerView = [[SpeakerPickerViewController alloc] initWithSessionID:self.sessionID andContext:self.objectContext andConferenceName:self.conferenceName];
    newPickerView.delegate = self;
    newPickerView.view.bounds = self.view.bounds;
    
    //Present it modally on the screen
    [self presentModalViewController:newPickerView animated:YES];
    [newPickerView release];
}

- (IBAction) moreInformationAboutVenue:(UIButton *)sender
{
    //This method gets called when the user clicks on the button on the left side of the venue information textlabel
    if(self.venueOfTheSession != nil)
    {
        //If there is a venue specified for this session, show a detailed venueInformationController
        VenueViewController *venueInformationController = [[VenueViewController alloc] initWithVenue:self.venueOfTheSession];
        [self.navigationController pushViewController:venueInformationController animated:YES];
        [venueInformationController release];
    }
}

- (void) handleSwiping
{
    // when the user swipes to the left, remove session info view from screen
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSAutoreleasePool *viewReleasePool = [[NSAutoreleasePool alloc] init];
    
    // Do any additional setup after loading the view from its nib.
    
    //Add a swipe gesture recognizer for swipe to the left, to remove view from screen.
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(handleSwiping)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeRecognizer];
    [swipeRecognizer release];
    
    //Set session title as the view title 
    self.sessionTitleLabel.text = self.sessionTitleString;
    
    //Configure buttons
    self.tagButton.alpha = 0.0;
    self.tagButton.enabled = NO;
    
    //If there is at least one tag specified for this session
    if([self.sessionTagSet count])
    {
        //enable tag button
        self.tagButton.alpha = 1.0;
        self.tagButton.enabled = YES;
        
        //And write all tags to a text label.
        int loopVariable = 1;
        for (Tag* currentTag in self.sessionTagSet) {
            if(loopVariable == 1)
            {
                self.sessionTagsLabel.text = [self.sessionTagsLabel.text stringByAppendingFormat:@"%@",currentTag.name];
                loopVariable = loopVariable + 1;
            }
            else
            {
                self.sessionTagsLabel.text = [self.sessionTagsLabel.text stringByAppendingFormat:@", %@",currentTag.name];
            }
        }
    }

    //Set description text
    self.descriptionLabel.text = self.sessionDescriptionString;
    
    //Preset all further buttons to be not visible and deactivate the buttons
    self.favedButton.alpha = 0.0;
    self.favedButton.enabled = NO;

    self.speakerButton.alpha = 0.0;
    self.speakerButton.enabled = NO;

    self.venueButton.alpha = 0.0;
    self.venueButton.enabled = NO;
    
    self.addEventButton.alpha = 0.0;
    self.addEventButton.enabled = NO;
    
    self.speakersLabel.alpha = 0.0;

    
    if(self.sessionNSDate != nil)
    {
        //If date is specified, show button to add event to iCal calendar
        self.addEventButton.alpha = 1.0;
        self.addEventButton.enabled = TRUE;
        
        //and show date in a textlabel
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd.MM.YYYY"];
        self.sessionDateLabel.text = [dateFormatter stringFromDate:self.sessionNSDate];
        [dateFormatter release];
    }
    
    if(self.sessionStartTime != nil)
    {
        //If starttime is specified, add it to the textlabel
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm"];
        self.sessionDateLabel.text = [self.sessionDateLabel.text stringByAppendingString:@" "];        
        self.sessionDateLabel.text = [self.sessionDateLabel.text stringByAppendingString:[dateFormatter stringFromDate:self.sessionStartTime]];
        [dateFormatter release];

        //and if duration is specified, compute end date and write it to the label
        if(self.sessionDuration != nil && ![self.sessionDuration isEqualToString:@""])
        {
            //Dauer angegeben
            NSCalendar* myHomeCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            NSDateComponents *dateSession = [myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:sessionNSDate];
            NSDateComponents *timeSession = [myHomeCalendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:sessionStartTime];
            
            dateSession.hour = timeSession.hour;
            dateSession.minute = timeSession.minute;
            
            NSInteger dateBefore = dateSession.day;
            NSInteger monthBefore = dateSession.month;
            NSInteger yearBefore = dateSession.year;
            BOOL somethingIsChanging = false;
            
            int duration_all = [self.sessionDuration intValue];
            int duration_hours = duration_all/60;
            int duration_minutes = [self.sessionDuration intValue] - duration_hours * 60;
                        
            dateSession.hour = dateSession.hour + duration_hours;
            dateSession.minute = dateSession.minute + duration_minutes;
            NSDate* endDateOfSession = [myHomeCalendar dateFromComponents:dateSession];
            
            NSDateComponents *newComponents = [myHomeCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:endDateOfSession];
            
            if(newComponents.day != dateBefore || newComponents.month != monthBefore || newComponents.year != yearBefore)
            {
                somethingIsChanging = true;
            }
            
            //Create enddate
            
            if(somethingIsChanging)
            {
                NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"dd.MM.YYYY HH:mm"];
                self.sessionDateLabel.text = [self.sessionDateLabel.text stringByAppendingFormat:@" \n - \n %@",[dateFormatter stringFromDate:endDateOfSession]];
                [dateFormatter release];
            }
            else
            {
                NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"HH:mm"];
                self.sessionDateLabel.text = [self.sessionDateLabel.text stringByAppendingFormat:@" \n - \n %@",[dateFormatter stringFromDate:endDateOfSession]];
                [dateFormatter release];
            }
            [myHomeCalendar release];
        }
    }
    
    //If venue to session is specified, enable venue button and set text.
    self.venueAndRoomLabel.text = @"";
    if(self.venueOfTheSession != nil)
    {
        self.venueAndRoomLabel.text = [self.venueAndRoomLabel.text stringByAppendingString:self.venueOfTheSession.name];
        self.venueButton.enabled = YES;
        self.venueButton.alpha = 1.0;
    }
    
    //If room is specified, add it to the text label
    if(self.roomNameString != nil)
    {
        self.venueAndRoomLabel.text = [self.venueAndRoomLabel.text stringByAppendingString:@" "];
        self.venueAndRoomLabel.text = [self.venueAndRoomLabel.text stringByAppendingFormat:@"%@: %@",room_english,self.roomNameString];
    }
    
    if(![self.sessionID isEqualToString:@""] && self.objectContext != nil)
    {
        //If session ID exists, fetch Session.
        NSFetchRequest* isFavedRequest = [[NSFetchRequest alloc] init];
        [isFavedRequest setAffectedStores:[NSArray arrayWithObject:[[self.objectContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
        isFavedRequest.entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.objectContext];
        isFavedRequest.predicate = [NSPredicate predicateWithFormat:@"sessionid = %@",self.sessionID];
        NSError* fetchError = nil;
        
        //Save it
        Session* sessionWithSameID = [[self.objectContext executeFetchRequest:isFavedRequest error:&fetchError] lastObject];
        [isFavedRequest release];
        if(!fetchError)
        {
            //If no error occured
            if(sessionWithSameID != nil)
            {
                //Enable fav button
                self.favedButton.enabled = YES;
                self.favedButton.alpha = 1.0;
                
                //If the session is already faved, set selected status to YES and to NO if not faved 
                if([sessionWithSameID.isfaved boolValue])
                {
                    [self.favedButton setSelected:YES];
                    [self.favedButton setNeedsDisplay];
                }
                else
                {
                    [self.favedButton setSelected:NO];
                    [self.favedButton setNeedsDisplay];
                }
            }
            else
            {
                //If session not available, show warning message
                UIAlertView *sessionNotAvailable = [[UIAlertView alloc] initWithTitle:session_not_available_header_en message:session_not_available_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [sessionNotAvailable show];
                [sessionNotAvailable release];
            }
        }
    }
    
    if([self.sessionSpeakerSet count] > 0)
    { 
        //If there are speakers specified to the session, enable speaker labels
        self.speakersLabel.alpha = 1.0;
        self.speakersLabel.textColor = [UIColor blackColor];
        int speakerloop = 0;
        for(User* speakerOfSession in self.sessionSpeakerSet)
        {
            //For each speaker
            if (speakerloop < 2) //Maximal 2 Sprecher anzeigen
            {
                //If the current speaker is the first, second or third one
                if(speakerloop > 0 && speakerloop != 2)
                {
                    //If the current speaker is not the first one, add a commata to the text label
                    self.speakersLabel.text = [self.speakersLabel.text stringByAppendingString:@", "];
                }
                
                //Add speakers name to the text labal
                self.speakersLabel.text = [self.speakersLabel.text stringByAppendingString:speakerOfSession.firstname];
                self.speakersLabel.text = [self.speakersLabel.text stringByAppendingString:@" "];
                self.speakersLabel.text = [self.speakersLabel.text stringByAppendingString:speakerOfSession.lastname];
            }
            else
            {
                //If the current speaker is the 4th one, add et al. and exit loop
                self.speakersLabel.text = [self.speakersLabel.text stringByAppendingString:@" et al."];
                break;
            }
            speakerloop = speakerloop + 1;
        }

        //Enable speaker Button
        self.speakerButton.alpha = 1.0;
        self.speakerButton.enabled = YES;
        
        //Configure text label to get all content in the visible area
        self.speakerButton.titleLabel.numberOfLines = 1;
        self.speakerButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.speakerButton.titleLabel.lineBreakMode = UILineBreakModeClip;
        
        //Set title for speaker button
        [self.speakerButton setTitle:information_about_speakers_english forState:UIControlStateNormal];
    }
    else
    {
        //If no speakers specified for this session, write this in the speakers label
        self.speakersLabel.alpha = 1.0;
        self.speakersLabel.textColor = [UIColor redColor];
        self.speakersLabel.text = no_speakers_english;
    }

    [viewReleasePool drain];
}

- (void)viewDidUnload
{
    NSLog(@"viewDidUnload is called of SessionView!");
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. myOutlet = nil;
    self.sessionTitleLabel = nil;
    self.sessionTagsLabel = nil;
    self.sessionDateLabel = nil;
    self.descriptionLabel = nil;
    self.objectContext = nil;
    self.favedButton = nil;
    self.speakerButton = nil;
    self.venueButton = nil;
    self.tagButton = nil;
    self.addEventButton = nil;
    self.speakersLabel = nil;
    self.venueAndRoomLabel = nil;
    
    self.sessionID = nil;
    self.sessionDescriptionString = nil;
    self.sessionTitleString = nil;
    self.sessionSpeakerSet = nil;
    self.sessionTagSet = nil;
    self.sessionStartTime = nil;
    self.sessionNSDate = nil;
    self.roomNameString = nil;
    self.venueOfTheSession = nil;
    self.storeURL = nil;
    self.conferenceName = nil;
    self.sessionDuration = nil;
    self.sessionDuration = nil;

}

- (void)dealloc
{
    NSLog(@"Dealloc is called of SessionView!");
    [sessionTitleLabel release];
    [sessionTagsLabel release];
    [sessionDateLabel release];
    [descriptionLabel release];
    [objectContext release];
    [favedButton release];
    [speakerButton release];
    [venueButton release];
    [tagButton release];
    [addEventButton release];
    [speakersLabel release];
    [venueAndRoomLabel release];
    
    [sessionID release];
    [sessionDescriptionString release];
    [sessionTitleString release];
    [sessionSpeakerSet release];
    [sessionTagSet release];
    [sessionStartTime release];
    [sessionNSDate release];
    [roomNameString release];
    [venueOfTheSession release];
    [storeURL release];
    
    [conferenceName release];
    //[view removeFromSuperview];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
