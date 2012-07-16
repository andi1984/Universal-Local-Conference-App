//  Sponsor.m
//  ConferenceApp

#import "Sponsor.h"


@implementation Sponsor
@dynamic name;
@dynamic sponsorurl;
@dynamic logourl;
+ (Sponsor *)initSponsorWithContext:(NSManagedObjectContext *)context andStore:(NSPersistentStore *)targetStore
{
    //Einfacher Initializer der manuell befüllt werden muss.
    Sponsor *newSponsor = nil; 
    newSponsor = [NSEntityDescription insertNewObjectForEntityForName:@"Sponsor" inManagedObjectContext:context];
    [context assignObject:newSponsor toPersistentStore:targetStore];
    NSError *error = nil;
    if (![context save:&error]) {
        
        NSLog(@"Fehler beim Speichern innerhalb von User.m");
        
    }
    return newSponsor;
}
@end
