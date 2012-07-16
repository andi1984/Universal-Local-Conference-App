//
//  UserCSVParser.m
//  CSVParser

#import "SessionCSVParser.h"
#import "CHCSV.h"
@implementation SessionCSVParser
@synthesize sessionArray;
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
    [sessionArray release];
    [super dealloc];
}
- (void) parser:(CHCSVParser *)parser didStartDocument:(NSString *)csvFile {
    self.sessionArray = [[[NSMutableArray alloc] init] autorelease];
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
        
        if([fieldString isEqualToString:@"sessionid"])
            idColumn = currentColumn;
        
        if([fieldString isEqualToString:@"title"])
            titleColumn = currentColumn;
        
        if([fieldString isEqualToString:@"abstract"])
            abstractColumn = currentColumn;
        
        if([fieldString isEqualToString:@"date"])
            dateColumn = currentColumn;
        
        if([fieldString isEqualToString:@"starttime"])
            starttimeColumn = currentColumn;
        
        if([fieldString isEqualToString:@"duration"])
            durationColumn = currentColumn;
        
        if([fieldString isEqualToString:@"roomname"])
            roomnameColumn = currentColumn;
        
        if([fieldString isEqualToString:@"tags"])
            tagsColumn = currentColumn;
    
        if([fieldString isEqualToString:@"speakers"])
            speakersColumn = currentColumn;
        
        if([fieldString isEqualToString:@"venue"])
            venueColumn = currentColumn;
    }
    else
    {
        if(currentColumn == idColumn)
            [currentUserDic setValue:fieldString forKey:@"sessionid"];
        
        if(currentColumn == titleColumn)
            [currentUserDic setValue:fieldString  forKey:@"title"];
        
        if(currentColumn == abstractColumn)
            [currentUserDic setValue:fieldString forKey:@"abstract"];
        
        if(currentColumn == dateColumn)
            [currentUserDic setValue:fieldString forKey:@"date"];
        
        if(currentColumn == starttimeColumn)
            [currentUserDic setValue:fieldString forKey:@"starttime"];
        
        if(currentColumn == durationColumn)
            [currentUserDic setValue:fieldString forKey:@"duration"];
        
        if(currentColumn == roomnameColumn)
            [currentUserDic setValue:fieldString forKey:@"roomname"];
        
        if(currentColumn == tagsColumn)
            [currentUserDic setValue:fieldString forKey:@"tags"];
        
        if(currentColumn == speakersColumn)
            [currentUserDic setValue:fieldString forKey:@"speakers"];
        
        if(currentColumn == venueColumn)
            [currentUserDic setValue:fieldString forKey:@"venue"];
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
        //.. füge Dictionary in sessionArray hinzu und release es
        
        [self.sessionArray addObject:currentUserDic];
        [currentUserDic release];
    }
    [didEndPool drain];
}
- (void) parser:(CHCSVParser *)parser didEndDocument:(NSString *)csvFile {
}
- (void) parser:(CHCSVParser *)parser didFailWithError:(NSError *)error {
}


- (NSMutableArray *) getSessionsFromCSVFileAtURL:(NSURL *)csvURL
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
        return [self.sessionArray retain];
    }
    else
    {
        return nil;
    }
    //[getUserPool drain];
}
@end
