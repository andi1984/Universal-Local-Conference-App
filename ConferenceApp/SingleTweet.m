//  SingleTweet.m
//  simpleTwitter

#import "SingleTweet.h"
#import "SHK.h"
#import "SHKTwitter.h"

@implementation SingleTweet
@synthesize avatarView, twitterURILabel, twitterNameLabel, tweetView, myAvatarData, myTwitterName, myTwitterURI, myTweet, abortButton, delegate, replyButton, retweetButton;

- (SingleTweet *) initWithAvatarData:(NSData *) avatarData andTwitterName:(NSString *)twitterName andTwitterURI:(NSString *)twitterURI andTweetText:(NSString *)tweet
{
    //This is the initializer method. Simply set all values.
    self.myAvatarData = avatarData;
    self.myTwitterName = twitterName;
    self.myTwitterURI = twitterURI;
    self.myTweet = tweet;
    return self;
}

- (IBAction)pressedAbort:(UIButton *)sender
{
    //If the user wants to get back, instance of this class sends a message to his delegate
    [self.delegate abortByTweetShow:self];
}

- (IBAction)reply:(UIButton *)sender
{
    //If the user wants to reply to a tweet, show a twitter reply message
    
    NSAutoreleasePool *drainPool = [[NSAutoreleasePool alloc] init];
    // Create the item to share (in this example, a url)
    SHKItem *item = [SHKItem text:[NSString stringWithFormat:@"\u0040%@",self.myTwitterName]];
    // Share the item
    [SHKTwitter shareItem:item];
    [drainPool drain];
}
- (IBAction)retweet:(UIButton *)sender
{
    //If the user wants to retweet a tweet, show a retweet message
    
    NSAutoreleasePool *drainPool = [[NSAutoreleasePool alloc] init];
    // Create the item to share (in this example, a url)
    SHKItem *item = [SHKItem text:[NSString stringWithFormat:@"RT \u0040%@: %@",self.myTwitterName,myTweet]];
    // Share the item
    [SHKTwitter shareItem:item];
    [drainPool drain];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{   
    NSLog(@"Dealloc of SingleTweet");
    [avatarView release];
    [twitterURILabel release];
    [twitterNameLabel release];
    [tweetView release];
    [myAvatarData release];
    [myTwitterName release];
    [myTwitterURI release];
    [myTweet release];
    [abortButton release];
    [replyButton release];
    [retweetButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //After view did load, show picture of twitter user (if a picture can be found)
    if(![self.myAvatarData isEqual:@""])
    {
        UIImage* avatarImage = [[UIImage alloc] initWithData:self.myAvatarData];
        [self.avatarView setImage:avatarImage];
        [avatarImage release];
    }
    
    //Set twittername
    self.twitterNameLabel.text = self.myTwitterName;
    
    //and URI
    self.twitterURILabel.text = self.myTwitterURI;
    
    //and Tweettext
    self.tweetView.text = self.myTweet;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. myOutlet = nil;
    self.avatarView = nil;
    self.twitterNameLabel = nil;
    self.twitterURILabel = nil;
    self.tweetView = nil;
    self.abortButton = nil;
    self.replyButton = nil;
    self.retweetButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
