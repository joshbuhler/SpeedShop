//
//  MFPreset.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFPreset.h"
#import "MFFuseBackup.h"

NSString *const DropTypeMFPreset = @"DropTypeMFPreset";

@interface MFPreset()
{
    // Used for XML parsing
    NSMutableString *currentElementValue;
    
    BOOL    _parsingAmp;
    BOOL    _parsingGDecAmp;
    BOOL    _parsingStomp;
    BOOL    _parsingMod;
    BOOL    _parsingDelay;
    BOOL    _parsingReverb;
    
    // Location of the file on disk
    NSURL *_fileURL;
}

@end

@implementation MFPreset

@synthesize ampModel = _ampModel;
@synthesize fxStomp = _fxStomp;
@synthesize fxModulation = _fxModulation;
@synthesize fxDelay = _fxDelay;
@synthesize fxReverb = _fxReverb;

- (void) loadPresetFile:(NSURL *)url
{
    _fileURL = url;
    
    NSXMLParser *cParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    
    cParser.delegate = self;
    
    [cParser setShouldResolveExternalEntities:YES];
    
    [cParser parse];
    

    NSLog(@"Preset: %@", self.name);
    
    NSString *searchString = @"UNKNOWN";
    if ([[[MFPreset getNameForAmpModel:_ampModel] lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound)
        NSLog(@"    _ampModel: %@", [MFPreset getNameForAmpModel:_ampModel]);
    
    if ([[[MFPreset getNameForFXStomp:_fxStomp] lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound)
        NSLog(@"    _fxStomp: %@", [MFPreset getNameForFXStomp:_fxStomp]);
    
    if ([[[MFPreset getNameForFXModulation:_fxModulation] lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound)
        NSLog(@"    _fxModulation: %@", [MFPreset getNameForFXModulation:_fxModulation]);
    
    if ([[[MFPreset getNameForFXDelay:_fxDelay] lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound)
        NSLog(@"    _fxDelay: %@", [MFPreset getNameForFXDelay:_fxDelay]);
    
    if ([[[MFPreset getNameForFXReverb:_fxReverb] lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound)
        NSLog(@"    _fxReverb: %@", [MFPreset getNameForFXReverb:_fxReverb]);
}

- (NSURL *) fileURL
{
    return _fileURL;
}

#pragma mark - NSCoding Methods
- (void) encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_name forKey:@"name"];
    [encoder encodeObject:_originalName forKey:@"originalName"];
    [encoder encodeObject:_author forKey:@"author"];
    [encoder encodeObject:_description forKey:@"description"];
    [encoder encodeObject:_fileURL forKey:@"fileURL"];
    [encoder encodeObject:_uuid forKey:@"uuid"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self.name = [decoder decodeObjectForKey:@"name"];
    self.originalName = [decoder decodeObjectForKey:@"originalName"];
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
    
    if ([elementName isEqualToString:@"Stompbox"])
    {
        _parsingStomp = YES;
    }
    
    if ([elementName isEqualToString:@"Modulation"])
    {
        _parsingMod = YES;
    }
    
    if ([elementName isEqualToString:@"Delay"])
    {
        _parsingDelay = YES;
    }
    
    if ([elementName isEqualToString:@"Reverb"])
    {
        _parsingReverb = YES;
    }
    
    if ([elementName isEqualToString:@"Module"])
    {
        if (_parsingAmp)
        {
            if (self.backup.ampSeries != AmpSeries_GDec)
            {
                _ampModel = [[attributeDict valueForKey:@"ID"] intValue];
                //NSLog(@"    _ampModel: %@", [MFPreset getNameForAmpModel:_ampModel]);
            }
        }
        
        if (_parsingStomp)
        {
            _fxStomp = [[attributeDict valueForKey:@"ID"] intValue];
//            NSLog(@"    _fxStomp: %@", [MFPreset getNameForFXStomp:_fxStomp]);
        }
        
        if (_parsingMod)
        {
            _fxModulation = [[attributeDict valueForKey:@"ID"] intValue];
//            NSLog(@"    _fxModulation: %@", [MFPreset getNameForFXModulation:_fxModulation]);
        }
        
        if (_parsingDelay)
        {
            _fxDelay = [[attributeDict valueForKey:@"ID"] intValue];
//            NSLog(@"    _fxDelay: %@", [MFPreset getNameForFXDelay:_fxDelay]);
        }
        
        if (_parsingReverb)
        {
            _fxReverb = [[attributeDict valueForKey:@"ID"] intValue];
//            NSLog(@"    _fxReverb: %@", [MFPreset getNameForFXReverb:_fxReverb]);
        }
    }
    
    if ([elementName isEqualToString:@"Param"])
    {
        if (self.backup.ampSeries == AmpSeries_GDec && _parsingAmp)
        {
            // parse amp model ID from param with ControlIndex "0"
            if ([[attributeDict valueForKey:@"ControlIndex"] intValue] == 0)
            {
                _parsingGDecAmp = YES;
            }
        }
    }
    
    
    if ([elementName isEqualToString:@"Info"])
    {
        self.name = [attributeDict valueForKey:@"name"];
        self.originalName = [NSString stringWithString:self.name];  // remember, if name is edited
        self.author = [attributeDict valueForKey:@"author"];
        
        //NSLog(@"Preset: %@ by %@. Orig: %@", self.name, self.author, self.originalName);
//        NSLog(@"\nPreset: %@", self.name);
    }
    
    // reset for the next node
    currentElementValue = nil;
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
    // parsing amp model for gdec amps
    if (self.backup.ampSeries == AmpSeries_GDec)
    {
        if ([elementName isEqualToString:@"Param"] && _parsingGDecAmp)
        {
            _ampModel = [currentElementValue intValue];
            _parsingGDecAmp = NO;
        }
    }
    
    if ([elementName isEqualToString:@"Amplifier"])
    {
        _parsingAmp = NO;
    }
    
    if ([elementName isEqualToString:@"Stompbox"])
    {
        _parsingStomp = NO;
    }
    
    if ([elementName isEqualToString:@"Modulation"])
    {
        _parsingMod = NO;
    }
    
    if ([elementName isEqualToString:@"Delay"])
    {
        _parsingDelay = NO;
    }
    
    if ([elementName isEqualToString:@"Reverb"])
    {
        _parsingReverb = NO;
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

#pragma mark - Conversion Helpers
+ (NSString *) getNameForAmpModel:(AmpModel)model
{
    switch (model) {
            // G-Dec
        case AmpModel_Tweed_Clean:
            return @"Tweed Clean";
        case AmpModel_Tweed_Drive:
            return @"Tweed Drive";
        case AmpModel_Tweed_Dirt:
            return @"Tweed Dirt";
        case AmpModel_Blackface_Clean:
            return @"Blackface Clean";
        case AmpModel_Blackface_Drive:
            return @"Blackface Drive";
        case AmpModel_Blackface_Distorted:
            return @"Blackface Distorted";
        case AmpModel_Jazzmaster:
            return @"Jazzmaster";
        case AmpModel_Garage_Rock:
            return @"Garage Rock";
        case AmpModel_Garage_Punk:
            return @"Garage Punk";
        case AmpModel_Very_Distorted:
            return @"Very Distorted";
        case AmpModel_Brit_Jangle:
            return @"Brit Jangle";
        case AmpModel_Brit_Blues:
            return @"Brit Blues";
        case AmpModel_British_Steel:
            return @"British Steel";
        case AmpModel_Modern_Crunch:
            return @"Modern Crunch";
        case AmpModel_Modern_Metal:
            return @"Modern Metal";
        case AmpModel_Modern_Shred:
            return @"Modern Shred";
        case AmpModel_HotRod_Grit:
            return @"HotRod Grit";
        case AmpModel_HotRod_Lead:
            return @"HotRod Lead";
        case AmpModel_Acoustic_Dred_M:
            return @"Acou Dred M";
        case AmpModel_Acoustic_Jumbo:
            return @"Acou Jumbo";
        case AmpModel_Acoustic_Dred_R:
            return @"Acou Dred R";
        case AmpModel_Acoustic_Parlor:
            return @"Acou Parlor";
            
            
            // Mustang
        case AmpModel_Fender_57_Deluxe:
            return @"Fender '57 Deluxe";
        case AmpModel_Fender_59_Bassman:
            return @"Fender '59 Bassman";
        case AmpModel_Fender_57_Champ:
            return @"Fender '57 Champ";
        case AmpModel_Fender_65_Deluxe_Reverb:
            return @"Fender '65 Deluxe Reverb";
        case AmpModel_Fender_65_Princeton:
            return @"Fender '65 Princeton";
        case AmpModel_Fender_65_Twin_Reverb:
            return @"Fender '65 Twin Reverb";
        case AmpModel_Fender_Super_Sonic:
            return @"Fender Super Sonic";
        case AmpModel_British_60s:
            return @"British '60s";
        case AmpModel_British_70s:
            return @"British '70s";
        case AmpModel_British_80s:
            return @"British '80s";
        case AmpModel_American_90s:
            return @"American '90s";
        case AmpModel_Metal_2000:
            return @"Metal 2000";            
            
        default:
            return [NSString stringWithFormat:@"**** UNKNOWN Amp Model: %d", model];
    }
}

+ (NSString *) getNameForFXStomp:(FXStomp)model
{
    switch (model) {
        case FX_Stomp_Empty:
            return @"Empty";
        case FX_Stomp_Overdrive:
            return @"Overdrive";
        case FX_Stomp_Wah:
            return @"Wah";
        case FX_Stomp_Touch_Wah:
            return @"Touch Wah";
        case FX_Stomp_Fuzz:
            return @"Fuzz";
        case FX_Stomp_Fuzz_Touch_Wah:
            return @"Fuzz Touch Wah";
        case FX_Stomp_Simple_Comp:
            return @"Simple Comp";
        case FX_Stomp_Compressor:
            return @"Compressor";
        default:
            return [NSString stringWithFormat:@"**** UNKNOWN Stomp: %d", model];
    }
}

+ (NSString *) getNameForFXModulation:(FXModulation)model
{
    switch (model) {
        case FX_Modulation_Empty:
            return @"Empty";
        case FX_Modulation_Sine_Chorus:
            return @"Sine Chorus";
        case FX_Modulation_Triangle_Chorus:
            return @"Triangle Chorus";
        case FX_Modulation_Sine_Flanger:
            return @"Sine Flanger";
        case FX_Modulation_Triangle_Flanger:
            return @"Triangle Flanger";
        case FX_Modulation_Vibratone:
            return @"Vibratone";
        case FX_Modulation_Vintage_Tremolo:
            return @"Vintage Tremolo";
        case FX_Modulation_Sine_Tremolo:
            return @"Sine Tremolo";
        case FX_Modulation_Ring_Modulator:
            return @"Ring Modulator";
        case FX_Modulation_Step_Filter:
            return @"Step Filter";
        case FX_Modulation_Phaser:
            return @"Phaser";
        case FX_Modulation_Pitch_Shifter:
            return @"Pitch Shifter";
        default:
            return [NSString stringWithFormat:@"**** UNKNOWN Modulation: %d", model];
    }
}

+ (NSString *) getNameForFXDelay:(FXDelay)model
{
    switch (model) {
        case FX_Delay_Empty:
            return @"Empty";
        case FX_Delay_Mono:
            return @"Mono";
        case FX_Delay_Mono_Echo_Filter:
            return @"Mono Echo Filter";
        case FX_Delay_Stereo_Echo_Filter:
            return @"Stero Echo Filter";
        case FX_Delay_Multitap:
            return @"Multitap";
        case FX_Delay_Ping_Pong:
            return @"Ping Pong";
        case FX_Delay_Ducking:
            return @"Ducking";
        case FX_Delay_Reverse:
            return @"Reverse";
        case FX_Delay_Tape:
            return @"Tape";
        case FX_Delay_Stereo_Tape:
            return @"Stereo Tape";
        default:
            return [NSString stringWithFormat:@"**** UNKNOWN Delay: %d", model];
    }
}

+ (NSString *) getNameForFXReverb:(FXReverb)model
{
    switch (model) {
        case FX_Reverb_Empty:
            return @"Empty";
        case FX_Reverb_Small_Hall:
            return @"Small Hall";
        case FX_Reverb_Large_Hall:
            return @"Large Hall";
        case FX_Reverb_Small_Room:
            return @"Small Room";
        case FX_Reverb_Large_Room:
            return @"Large Room";
        case FX_Reverb_Small_Plate:
            return @"Small Plate";
        case FX_Reverb_Large_Plate:
            return @"Large Plate";
        case FX_Reverb_Ambient:
            return @"Ambient";
        case FX_Reverb_Arena:
            return @"Arena";
        case FX_Reverb_Fender_63_Spring:
            return @"Fender '63 Spring";
        case FX_Reverb_Fender_65_Spring:
            return @"Fender '65 Spring";
        default:
            return [NSString stringWithFormat:@"**** UNKNOWN Reverb: %d", model];
    }
}
@end
