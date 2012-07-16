//  self.speakerPickerViewController.m
//  ConferenceApp

#import "SpeakerPickerViewController.h"
#import "Session.h"
#import "User.h"

#define instructions_german @"Wähle Referent/in aus:"
#define instructions_english @"Chose a speaker:"

#define abort_german @"Abbrechen"
#define abort_english @"Cancel"

@implementation SpeakerPickerViewController
@synthesize speakerPickerView, instructionLabel, speakerViewSourceArray, pickerViewContext, delegate, correspondingIDsArray, cancelButton, conferenceName, storeURL;

- (SpeakerPickerViewController *) initWithSessionID:(NSString *)initSessionID andContext:(NSManagedObjectContext *)initContext andConferenceName:(NSString *)targetedConference
{
    //This is the initializer method for the picker view controller. First save all attributes in variables
    self.pickerViewContext = initContext;
    self.conferenceName = targetedConference;
    
    //Add store to store coordinator
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    NSString* storeFileName = [NSString stringWithFormat:@"%@",self.conferenceName];
    self.storeURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:storeFileName]];
    [[self.pickerViewContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:nil error:nil];
    
    //Search for corresponding session
    NSFetchRequest* requestForSessionID = [[NSFetchRequest alloc] init];
    [requestForSessionID setAffectedStores:[NSArray arrayWithObject:[[self.pickerViewContext persistentStoreCoordinator] persistentStoreForURL:self.storeURL]]];
    requestForSessionID.entity = [NSEntityDescription entityForName:@"Session" inManagedObjectContext:self.pickerViewContext];
    requestForSessionID.predicate = [NSPredicate predicateWithFormat:@"sessionid = %@", initSessionID];
    NSError *errorRequestSessionID = nil;
    
    Session* sessionOfThisView = [[self.pickerViewContext executeFetchRequest:requestForSessionID error:&errorRequestSessionID] lastObject];
    [requestForSessionID release];
    
    //Alloc and init 2 mutable arrays
    NSMutableArray* sourceArray = [[NSMutableArray alloc] init];
    NSMutableArray* idArray = [[NSMutableArray alloc] init];

    if(!errorRequestSessionID)
    {
        //No Error occured
        if(sessionOfThisView != nil)
        {
            //Such a session exists
            for (User *currentSpeaker in sessionOfThisView.hasSpeakers)
            {
                //For each speaker of the session, save user profile in source array (source for the picker wheel)
                [sourceArray addObject:[NSString stringWithFormat:@"%@ %@",currentSpeaker.firstname,currentSpeaker.lastname]];
                
                //Save userid in idArray
                [idArray addObject:currentSpeaker.userid];
            }
        }
        else
        {
            NSLog(@"Session with such an ID does not exists!");
        }
    }
    else
    {
        //Error occured
        NSLog(@"Error occured while fetching session for PickerView");
    }
    
    //Then save results in the official arrays
    self.speakerViewSourceArray = sourceArray;
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
    return [self.speakerViewSourceArray count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.speakerViewSourceArray objectAtIndex:row];
}
- (IBAction)abort:(UIButton *)sender
{
    [self.delegate abortByPickerViewController:self];
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self.delegate speakerPickerViewController:self didChooseSpeakerWithID:[self.correspondingIDsArray objectAtIndex:row]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //Set instruction label
    self.instructionLabel.text = instructions_english;
    
    //Set cancel button
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
    self.speakerPickerView = nil;
    self.instructionLabel = nil;
    self.cancelButton = nil;
}

- (void)dealloc {
    [speakerPickerView release];
    [instructionLabel release];
    [speakerViewSourceArray release];
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
