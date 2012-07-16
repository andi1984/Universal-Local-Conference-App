//  SpeakerViewController.m
//  ConferenceApp

#import "SpeakerViewController.h"
#import "User.h"
#import "Session.h"
#import "Tag.h"
#import "SessionPickerViewController.h"
#import "SessionViewController.h"
#import "SHK.h"
#import "Conference.h"

#define age_deutsch @"Alter: "
#define age_english @"age: "

#define speaker_not_available_header_de @"Referent nicht gefunden"
#define speaker_not_available_header_en @"Speaker not found"

#define speaker_not_available_de @"Dieser Referent befindet sich nicht mehr in unserer Datenbank. Begeben Sie sich zurück zur letzten Übersicht."
#define speaker_not_available_en @"This speaker is no longer in our database. Please go back to the overview."

@implementation SpeakerViewController
@synthesize age, cvURL, pictureURL, speakerID, role, speakerFirstName, speakerLastName, shortDescription, vcardURL, homepageURL, speakerContext, hasSessionsSet, hasTagsSet;
@synthesize shortDescriptionLabel, invitedView, speakerImageView, speakerNameLabel, speakerAgeLabel, speakerTagsLabel, vcardButton, cvButton, homepageButton, tagButton, sessionsLabel, moreAboutSessionsButton, conferenceName, storeURL;
- (IBAction) shareSpeaker:(UIButton *)sender
{
    //This method gets called when the user wants to mention a speaker in a tweet, facebook post or any other social media activity. 
    
    //First get conference details.
    NSFetchRequest* getAllNeededData = [[NSFetchRequest alloc] init];
    getAllNeededData.entity = [NSEntityDescription entityForName:@"Conference" inManagedObjectContext:self.speakerContext];
    getAllNeededData.predicate = [NSPredicate predicateWithFormat:@"name = %@",self.conferenceName];
    
    NSError *fetchingAllDataError = nil;
    
    //Save them
    Conference* ourConference = [[[self.speakerContext executeFetchRequest:getAllNeededData error:&fetchingAllDataError] lastObject] retain];
    if(!fetchingAllDataError && ourConference != nil)
    {
        //If no error occured and conference exists
        if(ourConference.acronym != nil && ![ourConference.acronym isEqualToString:@""])
        {
            //If acronym is exists and is not empty.
            if(speakerLastName != nil && speakerFirstName != nil)
            {
                SHKItem *item = [SHKItem text:[NSString stringWithFormat:@"%@ %@ #%@",speakerFirstName,speakerLastName,ourConference.acronym]];
                SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];         
                // Display the action sheet
                [actionSheet showInView:self.view];
            }
            else
            {
                SHKItem *item = [SHKItem text:[NSString stringWithFormat:@"#%@",ourConference.acronym]];
                SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];  
                // Display the action sheet
                [actionSheet showInView:self.view];
            }          
        }
        else
        {
            if(speakerFirstName != nil && speakerLastName != nil)
            {
                // Create the item to share (in this example, a url)
                SHKItem *item = [SHKItem text:[NSString stringWithFormat:@"%@ %@",speakerFirstName,speakerLastName]];
                
                // Get the ShareKit action sheet
                SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
                
                // Display the action sheet
                [actionSheet showInView:self.view];
            }
            else
            {
                // Create the item to share (in this example, a url)
                SHKItem *item = [SHKItem text:@""];
                
                // Get the ShareKit action sheet
                SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
                
                // Display the action sheet
                [actionSheet showInView:self.view];
            }
            
        }
    }
    else
    {
        if(speakerFirstName != nil && speakerLastName != nil)
        {
            // Create the item to share (in this example, a url)
            SHKItem *item = [SHKItem text:[NSString stringWithFormat:@"%@ %@",speakerFirstName,speakerLastName]];
            
            // Get the ShareKit action sheet
            SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
            
            // Display the action sheet
            [actionSheet showInView:self.view];
        }
        else
        {
            // Create the item to share (in this example, a url)
            SHKItem *item = [SHKItem text:@""];
            
            // Get the ShareKit action sheet
            SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
            
            // Display the action sheet
            [actionSheet showInView:self.view];
        }
    }
    [ourConference release];
    [getAllNeededData release];
}
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
    
    // Release any cached data, imself.ages, etc that aren't in use.
}

- (void) sessionPickerViewController:(SessionPickerViewController *)sender didChoosesessionWithID:(NSString *)chosensessionID
{
    //This method gets called when the user has choosen a session in the picker view. Then remove picker view from screen
    [self dismissModalViewControllerAnimated:NO];
    
    //And allocate and initiate a detailed session view and show it on screen
    SessionViewController* chosenSessionViewController = [[SessionViewController alloc] initWithSessionID:chosensessionID andManagedObjectContext:self.speakerContext andConference:self.conferenceName];
    [self.navigationController pushViewController:chosenSessionViewController animated:NO];
    [chosenSessionViewController release];
}

- (void) abortByPickerViewController:(SessionPickerViewController *)sender
{
    //When the user aborts picker view, remove it from screen.
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction) moreInformationAboutSessions:(UIButton *)sender
{
    //This method is called when the user clicks on the button on the left side of the session label where all sessions are mentioned which are hold by this speaker.
    
    //Show a picker view with all sessions in it
    SessionPickerViewController *newPickerView = [[SessionPickerViewController alloc] initWithSpeakerID:self.speakerID andContext:self.speakerContext andConferenceName:self.conferenceName];
    newPickerView.delegate = self;
    newPickerView.view.bounds = self.view.bounds;
    
    //Show it on screen.
    [self presentModalViewController:newPickerView animated:YES];
    [newPickerView release];
}

#pragma mark - View lifecycle
- (SpeakerViewController *) initWithSpeakerID:(NSString*)inputID andManagedObjectContext:(NSManagedObjectContext*)inputContext andConference:(NSString *)targetedConferenceName
{
    //This method creates an instance of this class with all variables set to the corresponding speaker properties which should be displayed in this view.

    //First set the general properties
    self.speakerID = inputID;
    self.speakerContext = inputContext;
    self.conferenceName = targetedConferenceName;
    
    //Add store to store coordinator
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    NSString* storeFileName = [NSString stringWithFormat:@"%@",self.conferenceName];
    self.storeURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:storeFileName]];
    [[self.speakerContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:nil];
    
    //Check whether speaker with the self.speakerID exists.
    NSFetchRequest *speakerWithIDRequest = [[NSFetchRequest alloc] init];
    [speakerWithIDRequest setAffectedStores:[NSArray arrayWithObject:[[self.speakerContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    speakerWithIDRequest.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.speakerContext];
    speakerWithIDRequest.predicate = [NSPredicate predicateWithFormat:@"userid = %@",self.speakerID];
    NSError* idComparisonError = nil;
    
    User* speakerForView = [[self.speakerContext executeFetchRequest:speakerWithIDRequest error:&idComparisonError] lastObject];
    [speakerWithIDRequest release];
    
    if(!idComparisonError)
    {
        if(speakerForView != nil)
        {
            //If speaker exists, set all properties to the variables
            
            self.age = speakerForView.age;
            self.cvURL = speakerForView.cv;
            self.pictureURL = speakerForView.pictureurl;
            self.speakerFirstName = speakerForView.firstname;
            self.speakerLastName = speakerForView.lastname;
            self.shortDescription = speakerForView.shortdescription;
            self.vcardURL = speakerForView.vcardurl;
            self.hasSessionsSet = speakerForView.hasSessions;
            self.hasTagsSet = speakerForView.hasTags;
            self.homepageURL = speakerForView.homepageurl;
            self.role = speakerForView.role;
        }
        else
        {
            //Else display a message
            UIAlertView *speakerWithThisIDDoesNotExists = [[UIAlertView alloc] initWithTitle:speaker_not_available_header_en message:speaker_not_available_en delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [speakerWithThisIDDoesNotExists show];
            [speakerWithThisIDDoesNotExists release];
        }
    }
    else
        NSLog(@"Error while fetching data.");
    return self;
}

- (void) showVCard
{
    //This method opens safari and the VCard URL after user clicked on the corresponding button
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.vcardURL]];
}

- (void) showCV
{
    //This method opens safari and the CV URL after user clicked on the corresponding button    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.cvURL]];
}

- (void)handleSwiping
{
    //If the user swipes to the left, remove view
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)homepageButtonWasTapped:(UIButton *)sender
{
    //If homepage button was clicked, open homepage in safari
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: self.homepageURL]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSAutoreleasePool* loadingViewPool = [[NSAutoreleasePool alloc] init];
    
    //Add a swipe gesture recognizer to detect swipes to the left
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(handleSwiping)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeRecognizer];
    [swipeRecognizer release];
    
    //First hide and disable all buttons which should not be displayed yet.
    self.vcardButton.alpha = 0.0;
    self.vcardButton.enabled = NO;
    
    self.cvButton.alpha = 0.0;
    self.cvButton.enabled = NO;

    self.tagButton.alpha = 0.0;
    self.tagButton.enabled = NO;
    
    self.homepageButton.alpha = 0.0;
    self.homepageButton.enabled = NO;
    
    self.sessionsLabel.alpha = 0.0;
    self.sessionsLabel.text = @"";
    
    self.invitedView.alpha = 0.0;
    
       
    //If speaker has specified a picture
    if(self.pictureURL)
    {
        //Load picture in another thread
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL* imageURL = [NSURL URLWithString:self.pictureURL];
            NSError* getImageDataFromURLError = nil;
            NSData* imageData = [NSData dataWithContentsOfURL:imageURL options:NSDataReadingUncached error:&getImageDataFromURLError];
            dispatch_async( dispatch_get_main_queue(), ^{
                if(!getImageDataFromURLError || imageData != nil)
                {
                    //If no error occured while downloading picture data, create a new image with this data and set it as the image of our speakerImageView on screen
                    UIImage* speakerImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                    [self.speakerImageView setImage:speakerImage];
                    
                    //If speaker is invited speaker, add a yellow star on the right bottom of the image
                    if([self.role isEqualToString:@"invited_speaker"])
                        self.invitedView.alpha = 1.0;
                }
                else
                {
                    //If there was an error while downloading data, load standard picture
                    if([self.role isEqualToString:@"invited_speaker"])
                        [self.speakerImageView setImage:[UIImage imageNamed:@"invited_big.png"]];
                    else
                        [self.speakerImageView setImage:[UIImage imageNamed:@"profile_missing_big.png"]];
                }
            });
        });
    }
    else
    {
        //If no picture is specified, load standard picture
        if([self.role isEqualToString:@"invited_speaker"])
            [self.speakerImageView setImage:[UIImage imageNamed:@"invited_big.png"]];
        else
            [self.speakerImageView setImage:[UIImage imageNamed:@"profile_missing_big.png"]];
    }
   
    
    //Set name label
    BOOL firstNameSet = false;
    if(self.speakerFirstName)
    {
        self.speakerNameLabel.text = self.speakerFirstName;
        firstNameSet = true;
    }
        
    if(self.speakerLastName && firstNameSet)
        self.speakerNameLabel.text = [self.speakerNameLabel.text stringByAppendingFormat:@" %@",self.speakerLastName];
    
    if(self.speakerLastName && !firstNameSet)
        self.speakerNameLabel.text = self.speakerLastName;
    
    if(!self.speakerLastName && !firstNameSet)
        self.speakerNameLabel.text = @"";
    
    
    //Set description text
    if(self.shortDescription)
        self.shortDescriptionLabel.text = self.shortDescription;
    else
        self.shortDescriptionLabel.text = @"";
    
    //Set tag label
    if([self.hasTagsSet count])
    {
        //If speaker has specified tags
        self.tagButton.alpha = 1.0;
        self.tagButton.enabled = YES; //Show buttons for later intactions (in later versions of this app) to show results corresponding to a specific tag (planned feature in future release)
        
        int loopVariable = 1;
        for (Tag* currentTag in self.hasTagsSet) {
            if(loopVariable == 1)
            {
                self.speakerTagsLabel.text = currentTag.name;
                loopVariable = loopVariable + 1;
            }
            else
            {
                self.speakerTagsLabel.text = [self.speakerTagsLabel.text stringByAppendingFormat:@", %@",currentTag.name];
            }
        }
    }
        
    //Display age in label
    if(self.age && ![self.age isEqualToNumber:[NSNumber numberWithInt:0]])
    {
        self.speakerAgeLabel.text = [NSString stringWithFormat:@"%@ %i",age_english, [self.age intValue]];
    }
    
    
    //If vcard is specified, display button
    //Unfortunately not allowed to download vcard from web, hence commented this section out
    /*
    if(![self.vcardURL isEqualToString:@""])
    {
        //If vcard exists.
        NSData* vcardData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:self.vcardURL]];
        if(vcardData != nil)
        {
            //vcardData wurde geladen
            self.vcardButton.alpha = 1.0;
            self.vcardButton.enabled = YES;
            [self.vcardButton addTarget:self action:@selector(showVCard) forControlEvents:UIControlEventTouchUpInside];
            
        }
        [vcardData release];
    }*/
    
    
    //If cvURL is specified, add button
    if(self.cvURL != nil && ![self.cvURL isEqualToString:@""])
    {
        self.cvButton.alpha = 1.0;
        self.cvButton.enabled = YES;
        [self.cvButton addTarget:self action:@selector(showCV) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //If homepage is specified, add button
    if(self.homepageURL != nil && ![self.homepageURL isEqualToString:@""])
    {
        //Homepageurl existiert
        self.homepageButton.alpha = 1.0;
        self.homepageButton.enabled = YES;
        [self.homepageButton setTitle:self.homepageURL forState:UIControlStateNormal];
    }
    
    
    //Finally find sessions hold by this speaker
    NSLog(@"Number of Sessions hold by this speaker: %i",[self.hasSessionsSet count]);
    if ([self.hasSessionsSet count] > 0)
    {
        //If the speaker holds at least one session, add button and display sessions in sessionsLabel
        
        self.sessionsLabel.alpha = 1.0;
        NSString* sessionOutputForLabel = @"";
        for (Session *currentSession in self.hasSessionsSet) {
            sessionOutputForLabel = [sessionOutputForLabel stringByAppendingFormat:@"%@ \n",currentSession.title];
        }
        self.sessionsLabel.text = sessionOutputForLabel;
    }
    
    [loadingViewPool drain];
}

- (void)dealloc {
    [age release];
    [cvURL release];
    [pictureURL release];
    [speakerID release];
    [speakerFirstName release];
    [speakerLastName release];
    [shortDescription release];
    [vcardURL release];
    [speakerContext release];
    [hasSessionsSet release];
    [hasTagsSet release];
    [homepageURL release];
    [role release];
    
    [speakerImageView release];
    [speakerNameLabel release];
    [shortDescriptionLabel release];
    [invitedView release];
    [speakerAgeLabel release];
    [speakerTagsLabel release];
    [vcardButton release];
    [cvButton release];
    [homepageButton release];
    [tagButton release];
    [sessionsLabel release];
    [moreAboutSessionsButton release];
    [conferenceName release];
    [storeURL release];
    [super dealloc];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. myOutlet = nil;
    self.speakerImageView = nil;
    self.speakerNameLabel = nil;
    self.speakerTagsLabel = nil;
    self.shortDescriptionLabel = nil;
    self.invitedView = nil;
    self.speakerAgeLabel = nil;
    self.vcardButton = nil;
    self.cvButton = nil;
    self.tagButton = nil;
    self.homepageButton = nil;
    self.sessionsLabel = nil;
    self.moreAboutSessionsButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
