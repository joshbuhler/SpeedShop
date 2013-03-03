//
//  MFPreset.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFPreset.h"

@implementation MFPreset

@synthesize name;
@synthesize author;

- (void) loadPresetFile:(NSURL *)url
{
    NSXMLParser *cParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    
    cParser.delegate = self;
    
    [cParser setShouldResolveExternalEntities:YES];
    
    [cParser parse];
}


#pragma mark - NSXMLParserDelegate methods
- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"Info"])
    {
        self.name = [attributeDict valueForKey:@"name"];
        self.author = [attributeDict valueForKey:@"author"];
        
        NSLog(@"Preset: %@ by %@", self.name, self.author);
    }
}


@end
