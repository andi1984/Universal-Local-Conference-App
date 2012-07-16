//
//  UserCSVParser.h
//  CSVParser

#import <Foundation/Foundation.h>
#import "CHCSV.h"

@interface SessionCSVParser : NSObject<CHCSVParserDelegate>
{
    int currentColumn;
    int idColumn;
    int titleColumn;
    int abstractColumn;
    int dateColumn;
    int starttimeColumn;
    int durationColumn;
    int roomnameColumn;
    int venueColumn;
    int speakersColumn;
    int tagsColumn;
    BOOL isHeaderRow;
    NSMutableArray *sessionArray;
    NSMutableDictionary *currentUserDic;
}
- (NSMutableArray *) getSessionsFromCSVFileAtURL:(NSURL *)csvURL;
@property (nonatomic, retain) NSMutableArray *sessionArray;
@end
