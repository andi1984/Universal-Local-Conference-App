//
//  UserCSVParser.h
//  CSVParser


#import <Foundation/Foundation.h>
#import "CHCSV.h"

@interface UserCSVParser : NSObject<CHCSVParserDelegate>
{
    int currentColumn;
    int idColumn;
    int roleColumn;
    int emailColumn;
    int pictureURLColumn;
    int firstNameColumn;
    int lastNameColumn;
    int ageColumn;
    int shortDescriptionColumn;
    int cvColumn;
    int vcardColumn;
    int tagsColumn;
    int homepageColumn;
    BOOL isHeaderRow;
    NSMutableArray *userArray;
    NSMutableDictionary *currentUserDic;
}
- (NSMutableArray *) getUsersFromCSVFileAtURL:(NSURL *)csvURL;
@property (nonatomic, retain) NSMutableArray *userArray;
@end
