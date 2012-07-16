//  Tag.m
//  ConferenceApp

#import "Tag.h"
#import "Session.h"
#import "User.h"


@implementation Tag
@dynamic name;
@dynamic usedByUsers;
@dynamic usedBySessions;
+ (Tag *)initTagWithContext:(NSManagedObjectContext *)context andStore:(NSPersistentStore *)targetStore
{
    //Einfacher Initializer der manuell befüllt werden muss.
    Tag *newTag = nil; 
    newTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:context];
    [context assignObject:newTag toPersistentStore:targetStore];
    NSError *error = nil;
    if (![context save:&error]) {
        
        NSLog(@"Fehler beim Speichern innerhalb von Tag.m");
        
    }
    return newTag;
}

- (void)addUsedByUsersObject:(User *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    NSLog(@"hasUsers vorher %i",[self.usedByUsers count]);
    
    
    [self willChangeValueForKey:@"usedByUsers"
     
                withSetMutation:NSKeyValueUnionSetMutation
     
                   usingObjects:changedObjects];
    
    //[self.hasSpeakers setByAddingObjectsFromSet:changedObjects];
    [[self primitiveusedByUsers] addObject:value];
    
    [self didChangeValueForKey:@"usedByUsers"
     
               withSetMutation:NSKeyValueUnionSetMutation
     
                  usingObjects:changedObjects];
    
    
    NSLog(@"hasUsers nachher %i",[self.usedByUsers count]);
    [changedObjects release];
}
- (void)removeUsedByUsersObject:(User *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    
    
    [self willChangeValueForKey:@"usedByUsers"
     
                withSetMutation:NSKeyValueMinusSetMutation
     
                   usingObjects:changedObjects];
    
    [[self primitiveusedByUsers] removeObject:value];
    
    [self didChangeValueForKey:@"usedByUsers"
     
               withSetMutation:NSKeyValueMinusSetMutation
     
                  usingObjects:changedObjects];
    
    
    [changedObjects release];
}
- (void)addUsedByUsers:(NSSet *)values
{
    [self willChangeValueForKey:@"usedByUsers"
     
                withSetMutation:NSKeyValueUnionSetMutation
     
                   usingObjects:values];
    
    [[self primitiveusedByUsers] unionSet:values];
    
    [self didChangeValueForKey:@"usedByUsers"
     
               withSetMutation:NSKeyValueUnionSetMutation
     
                  usingObjects:values];
}
- (void)removeUsedByUsers:(NSSet *)values
{
    [self willChangeValueForKey:@"usedByUsers"
     
                withSetMutation:NSKeyValueMinusSetMutation
     
                   usingObjects:values];
    
    [[self primitiveusedByUsers] minusSet:values];
    
    [self didChangeValueForKey:@"usedByUsers"
     
               withSetMutation:NSKeyValueMinusSetMutation
     
                  usingObjects:values];
}

- (void)addUsedBySessionsObject:(Session *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    NSLog(@"hasSessions vorher %i",[self.usedBySessions count]);
    
    
    [self willChangeValueForKey:@"usedBySessions"
     
                withSetMutation:NSKeyValueUnionSetMutation
     
                   usingObjects:changedObjects];
    
    //[self.hasSpeakers setByAddingObjectsFromSet:changedObjects];
    [[self primitiveusedBySessions] addObject:value];
    
    [self didChangeValueForKey:@"usedBySessions"
     
               withSetMutation:NSKeyValueUnionSetMutation
     
                  usingObjects:changedObjects];
    
    
    NSLog(@"hasSessions nachher %i",[self.usedBySessions count]);
    [changedObjects release];
}

- (void)removeUsedBySessionsObject:(Session *)value
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    
    
    [self willChangeValueForKey:@"usedBySessions"
     
                withSetMutation:NSKeyValueMinusSetMutation
     
                   usingObjects:changedObjects];
    
    [[self primitiveusedBySessions] removeObject:value];
    
    [self didChangeValueForKey:@"usedBySessions"
     
               withSetMutation:NSKeyValueMinusSetMutation
     
                  usingObjects:changedObjects];
    
    
    [changedObjects release];
}

- (void)addUsedBySessions:(NSSet *)values
{
    [self willChangeValueForKey:@"usedBySessions"
     
                withSetMutation:NSKeyValueUnionSetMutation
     
                   usingObjects:values];
    
    [[self primitiveusedBySessions] unionSet:values];
    
    [self didChangeValueForKey:@"usedBySessions"
     
               withSetMutation:NSKeyValueUnionSetMutation
     
                  usingObjects:values];
}

- (void)removeUsedBySessions:(NSSet *)values
{
    [self willChangeValueForKey:@"usedBySessions"
     
                withSetMutation:NSKeyValueMinusSetMutation
     
                   usingObjects:values];
    
    [[self primitiveusedBySessions] minusSet:values];
    
    [self didChangeValueForKey:@"usedBySessions"
     
               withSetMutation:NSKeyValueMinusSetMutation
     
                  usingObjects:values];
}
@end
