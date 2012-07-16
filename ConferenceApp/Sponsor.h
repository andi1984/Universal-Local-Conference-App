//  Sponsor.h
//  ConferenceApp

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Sponsor : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * sponsorurl;
@property (nonatomic, retain) NSString * logourl;
+ (Sponsor *)initSponsorWithContext:(NSManagedObjectContext *)context andStore:(NSPersistentStore *)targetStore;
@end
