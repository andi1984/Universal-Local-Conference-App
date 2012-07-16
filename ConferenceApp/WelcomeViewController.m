//  WelcomeViewController.m
//  ConferenceApp

#import "WelcomeViewController.h"
#import <MediaPlayer/MediaPlayer.h>  

//Definition of all translation variables 

#define welcome_de @"Willkommen"
#define welcome_en @"Welcome"

#define next_de @"Weiter"
#define next_en @"Next"

@implementation WelcomeViewController
@synthesize welcome_message, welcome_video;
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
- (void) initWelcomeViewWithMessage:(NSString *)message AndVideoUrl:(NSString *)videourl
{
    //This is a initializer method to set values for the text message and/or URL of the video which should be displayed
    self.welcome_message = message;
    self.welcome_video = videourl;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [super loadView];
}

- (void)moviePlaybackComplete:(NSNotification *)notification
{
    //After the movie did finished
    NSLog(@"Movie did finish!");
    
    //Get the MPMoviePlayerController which has send this notification
    MPMoviePlayerController *moviePlayerController = [notification object];
    
    //And remove observer from the notification that video was finished
    [[NSNotificationCenter defaultCenter] removeObserver:self
													name:MPMoviePlayerPlaybackDidFinishNotification
												  object:moviePlayerController];
	
    //If there is a welcome message
    if(self.welcome_message != nil)
    {
        //Make the textframe bigger now, because video will be removed
        welcomeTextView.frame = CGRectMake(0.0, 50.0, self.view.frame.size.width, self.view.frame.size.height - 130.0);
        
        //And add a backButton to get back to the ConferenceTableViewController
        UIButton *backButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        [backButton setFrame:CGRectMake(self.view.frame.size.width/2 - 45.0, self.view.frame.size.height - 60.0, 90.0, 50.0)];
        [backButton setTitle:next_en forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(backToRoot) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:backButton];
        [backButton release];
    }
    else
    {
        //If there is no welcome text, simply show the backbutton now
        UIButton *backButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        [backButton setFrame:moviePlayerController.view.frame];
        [backButton setTitle:next_en forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(backToRoot) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:backButton];
        [backButton release];
    }
    
    //Remove the movie player from screen
    [moviePlayerController.view removeFromSuperview];
    [moviePlayerController release];
}

- (void)backToRoot
{
    //Simply get back to the ConferenceTableViewController instance
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //First initiate two boolean variables to check whether the video at the video URL has a valid, supported video format (currently supported: MOV or Youtube video) and whether it is a .mov video. 
    bool isValidVideoFormat = false;
    bool isMovFormat = false;
    
    if(self.welcome_video != nil && ![self.welcome_video isEqualToString:@""])
    {
        //If a video url is set, check whether it is a supported video format
        
        /*
         
         YOUTUBE LINK
         
         */
        
        //Search for 'youtube' in the URL
        NSRange youTubeRange = [self.welcome_video rangeOfString:@"youtube" options:NSCaseInsensitiveSearch];
        if(youTubeRange.location != NSNotFound)
        {
            //If 'youtube' is found in the url, it is a youtube video, hence a valid video format
            isValidVideoFormat = true;
            
            //Then we have to set the frame for the video
            if(self.welcome_message != nil)
                [self embedYouTube:self.welcome_video frame:CGRectMake(0.0, 50.0, self.view.frame.size.width, 200.0)];
            else
                [self embedYouTube:self.welcome_video frame:CGRectMake(0.0, self.view.frame.size.height/2 - 100, self.view.frame.size.width, 200.0)];            
        }
        
        
        
        /*
         
         .MOV URL
         
         */
        
        //Search for '.mov' in URL
        NSRange movRange = [self.welcome_video rangeOfString:@".mov" options:NSCaseInsensitiveSearch];
        if(movRange.location != NSNotFound)
        {
            //Welcome Video is a .mov file
            isValidVideoFormat = true;
            isMovFormat = true;
            
            //Then allocate and initiate a MPMOviePlayerController which can handle .mov files
            MPMoviePlayerController *moviePlayerController = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:self.welcome_video]];
            
            //When the vide is finished, run moviePlaybackComplete method
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(moviePlaybackComplete:)
                                                         name:MPMoviePlayerPlaybackDidFinishNotification
                                                       object:moviePlayerController];
            
            //Set the movie frames again
            if(self.welcome_message != nil)
                [moviePlayerController.view setFrame:CGRectMake(0.0, 50.0, self.view.frame.size.width, 200.0)];
            else
                [moviePlayerController.view setFrame:CGRectMake(0.0, self.view.frame.size.height/2 - 100, self.view.frame.size.width, 200.0)];
            
            //Add the movie player as a subview of current view
            [self.view addSubview:moviePlayerController.view];
            //moviePlayerController.fullscreen = YES;
            
            //moviePlayerController.scalingMode = MPMovieScalingModeFill;
            
            //Start the video
            [moviePlayerController play];
        }
        
        
    }
    
    //Now setup the UITextView for welcome message, if some text was provided
    if(self.welcome_message != nil)
    {
        //If text was provided, check whether a video is already set up.
        if(isValidVideoFormat)
        {
            //Videoscreen is already there, then set the frame properly
            welcomeTextView = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 260.0, self.view.frame.size.width, self.view.frame.size.height - 340.0)];
            
            //Set the UITextView to be not editable
            welcomeTextView.editable = FALSE;
            
            //Set the welcome message to the textview
            welcomeTextView.text = self.welcome_message; //Die Zeilenumbrüche werden noch rausgelesen werden
            
            //Add the view as a subview of current view
            [self.view addSubview:welcomeTextView];
            
            [welcomeTextView release];
            
        }
        else
        {
            //There is no video included, then textfield can be larger
            welcomeTextView = [[UITextView alloc] initWithFrame:CGRectMake(0.0, 50.0, self.view.frame.size.width, self.view.frame.size.height - 130.0)];
            
            //Set the UITextView to be not editable
            welcomeTextView.editable = FALSE;
            
            //Set the welcome message to the textview
            welcomeTextView.text = self.welcome_message; //Die Zeilenumbrüche werden noch rausgelesen werden
            
            //Add the view as a subview of current view
            [self.view addSubview:welcomeTextView];
            
            [welcomeTextView release];
        }
    }
    
    //Set a welcome label above the video and/or textview
    UILabel *welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 10.0, self.view.frame.size.width, 40.0)];
    welcomeLabel.textAlignment = UITextAlignmentCenter;
    welcomeLabel.text = welcome_en;
    welcomeLabel.font = [UIFont fontWithName:@"Arial" size:22.0];
    [self.view addSubview:welcomeLabel];
    [welcomeLabel release];
    
    if(!isMovFormat)
    {
        //If there is no video or the video is not a .mov video put a back button on screen. In case of a .mov video the back button is shown when the video is shown completely
        UIButton *backButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        [backButton setFrame:CGRectMake(self.view.frame.size.width/2 - 45.0, self.view.frame.size.height - 60.0, 90.0, 50.0)];
        [backButton setTitle:next_en forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(backToRoot) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:backButton];
        [backButton release];
    }
    
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}
- (void)embedYouTube:(NSString *)urlString frame:(CGRect)frame 
{
    //Setup youtube embed code...
    NSString *embedHTML = @"\
    <html><head>\
    <style type=\"text/css\">\
    body {\
    background-color: transparent;\
    color: white;\
    }\
    </style>\
    </head><body style=\"margin:0\">\
    <embed id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \
    width=\"%0.0f\" height=\"%0.0f\"></embed>\
    </body></html>";
    NSString *html = [NSString stringWithFormat:embedHTML, urlString, frame.size.width, frame.size.height];
    
    //To show it in a UIWebView
    UIWebView *videoView = [[UIWebView alloc] initWithFrame:frame];
    [videoView loadHTMLString:html baseURL:nil];
    
    //Add the UIWebView with the embedded video code as a subview of the current view
    [self.view addSubview:videoView];
    [videoView release];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
   
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
    NSLog(@"Dealloc is called!");
    [welcome_video release];
    [welcome_message release];
    [super dealloc];
}
@end
