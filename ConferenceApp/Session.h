//  Session.h
//  ConferenceApp

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User, Venue, Tag;

@interface Session : NSManagedObject {
@private
}
@property (nonatomic, retain) NSDate * starttime;
@property (nonatomic, retain) NSString * sessionid;
@property (nonatomic, retain) NSNumber * isfaved;
@property (nonatomic, retain) NSString * roomname;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * abstract;
@property (nonatomic, retain) NSString * duration;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *hasSpeakers;
@property (nonatomic, retain) NSSet *hasTags;
@property (nonatomic, retain) Venue *invenue;
@property (nonatomic, assign) NSNumber *alreadyover;
@end

@interface Session (CoreDataGeneratedAccessors)

- (void)addHasSpeakersObject:(User *)value;
- (void)removeHasSpeakersObject:(User *)value;
- (void)addHasSpeakers:(NSSet *)values;
- (void)removeHasSpeakers:(NSSet *)values;
- (void)setPrimitivehasSpeakers:(NSMutableSet*)value;
- (NSMutableSet*)primitivehasSpeakers;

- (NSMutableSet*)primitivehasTags;
- (void)addHasTagsObject:(Tag *)value;
- (void)removeHasTagsObject:(Tag *)value;
- (void)addHasTags:(NSSet *)values;
- (void)removeHasTags:(NSSet *)values;

- (Venue *) primitiveinvenue;

- (void)setPrimitiveinvenue;
+ (Session *)initSessionInContext:(NSManagedObjectContext *)context andStore:(NSPersistentStore *)targetStore;
@end
