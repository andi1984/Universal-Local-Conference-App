//  Conference.h
//  ConferenceApp


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Conference : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * recommendedhotels;
@property (nonatomic, retain) NSString * conferencelogourl;
@property (nonatomic, retain) NSDate * startdate;
@property (nonatomic, retain) NSString * journeyplan;
@property (nonatomic, retain) NSString * slogan;
@property (nonatomic, retain) NSString * contact;
@property (nonatomic, retain) NSString * imprint;
@property (nonatomic, retain) NSString * newsfeedurl;
@property (nonatomic, retain) NSString * conditions;
@property (nonatomic, retain) NSString * topic;
@property (nonatomic, retain) NSString * targetedaudience;
@property (nonatomic, retain) NSString * acronym;
@property (nonatomic, retain) NSString * registrationurl;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * timezone;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * homepageurl;
@property (nonatomic, retain) NSString * conferencexmlurl;
@property (nonatomic, retain) NSString * sponsorxmlurl;
@property (nonatomic, retain) NSString * venuexmlurl;
@property (nonatomic, retain) NSString * sessionxmlurl;
@property (nonatomic, retain) NSString * userxmlurl;
@property (nonatomic, retain) NSString * welcomemessage;
@property (nonatomic, retain) NSString * welcomevideo;
+ (Conference *)initConferenceWithContext:(NSManagedObjectContext *)context;
@end
