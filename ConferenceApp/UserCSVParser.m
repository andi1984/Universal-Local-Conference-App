//  UserCSVParser.m
//  CSVParser


#import "UserCSVParser.h"
#import "CHCSV.h"
@implementation UserCSVParser
@synthesize userArray;
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [userArray release];
    [super dealloc];
}
- (void) parser:(CHCSVParser *)parser didStartDocument:(NSString *)csvFile {
    self.userArray = [[[NSMutableArray alloc] init] autorelease];
}
- (void) parser:(CHCSVParser *)parser didStartLine:(NSUInteger)lineNumber {
    NSAutoreleasePool *didStartPool = [[NSAutoreleasePool alloc] init];
    currentColumn = 0;
    if(lineNumber == 1)
    {
        //Parser ist in Zeile 1, also im Header. Setze int Werte für die einzelnen typen
        isHeaderRow = YES;        
    }
    else
    {
        isHeaderRow = NO;
        currentUserDic = [[NSMutableDictionary alloc] init];
    } 
    [didStartPool drain];
}
- (void) parser:(CHCSVParser *)parser didReadField:(NSString *)field {
    NSAutoreleasePool *readPool = [[NSAutoreleasePool alloc] init];
    NSString *fieldString = [[NSString alloc] initWithString:field];
    if(isHeaderRow)
    {
        //Spalten-NR den einzelnen Sachen anordnen
        
        if([fieldString isEqualToString:@"userid"])
            idColumn = currentColumn;
        
        if([fieldString isEqualToString:@"role"])
            roleColumn = currentColumn;
        
        if([fieldString isEqualToString:@"email"])
            emailColumn = currentColumn;
        
        if([fieldString isEqualToString:@"pictureurl"])
            pictureURLColumn = currentColumn;
        
        if([fieldString isEqualToString:@"firstname"])
            firstNameColumn = currentColumn;
        
        if([fieldString isEqualToString:@"lastname"])
            lastNameColumn = currentColumn;
        
        if([fieldString isEqualToString:@"age"])
            ageColumn = currentColumn;
        
        if([fieldString isEqualToString:@"shortdescription"])
            shortDescriptionColumn = currentColumn;
        
        if([fieldString isEqualToString:@"cv"])
            cvColumn = currentColumn;
        
        if([fieldString isEqualToString:@"vcardurl"])
            vcardColumn = currentColumn;
        
        if([fieldString isEqualToString:@"tags"])
            tagsColumn = currentColumn;
        
        if([fieldString isEqualToString:@"homepageurl"])
            homepageColumn = currentColumn;
    }
    else
    {
        if(currentColumn == idColumn)
            [currentUserDic setValue:fieldString forKey:@"userid"];
        
        if(currentColumn == roleColumn)
            [currentUserDic setValue:fieldString  forKey:@"role"];
        
        if(currentColumn == emailColumn)
            [currentUserDic setValue:fieldString forKey:@"email"];
        
        if(currentColumn == pictureURLColumn)
            [currentUserDic setValue:fieldString forKey:@"pictureurl"];
        
        if(currentColumn == firstNameColumn)
            [currentUserDic setValue:fieldString forKey:@"firstname"];
        
        if(currentColumn == lastNameColumn)
            [currentUserDic setValue:fieldString forKey:@"lastname"];
        
        if(currentColumn == ageColumn)
            [currentUserDic setValue:fieldString forKey:@"age"];
        
        if(currentColumn == shortDescriptionColumn)
            [currentUserDic setValue:fieldString forKey:@"shortdescription"];
        
        if(currentColumn == cvColumn)
            [currentUserDic setValue:fieldString forKey:@"cv"];
        
        if(currentColumn == vcardColumn)
            [currentUserDic setValue:fieldString forKey:@"vcardurl"];
        
        if(currentColumn == tagsColumn)
            [currentUserDic setValue:fieldString forKey:@"tags"];
        
        if(currentColumn == homepageColumn)
            [currentUserDic setValue:fieldString forKey:@"homepageurl"];
    }
    [fieldString release];
    
    //Spaltennummer um eins erhöhen
    currentColumn = currentColumn + 1;
    [readPool drain];
}
- (void) parser:(CHCSVParser *)parser didEndLine:(NSUInteger)lineNumber {
    NSAutoreleasePool *didEndPool = [[NSAutoreleasePool alloc] init];
    if(!isHeaderRow)
    {
        //Sofern es nicht Header Zeile war
        //.. füge Dictionary in userArray hinzu und release es
        
        [self.userArray addObject:currentUserDic];
        [currentUserDic release];
    }
    [didEndPool drain];
}
- (void) parser:(CHCSVParser *)parser didEndDocument:(NSString *)csvFile {
}
- (void) parser:(CHCSVParser *)parser didFailWithError:(NSError *)error {
}


- (NSMutableArray *) getUsersFromCSVFileAtURL:(NSURL *)csvURL
{
    //NSAutoreleasePool *getUserPool = [[NSAutoreleasePool alloc] init];
    NSError *gettingFileError = nil;
    NSString * csvString = [NSString stringWithContentsOfURL:csvURL encoding:NSUTF8StringEncoding error:&gettingFileError];
    if(!gettingFileError)
    {
        NSError *parseError = nil;
        CHCSVParser *parser = [[[CHCSVParser alloc] initWithCSVString:csvString encoding:NSUTF8StringEncoding error:&parseError] autorelease];  
        [parser setDelimiter:@";"]; 
        if(parseError)
            return nil;
        
        [parser setParserDelegate:self];
        
        [parser parse];
        
        //[parser release];
        return [self.userArray retain];
    }
    else
    {
        return nil;
    }
    //[getUserPool drain];
}
@end
