//  AddConferenceViewController.m
//  ConferenceApp

#import "AddConferenceViewController.h"
#import "Conference.h"
#import "WelcomeViewController.h"
#import "TBXML.h"

#define successful_import_de @"Erfolgreicher Import!"
#define successful_import_en @"Successful Import!"

#define abort_import_de @"Import abgebrochen!"
#define abort_import_en @"Import Abort"

#define message_successful_import_de @"Konferenz-Import wurde erfolgreich abgeschlossen!"
#define message_successful_import_en @"Conference Data were imported successfully!"

#define message_same_name_de @"Konferenz mit gleichem Namen existiert bereits!"
#define message_same_name_en @"Conference with the same name already exists!"

#define message_import_couldnt_be_completely_loaded_de @"Es konnten nicht alle erforderlichen Daten geladen werden. Import wurde abgebrochen"
#define message_import_couldnt_be_completely_loaded_en @"Import couldn't be completed."

#define wrong_xml_file_de @"Die Datei ist fehlerhaft."
#define wrong_xml_file_en @"The file is faulty."

#define file_couldnt_be_found_de @"Die Datei konnte unter der URL %@ nicht gefunden werden."
#define file_couldnt_be_found_en @"The file couldn't be found at URL %@"

@implementation AddConferenceViewController
@synthesize conferenceXMLUrlTextfield, addContext;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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
    [conferenceXMLUrlTextfield release];
    [addContext release];
    [super dealloc];
}
- (void) handleSwiping
{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad
{
    //This class is responsible to provide UI and background for adding a new conference to the App.
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //First add a swipe gesture recognizer to recognize a swipe to the left (get back)
    UISwipeGestureRecognizer* swipingToTheRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwiping)];
    swipingToTheRight.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipingToTheRight];
    [swipingToTheRight release];
    
    //Set textfield delegate to the instance of this class to remove keyboard after user typed in the conference.xml url etc.
    self.conferenceXMLUrlTextfield.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.conferenceXMLUrlTextfield = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
- (IBAction)pushAddConference:(id)sender
{
    //This is the main method of this class. It gets called when the user clicks on the add button to add the conference with the conference.xml url specified in the textfield
    if([self.conferenceXMLUrlTextfield.text length])
    {
        //If the user has written something into this textfield, get real XML URL by removing whitespace characters
        NSString* conferenceXMLPath;
        conferenceXMLPath = [self.conferenceXMLUrlTextfield.text stringByReplacingOccurrencesOfString:@" " withString:@""];

        //Then load the data in background
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData* xmlData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:conferenceXMLPath]];
            dispatch_async( dispatch_get_main_queue(), ^{
                if(xmlData != nil)
                {
                    //If there is some data behind URL, start XML Parser
                    TBXML* tbxml = [TBXML tbxmlWithURL:[NSURL URLWithString:conferenceXMLPath]];
                    TBXMLElement * root = tbxml.rootXMLElement;
                    
                    if (root)
                    {
                        //If root in XML doc was found, read out all properties
                        
                        TBXMLElement* conferenceName = [TBXML childElementNamed:@"name" parentElement:root];
                        TBXMLElement* startDateOfConference = [TBXML childElementNamed:@"startdate" parentElement:root];
                        TBXMLElement* durationOfConference = [TBXML childElementNamed:@"duration" parentElement:root];
                        TBXMLElement* topicOfConference = [TBXML childElementNamed:@"topic" parentElement:root];
                        TBXMLElement* contactForConference = [TBXML childElementNamed:@"contact" parentElement:root];
                        TBXMLElement* homepageURLOfConference = [TBXML childElementNamed:@"homepageurl" parentElement:root];
                        TBXMLElement* imprintOfConference = [TBXML childElementNamed:@"imprint" parentElement:root];
                        
                        //Check whether there is already a conference with the same name in our local store on the smartphone, than prohibit to save it again on memory
                        NSFetchRequest* sameConferenceName = [[NSFetchRequest alloc] init];
                        sameConferenceName.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:addContext];
                        sameConferenceName.predicate = [NSPredicate predicateWithFormat:@"name = %@",[TBXML textForElement:conferenceName]];
                        
                        NSError* sameConferenceNameError;
                        
                        //This variable sameNameConference gets nil, if there is no conference with same name and unequal to nil, if there is such a conference
                        Conference *sameNameConference = [[addContext executeFetchRequest:sameConferenceName error:&sameConferenceNameError] lastObject];
                        [sameConferenceName release];
                        
                        if(conferenceName != nil && startDateOfConference != nil && durationOfConference != nil && topicOfConference != nil && contactForConference != nil && homepageURLOfConference != nil && imprintOfConference != nil && sameNameConference == nil)
                        {
                            
                            //If all needed data is there, add a new conference and set the properties
                                                        
                            Conference* newConference = [Conference initConferenceWithContext:addContext];
                            newConference.name = [TBXML textForElement:conferenceName];
                            newConference.topic = [TBXML textForElement:topicOfConference];
                            newConference.contact = [TBXML textForElement:contactForConference];
                            newConference.homepageurl = [TBXML textForElement:homepageURLOfConference];
                            newConference.imprint = [TBXML textForElement:imprintOfConference];
                            newConference.conferencexmlurl = conferenceXMLPath;
                            
                            //If startdate is specified
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
                                    
                                    newConference.startdate = finalDate;
                                }
                                else
                                {
                                    //If date is not valid set startdate to nil.
                                    newConference.startdate = nil;
                                }
                            }                   
                   
                            //Then save duration entry. Gets nil if entry does not exists or entry is not a number. For numbers it only counts the digits before the commata.
                            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                            [f setNumberStyle:NSNumberFormatterDecimalStyle];
                            newConference.duration = [f numberFromString:[TBXML textForElement:durationOfConference]];
                            [f release];
                            
                                                        
                            //Further check all the other entries and set them if they are set
                            
                            TBXMLElement* conditionsForConference = [TBXML childElementNamed:@"conditions" parentElement:root];
                            if(conditionsForConference)
                                newConference.conditions = [TBXML textForElement:conditionsForConference];
                            

                            TBXMLElement* recommendedHotelsForeConference = [TBXML childElementNamed:@"recommendedhotels" parentElement:root];
                            if(recommendedHotelsForeConference)
                                newConference.recommendedhotels = [TBXML textForElement:recommendedHotelsForeConference];
                            
                            TBXMLElement* conferenceLogoUrl = [TBXML childElementNamed:@"conferencelogourl" parentElement:root];
                            if(conferenceLogoUrl)
                                newConference.conferencelogourl = [TBXML textForElement:conferenceLogoUrl];
                            
                            TBXMLElement* sponsorXMLURLForConference = [TBXML childElementNamed:@"sponsorxmlurl" parentElement:root];
                            if(sponsorXMLURLForConference && ![[TBXML textForElement:sponsorXMLURLForConference] isEqualToString:@""])
                                newConference.sponsorxmlurl = [TBXML textForElement:sponsorXMLURLForConference];
                            
                            TBXMLElement* venueXMLURLForConference = [TBXML childElementNamed:@"venuexmlurl" parentElement:root];
                            if(venueXMLURLForConference && ![[TBXML textForElement:venueXMLURLForConference] isEqualToString:@""])
                                newConference.venuexmlurl = [TBXML textForElement:venueXMLURLForConference];
                            
                            TBXMLElement* sessionXMLURLForConference = [TBXML childElementNamed:@"sessionxmlurl" parentElement:root];
                            if(sessionXMLURLForConference && ![[TBXML textForElement:sessionXMLURLForConference] isEqualToString:@""])
                                newConference.sessionxmlurl = [TBXML textForElement:sessionXMLURLForConference];
                            
                            TBXMLElement* userXMLURLForConference = [TBXML childElementNamed:@"userxmlurl" parentElement:root];
                            if(userXMLURLForConference && ![[TBXML textForElement:userXMLURLForConference] isEqualToString:@""])
                                newConference.userxmlurl = [TBXML textForElement:userXMLURLForConference];
                            
                            TBXMLElement* targetedaudienceOfConference = [TBXML childElementNamed:@"targetedaudience" parentElement:root];
                            if(targetedaudienceOfConference)
                                newConference.targetedaudience = [TBXML textForElement:targetedaudienceOfConference];
                            
                            TBXMLElement *sloganOfConference = [TBXML childElementNamed:@"slogan" parentElement:root];
                            if(sloganOfConference)
                                newConference.slogan = [TBXML textForElement:sloganOfConference];
                            
                            
                            TBXMLElement* timeZoneOfConference = [TBXML childElementNamed:@"timezone" parentElement:root];
                            if(timeZoneOfConference)
                                newConference.timezone = [TBXML textForElement:timeZoneOfConference];
                            
                            TBXMLElement* registrationURLForConference = [TBXML childElementNamed:@"registrationurl" parentElement:root];
                            if(registrationURLForConference)
                                newConference.registrationurl = [TBXML textForElement:registrationURLForConference];
                            
                            TBXMLElement* acronymOfConference = [TBXML childElementNamed:@"acronym" parentElement:root];
                            if(acronymOfConference)
                                newConference.acronym = [TBXML textForElement:acronymOfConference];
                            
                            TBXMLElement* newsFeedURLForConference = [TBXML childElementNamed:@"newsfeedurl" parentElement:root];
                            if(newsFeedURLForConference)
                                newConference.newsfeedurl = [TBXML textForElement:newsFeedURLForConference];
                            
                            TBXMLElement* journeyPlanOfConference = [TBXML childElementNamed:@"journeyplan" parentElement:root];
                            if(journeyPlanOfConference)
                                newConference.journeyplan = [TBXML textForElement:journeyPlanOfConference];
                            
                            TBXMLElement* welcomeMessageElement = [TBXML childElementNamed:@"welcomemessage" parentElement:root];
                            if(welcomeMessageElement)
                                newConference.welcomemessage = [TBXML textForElement:welcomeMessageElement];
                            
                            TBXMLElement* welcomeVideoElement = [TBXML childElementNamed:@"welcomevideo" parentElement:root];
                            if(welcomeVideoElement)
                                newConference.welcomevideo = [TBXML textForElement:welcomeVideoElement];
                            
                            //Save changes
                            NSError *savingError2;
                            if(![self.addContext save:&savingError2])
                            {
                                NSLog(@"Error while saving conference properties");
                            }
                            else
                            {
                                //If there was no error while saving, proceed by creating a new store with pathname corresponding to the conference's name
                                NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                NSString *documentPath = [searchPaths objectAtIndex:0];
                                NSString* storeFileName = [NSString stringWithFormat:@"%@",newConference.name];
                                NSLog(@"Store mit URL %@ hinzugefügt",[documentPath stringByAppendingPathComponent:storeFileName]);
                                NSURL *storeURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:storeFileName]];
                                
                                //Save setting                                
                                NSError* saveToStoreError;
                                NSLog(@"PersistentStoreCoordinator %@",[self.addContext persistentStoreCoordinator]);
                                if(![[self.addContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&saveToStoreError])
                                {
                                    NSLog(@"Error: %@, %@", saveToStoreError, [saveToStoreError userInfo]);
                                    abort();
                                }
                                else
                                {
                                    NSLog(@"Store wurde hinzugefügt!");
                                    NSError *saveStoreError;
                                    if(![self.addContext save:&saveStoreError])
                                    {
                                        NSLog(@"Error while saving last store creation changes");
                                    }
                                }
                                
                            }
                                                        
                        
                            if(newConference.welcomevideo != nil || newConference.welcomemessage != nil)
                            {
                                //If a welcome video and/or message exists, load an instance of WelcomeVideoController and initiate it with the vide URL
                                
                                WelcomeViewController* newWelcomeScreen = [[WelcomeViewController alloc] init];
                                [newWelcomeScreen initWelcomeViewWithMessage:newConference.welcomemessage AndVideoUrl:newConference.welcomevideo];
                                
                                //Show the welcome view
                                [self.navigationController pushViewController:newWelcomeScreen animated:YES];
                                [newWelcomeScreen release];
                                
                            }
                            else
                            {
                                //If there is no welcome message or video, only present a message about successful import of conference
                                UIAlertView* finishedImporting = [[UIAlertView alloc] initWithTitle:successful_import_en message:message_successful_import_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                                [finishedImporting show];
                                [finishedImporting release];
                                [self.navigationController popToRootViewControllerAnimated:YES];
                            }
                        }
                        else
                        {
                            if(sameNameConference != nil)
                            {
                                //If there already exists a conference with same name, show message to the user
                                UIAlertView* conferenceAlreadyThere = [[UIAlertView alloc] initWithTitle:abort_import_en message:message_same_name_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                                [conferenceAlreadyThere show];
                                [conferenceAlreadyThere release];
                            }
                            else
                            {
                                //If not all necessary data could be found/loaded
                                UIAlertView* nichtAlleDaten = [[UIAlertView alloc] initWithTitle:abort_import_en message:message_import_couldnt_be_completely_loaded_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                                [nichtAlleDaten show];
                                [nichtAlleDaten release];
                            }
                        }
                    }
                    else
                    {
                        //If the root in xml structure was not found, file does not seems to be a XML file.
                        UIAlertView* wrongXMLStructure = [[UIAlertView alloc] initWithTitle:abort_import_en message:wrong_xml_file_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [wrongXMLStructure show];
                        [wrongXMLStructure release];
                    }
                }
                else
                {
                    //If no XML data was found, file does not seems to be reachable at this URL
                    UIAlertView* importingAborted = [[UIAlertView alloc] initWithTitle:abort_import_en message:[NSString stringWithFormat:file_couldnt_be_found_en, conferenceXMLPath] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    [importingAborted show];
                    [importingAborted release];
                }
                [xmlData release];
            });
        });
    }
    
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //When the user starts typing, show the URL keyboard type
    self.conferenceXMLUrlTextfield.keyboardType = UIKeyboardTypeURL;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //When the user exists the textfield don't show keyboard any longer
    [self.conferenceXMLUrlTextfield resignFirstResponder];
}
@end
