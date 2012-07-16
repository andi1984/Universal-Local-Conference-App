//  SpeakerPickerViewController.m
//  ConferenceApp

#import "SessionPickerViewController.h"
#import "Session.h"
#import "User.h"

#define instructions_german @"Wähle Session aus:"
#define instructions_english @"Chose a session:"

#define abort_german @"Abbrechen"
#define abort_english @"Cancel"

@implementation SessionPickerViewController
@synthesize sessionPickerView, instructionLabel, sessionViewSourceArray, pickerViewContext, delegate, correspondingIDsArray, cancelButton, conferenceName, storeURL;

- (SessionPickerViewController *) initWithSpeakerID:(NSString *)initSpeakerID andContext:(NSManagedObjectContext *)initContext andConferenceName:(NSString *)targetedConferenceName
{
    //This is the session picker wheel view controller
    
    //First save attributes to the variables
    self.pickerViewContext = initContext;
    self.conferenceName = targetedConferenceName;

    //Add store to coordinator
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    NSString* storeFileName = [NSString stringWithFormat:@"%@",self.conferenceName];
    self.storeURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:storeFileName]];
    [[self.pickerViewContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:nil];
    
    //Check for speaker (user)
    NSFetchRequest* requestForSpeakerID = [[NSFetchRequest alloc] init];
    [requestForSpeakerID setAffectedStores:[NSArray arrayWithObject:[[self.pickerViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    requestForSpeakerID.entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.pickerViewContext];
    requestForSpeakerID.predicate = [NSPredicate predicateWithFormat:@"userid = %@", initSpeakerID];
    NSError *errorRequestSpeakerID = nil;
    
    User* speakerOfThisView = [[self.pickerViewContext executeFetchRequest:requestForSpeakerID error:&errorRequestSpeakerID] lastObject];
    [requestForSpeakerID release];
    NSMutableArray* sourceArray = [[NSMutableArray alloc] init];
    NSMutableArray* idArray = [[NSMutableArray alloc] init];
    
    if(!errorRequestSpeakerID)
    {
        //No Error occured
        if(speakerOfThisView != nil)
        {
            //Such a speaker exists
            for (Session *currentSession in speakerOfThisView.hasSessions)
            {
                //For each session the speaker holds, add session title to source array and sessionid to idArray
                [sourceArray addObject:[NSString stringWithFormat:@"%@",currentSession.title]];
                [idArray addObject:currentSession.sessionid];
            }
        }
        else
        {
            NSLog(@"Speaker with such an ID does not exists!");
        }
    }
    else
    {
        //Error occured
        NSLog(@"Error occured while fetching Speaker for PickerView");
    }
    
    //Save results in official arrays
    self.sessionViewSourceArray = sourceArray;
    self.correspondingIDsArray = idArray;
    [sourceArray release];
    [idArray release];

    return self;
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
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.sessionViewSourceArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.sessionViewSourceArray objectAtIndex:row];
}
- (IBAction)abort:(UIButton *)sender
{
    //Send a message to picker view's delegate that the user aborted view
    [self.delegate abortByPickerViewController:(SessionPickerViewController *)self];
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    //Send a message to picker view's delegate that the user has choosen session with id [self.correspondingIDsArray objectAtIndex:row]
    [self.delegate sessionPickerViewController:(SessionPickerViewController *)pickerView didChoosesessionWithID:[self.correspondingIDsArray objectAtIndex:row]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    //Set instruction label
    self.instructionLabel.text = instructions_english;
    
    //Add cancel button
    self.cancelButton.titleLabel.numberOfLines = 1;
    self.cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.cancelButton.titleLabel.lineBreakMode = UILineBreakModeClip;
    [self.cancelButton setTitle:abort_english forState:UIControlStateNormal];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. myOutlet = nil;
    self.sessionPickerView = nil;
    self.instructionLabel = nil;
    self.cancelButton = nil;
}

- (void)dealloc {
    [sessionPickerView release];
    [instructionLabel release];
    [sessionViewSourceArray release];
    [correspondingIDsArray release];
    [pickerViewContext release];
    [cancelButton release];
    [conferenceName release];
    [storeURL release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
