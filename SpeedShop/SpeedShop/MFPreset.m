//
//  MFPreset.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFPreset.h"

NSString *const DropTypeMFPreset = @"DropTypeMFPreset";

@interface MFPreset()
{
    // Used for XML parsing
    NSMutableString *currentElementValue;
    
    BOOL    _parsingAmp;
    
    // Location of the file on disk
    NSURL *_fileURL;
}

@end

@implementation MFPreset


- (void) loadPresetFile:(NSURL *)url
{
    _fileURL = url;
    
    NSXMLParser *cParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    
    cParser.delegate = self;
    
    [cParser setShouldResolveExternalEntities:YES];
    
    [cParser parse];
}

- (NSURL *) fileURL
{
    return _fileURL;
}

#pragma mark - NSCoding Methods
- (void) encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_name forKey:@"name"];
    [encoder encodeObject:_author forKey:@"author"];
    [encoder encodeObject:_description forKey:@"description"];
    [encoder encodeObject:_fileURL forKey:@"fileURL"];
    [encoder encodeObject:_uuid forKey:@"uuid"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self.name = [decoder decodeObjectForKey:@"name"];
    self.author = [decoder decodeObjectForKey:@"author"];
    self.description = [decoder decodeObjectForKey:@"description"];
    _fileURL = [decoder decodeObjectForKey:@"fileURL"];
    self.uuid = [decoder decodeObjectForKey:@"uuid"];
    
    return self;
}


#pragma mark - NSXMLParserDelegate methods
- (void) parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
     attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"Amplifier"])
    {
        _parsingAmp = YES;
    }
    
    if ([elementName isEqualToString:@"Module"])
    {
        if (_parsingAmp)
        {
            NSLog(@"Amp: %d", [[attributeDict valueForKey:@"ID"] intValue]);
        }
    }
    
    
    if ([elementName isEqualToString:@"Info"])
    {
        self.name = [attributeDict valueForKey:@"name"];
        self.author = [attributeDict valueForKey:@"author"];
        
        //NSLog(@"     Preset: %@ by %@", self.name, self.author);
        
        currentElementValue = nil;
    }
}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!currentElementValue)
    {
        currentElementValue = [[NSMutableString alloc] initWithString:string];
    }
    else
    {
        [currentElementValue appendString:string];
    }
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"Amplifier"])
    {
        _parsingAmp = NO;
    }
    
    if ([elementName isEqualToString:@"Info"])
    {
        self.description = currentElementValue;
    }
    
    currentElementValue = nil;
}

-(NSString *) description
{
    return _name;
}
@end
