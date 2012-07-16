//  Venue.m
//  ConferenceApp

#import "Venue.h"
#import "Session.h"


@implementation Venue
@dynamic websiteurl;
@dynamic latitude;
@dynamic name;
@dynamic longitude;
@dynamic sessionshere;
@dynamic floorplan;
@dynamic infotext;
+ (Venue *)initVenueWithContext:(NSManagedObjectContext *)context andStore:(NSPersistentStore *)targetStore
{
    //Einfacher Initializer der manuell befüllt werden muss.
    Venue *venue = nil; 
    venue = [NSEntityDescription insertNewObjectForEntityForName:@"Venue" inManagedObjectContext:context];
    [context assignObject:venue toPersistentStore:targetStore];
    NSError *error = nil;
    if (![context save:&error]) {
        
        NSLog(@"Fehler beim Speichern innerhalb von Venue");
        
    }
    return venue;
}
@end
