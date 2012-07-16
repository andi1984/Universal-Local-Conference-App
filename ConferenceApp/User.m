//  User.m
//  ConferenceApp


#import "User.h"
#import "Session.h"


@implementation User
@dynamic userid;
@dynamic cv;
@dynamic age;
@dynamic lastname;
@dynamic pictureurl;
@dynamic firstname;
@dynamic vcardurl;
@dynamic role;
@dynamic email;
@dynamic shortdescription;
@dynamic hasSessions;
@dynamic hasTags;
@dynamic homepageurl;

+ (User *)initUserWithContext:(NSManagedObjectContext *)context andStore:(NSPersistentStore *)targetStore
{
    //Einfacher Initializer der manuell befüllt werden muss.
    User *user = nil; 
    user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
    [context assignObject:user toPersistentStore:targetStore];
    NSError *error = nil;
    if (![context save:&error]) {
        
        NSLog(@"Fehler beim Speichern innerhalb von User.m");
        
    }
    return user;
}
- (void)addHasTagsObject:(Tag *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    NSLog(@"hasTags vorher %i",[self.hasTags count]);
    
    
    [self willChangeValueForKey:@"hasTags"
     
                withSetMutation:NSKeyValueUnionSetMutation
     
                   usingObjects:changedObjects];
    
    //[self.hasSpeakers setByAddingObjectsFromSet:changedObjects];
    [[self primitivehasTags] addObject:value];
    
    [self didChangeValueForKey:@"hasTags"
     
               withSetMutation:NSKeyValueUnionSetMutation
     
                  usingObjects:changedObjects];
    
    
    NSLog(@"hasTags nachher %i",[self.hasTags count]);
    [changedObjects release];
}
- (void)removeHasTagsObject:(Tag *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    
    
    [self willChangeValueForKey:@"hasTags"
     
                withSetMutation:NSKeyValueMinusSetMutation
     
                   usingObjects:changedObjects];
    
    [[self primitivehasTags] removeObject:value];
    
    [self didChangeValueForKey:@"hasTags"
     
               withSetMutation:NSKeyValueMinusSetMutation
     
                  usingObjects:changedObjects];
    
    
    [changedObjects release];
}
- (void)addHasTags:(NSSet *)values
{
    [self willChangeValueForKey:@"hasTags"
     
                withSetMutation:NSKeyValueUnionSetMutation
     
                   usingObjects:values];
    
    [[self primitivehasTags] unionSet:values];
    
    [self didChangeValueForKey:@"hasTags"
     
               withSetMutation:NSKeyValueUnionSetMutation
     
                  usingObjects:values];
}
- (void)removeHasTags:(NSSet *)values
{
    [self willChangeValueForKey:@"hasTags"
     
                withSetMutation:NSKeyValueMinusSetMutation
     
                   usingObjects:values];
    
    [[self primitivehasTags] minusSet:values];
    
    [self didChangeValueForKey:@"hasTags"
     
               withSetMutation:NSKeyValueMinusSetMutation
     
                  usingObjects:values];
}
@end
