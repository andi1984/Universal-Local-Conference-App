//  ConferenceAppAppDelegate.h
//  ConferenceApp


#import <UIKit/UIKit.h>

@interface ConferenceAppAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain) UINavigationController *navController;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
