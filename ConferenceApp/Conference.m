//  Conference.m
//  ConferenceApp

#import "Conference.h"


@implementation Conference
@dynamic recommendedhotels;
@dynamic conferencelogourl;
@dynamic startdate;
@dynamic journeyplan;
@dynamic slogan;
@dynamic contact;
@dynamic imprint;
@dynamic newsfeedurl;
@dynamic conditions;
@dynamic topic;
@dynamic targetedaudience;
@dynamic acronym;
@dynamic registrationurl;
@dynamic duration;
@dynamic timezone;
@dynamic name;
@dynamic homepageurl;
@dynamic conferencexmlurl;
@dynamic sponsorxmlurl;
@dynamic venuexmlurl;
@dynamic sessionxmlurl;
@dynamic userxmlurl;
@dynamic welcomemessage;
@dynamic welcomevideo;
+ (Conference *)initConferenceWithContext:(NSManagedObjectContext *)context
{
    //Einfacher Initializer der manuell befüllt werden muss.
    Conference *newConference = nil; 
    newConference = [NSEntityDescription insertNewObjectForEntityForName:@"Conference" inManagedObjectContext:context];
    NSError *error = nil;
    if (![context save:&error]) {
        
        NSLog(@"Fehler beim Speichern innerhalb von User.m");
        
    }
    return newConference;
}
@end
