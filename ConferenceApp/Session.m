//  Session.m
//  ConferenceApp

#import "Session.h"
#import "User.h"
#import "Venue.h"


@implementation Session
@dynamic starttime;
@dynamic sessionid;
@dynamic isfaved;
@dynamic roomname;
@dynamic date;
@dynamic abstract;
@dynamic duration;
@dynamic title;
@dynamic hasSpeakers;
@dynamic invenue;
@dynamic hasTags;
@dynamic alreadyover;
- (void)addHasSpeakersObject:(User *)value
{
    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    NSLog(@"hasSpeakers vorher %i",[self.hasSpeakers count]);
    
    
    [self willChangeValueForKey:@"hasSpeakers"
     
                withSetMutation:NSKeyValueUnionSetMutation
     
                   usingObjects:changedObjects];
    
    //[self.hasSpeakers setByAddingObjectsFromSet:changedObjects];
    [[self primitivehasSpeakers] addObject:value];
    
    [self didChangeValueForKey:@"hasSpeakers"
     
               withSetMutation:NSKeyValueUnionSetMutation
     
                  usingObjects:changedObjects];
    
    
    NSLog(@"hasSpeakers nachher %i",[self.hasSpeakers count]);
    [changedObjects release];
    
}



- (void)removeHasSpeakersObject:(User *)value

{
    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    
    
    [self willChangeValueForKey:@"hasSpeakers"
     
                withSetMutation:NSKeyValueMinusSetMutation
     
                   usingObjects:changedObjects];
    
    [[self primitivehasSpeakers] removeObject:value];
    
    [self didChangeValueForKey:@"hasSpeakers"
     
               withSetMutation:NSKeyValueMinusSetMutation
     
                  usingObjects:changedObjects];
    
    
    [changedObjects release];
    
}



- (void)addHasSpeakers:(NSSet *)value

{
    
    [self willChangeValueForKey:@"hasSpeakers"
     
                withSetMutation:NSKeyValueUnionSetMutation
     
                   usingObjects:value];
    
    [[self primitivehasSpeakers] unionSet:value];
    
    [self didChangeValueForKey:@"hasSpeakers"
     
               withSetMutation:NSKeyValueUnionSetMutation
     
                  usingObjects:value];
    
}



- (void)removeHasSpeakers:(NSSet *)value

{
    
    [self willChangeValueForKey:@"hasSpeakers"
     
                withSetMutation:NSKeyValueMinusSetMutation
     
                   usingObjects:value];
    
    [[self primitivehasSpeakers] minusSet:value];
    
    [self didChangeValueForKey:@"hasSpeakers"
     
               withSetMutation:NSKeyValueMinusSetMutation
     
                  usingObjects:value];
    
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

+ (Session *)initSessionInContext:(NSManagedObjectContext *)context andStore:(NSPersistentStore *)targetStore
{
    //Einfacher Initializer der manuell befüllt werden muss.
    Session *session = nil; 
    session = [NSEntityDescription insertNewObjectForEntityForName:@"Session" inManagedObjectContext:context];
    [context assignObject:session toPersistentStore:targetStore];
    NSError *error = nil;
    if (![context save:&error]) {
        
        NSLog(@"Fehler beim Speichern innerhalb von Session");
        
    }
    
    return session;
}
@end
