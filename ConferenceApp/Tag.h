//  Tag.h
//  ConferenceApp


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session, User;

@interface Tag : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *usedByUsers;
@property (nonatomic, retain) NSSet *usedBySessions;
@end

@interface Tag (CoreDataGeneratedAccessors)
+ (Tag *)initTagWithContext:(NSManagedObjectContext *)context andStore:(NSPersistentStore *)targetStore;
- (NSMutableSet*)primitiveusedByUsers;
- (void)addUsedByUsersObject:(User *)value;
- (void)removeUsedByUsersObject:(User *)value;
- (void)addUsedByUsers:(NSSet *)values;
- (void)removeUsedByUsers:(NSSet *)values;

- (NSMutableSet*)primitiveusedBySessions;
- (void)addUsedBySessionsObject:(Session *)value;
- (void)removeUsedBySessionsObject:(Session *)value;
- (void)addUsedBySessions:(NSSet *)values;
- (void)removeUsedBySessions:(NSSet *)values;
@end
