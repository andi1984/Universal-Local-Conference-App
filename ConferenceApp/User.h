//  User.h
//  ConferenceApp

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session, Tag;

@interface User : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * userid;
@property (nonatomic, retain) NSString * cv;
@property (nonatomic, retain) NSNumber * age;
@property (nonatomic, retain) NSString * lastname;
@property (nonatomic, retain) NSString * pictureurl;
@property (nonatomic, retain) NSString * firstname;
@property (nonatomic, retain) NSString * vcardurl;
@property (nonatomic, retain) NSString * role;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * shortdescription;
@property (nonatomic, retain) NSString * homepageurl;
@property (nonatomic, retain) NSSet *hasSessions;
@property (nonatomic, retain) NSSet *hasTags;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addHasSessionsObject:(Session *)value;
- (void)removeHasSessionsObject:(Session *)value;
- (void)addHasSessions:(NSSet *)values;
- (void)removeHasSessions:(NSSet *)values;

- (NSMutableSet*)primitivehasTags;
- (void)addHasTagsObject:(Tag *)value;
- (void)removeHasTagsObject:(Tag *)value;
- (void)addHasTags:(NSSet *)values;
- (void)removeHasTags:(NSSet *)values;
+ (User *)initUserWithContext:(NSManagedObjectContext *)context andStore:(NSPersistentStore *)targetStore;
@end
