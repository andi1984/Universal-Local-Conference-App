//  Venue.h
//  ConferenceApp

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session;

@interface Venue : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * websiteurl;
@property (nonatomic, retain) NSDecimalNumber * latitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDecimalNumber * longitude;
@property (nonatomic, retain) NSSet *sessionshere;
@property (nonatomic, retain) NSString * floorplan;
@property (nonatomic, retain) NSString * infotext;
@end

@interface Venue (CoreDataGeneratedAccessors)

- (void)addSessionshereObject:(Session *)value;
- (void)removeSessionshereObject:(Session *)value;
- (void)addSessionshere:(NSSet *)values;
- (void)removeSessionshere:(NSSet *)values;
+ (Venue *)initVenueWithContext:(NSManagedObjectContext *)context andStore:(NSPersistentStore *)targetStore;
@end
