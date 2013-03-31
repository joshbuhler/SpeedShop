//
//  MFFuseBackup.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 3/2/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFFuseBackup.h"
#import "MFFuseBackup+MFFuseBackup_Private.h"

NSString *FUSE_FOLDER = @"FUSE";
NSString *PRESET_FOLDER = @"Presets";
NSString *BACKUP_FILENAME_GDEC = @"GD_BackupName.fuse";
NSString *BACKUP_FILENAME_MUSTANG = @"MU_BackupName.fuse";
NSString *SETTINGS_FILENAME = @"SystemSettings.fuse";

@interface MFFuseBackup()
{
    MFFuseBackupCompletion      _loadCompletionBlock;
    MFFuseBackupSaveCompletion  _saveCompletionBlock;
    
    NSURL   *_newFolderURL;
    
    AmpSeries   _ampType;
    
    // Used for XML parsing
    NSMutableString *currentElementValue;
}

@end

@implementation MFFuseBackup

@synthesize folderURL = _folderURL;
@synthesize presets = _presets;
@synthesize quickAccessPresets = _quickAccessPresets;

- (void) loadBackup:(NSURL *)url withCompletion:(MFFuseBackupCompletion)block
{
    self.folderURL = url;
    
    _loadCompletionBlock = block;
    
    if (![self validateBackupContents])
    {
        [self completeLoading:NO];
        return;
    }
    
    self.presets = [[NSMutableArray alloc] init];
    self.quickAccessPresets = [[NSMutableArray alloc] init];
    
    [self loadBackupContents];
}


#pragma mark - Private Methods

- (BOOL) validateBackupContents
{
    // Simple check to make sure that everything we need is in it's place
    // We should have four items:
    // - "FUSE" folder
    // - "Presets" folder
    // - "MU_BackupName.fuse" file or "GD_BackupName.fuse"
    // - "SystemSettings.fuse" file - Mustang only
    
    NSFileManager *fileMan = [NSFileManager defaultManager];
    
    NSURL *fuseDir = [_folderURL URLByAppendingPathComponent:FUSE_FOLDER];
    if ([fileMan fileExistsAtPath:[fuseDir path]] == NO)
        return NO;
    
    // Do we have anything in here?
    NSError *error = nil;
    NSArray *fuseContents = [fileMan contentsOfDirectoryAtPath:[fuseDir path] error:&error];
    if ([fuseContents count] <= 0 || error != nil)
        return NO;
    
    // now the Presets directory
    NSURL *presetDir = [_folderURL URLByAppendingPathComponent:PRESET_FOLDER];
    if ([fileMan fileExistsAtPath:[presetDir path]] == NO)
        return NO;
    
    NSArray *presetContents = [fileMan contentsOfDirectoryAtPath:[presetDir path] error:&error];
    if ([presetContents count] <= 0 || error != nil)
        return NO;
    
    // Check for backup file
    BOOL backupFileFound = NO;
    
    NSURL *backupFileMustang = [_folderURL URLByAppendingPathComponent:BACKUP_FILENAME_MUSTANG];
    if ([fileMan fileExistsAtPath:[backupFileMustang path]] == YES)
    {
        backupFileFound = YES;
        _ampType = AmpSeries_Mustang;
    }
    
    NSURL *backupFileGDec = [_folderURL URLByAppendingPathComponent:BACKUP_FILENAME_GDEC];
    if ([fileMan fileExistsAtPath:[backupFileGDec path]] == YES)
    {
        backupFileFound = YES;
        _ampType = AmpSeries_GDec;
    }
    
    if (!backupFileFound)
        return NO;
    
    // Look for a settings file if it's a Mustang series
    if (_ampType == AmpSeries_Mustang)
    {
        NSURL *settingsFile = [_folderURL URLByAppendingPathComponent:SETTINGS_FILENAME];
        if ([fileMan fileExistsAtPath:[settingsFile path]] == NO)
            return NO;
    }
    
    // Looks like on the surface everything is cool to begin parsing
    return YES;
}

- (void) loadBackupContents
{
    [self loadBackupDescription];
    [self loadAmpSettings];
    
    // TODO: delegate progress method for loading status (we do have to analyze 99 files, after all)
    [self loadPresetFiles];
}

- (void) loadBackupDescription
{
    NSURL *backupFile = [_folderURL URLByAppendingPathComponent:BACKUP_FILENAME_MUSTANG];
    
    NSData *data = [NSData dataWithContentsOfURL:backupFile];
    NSString *desc = [[NSString alloc] initWithBytes:[data bytes]
                                              length:[data length]
                                            encoding:NSUTF8StringEncoding];
    
    self.backupDescription = desc;    
}

- (void) loadAmpSettings
{
    NSURL *settingsFile = [_folderURL URLByAppendingPathComponent:SETTINGS_FILENAME];
    
    NSXMLParser *cParser = [[NSXMLParser alloc] initWithContentsOfURL:settingsFile];
    
    currentElementValue = nil;
    self.quickAccessPresets = [[NSMutableArray alloc] init];
    
    cParser.delegate = self;
    [cParser setShouldResolveExternalEntities:YES];
    [cParser parse];
}

#pragma mark - NSXMLParserDelegate methods
- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"QA"])
    {
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
    if ([elementName isEqualToString:@"QA"])
    {
        [_quickAccessPresets addObject:[NSNumber numberWithInt:[currentElementValue intValue]]];
    }
    
    currentElementValue = nil;
}

#pragma mark - Preset Loading

// Loads "Preset" folder contents to get an overview of the preset files.
- (void) loadPresetFiles
{
    NSFileManager *fileMan = [NSFileManager defaultManager];
    
    NSURL *presetDir = [_folderURL URLByAppendingPathComponent:PRESET_FOLDER];
    NSError *error = nil;
    NSArray *presetContents = [fileMan contentsOfDirectoryAtPath:[presetDir path] error:&error];
    
    if (error)
    {
        NSLog(@"*** ERROR: error loading fuse files");
        [self completeLoading:NO];
        return;
    }
    
    for (int i = 0; i < presetContents.count; i++)
    {
        //NSLog(@"fileName: %@", [presetContents objectAtIndex:i]);
        
        NSURL *cURL = [presetDir URLByAppendingPathComponent:[presetContents objectAtIndex:i]];
        MFPreset *cPreset = [[MFPreset alloc] init];
        
        cPreset.backup = self;
        cPreset.uuid = [self newUUID];
        
        [cPreset loadPresetFile:cURL];
        
        [self.presets addObject:cPreset];
    }

    [self completeLoading:YES];
}

- (void) completeLoading:(BOOL)success
{    
    if (_loadCompletionBlock)
        _loadCompletionBlock(success);
}

#pragma mark - Exporting / Saving
// Saves to the existing location
- (void) saveWithCompletion:(MFFuseBackupSaveCompletion)block
{
    _saveCompletionBlock = block;
    
    [self saveToURL:self.folderURL];
}

- (void) saveAsNewBackup:(NSURL *)url withCompletion:(MFFuseBackupSaveCompletion)block
{
    _saveCompletionBlock = block;
    
    // create a new folder at the specified path - filename must be a date, otherwise
    // FUSE won't see it
    NSDate *now = [NSDate date];
    NSDateFormatter *filenameFormat = [[NSDateFormatter alloc] init];
    [filenameFormat setDateFormat:@"yyyy_MM_dd_hh_mm_ss"];
    NSString *dateFileName = [filenameFormat stringFromDate:now];
    
    NSURL *destURL = [url URLByAppendingPathComponent:dateFileName];
    [self saveToURL:destURL];
}

- (void) saveToURL:(NSURL *)destURL
{
    NSFileManager *fileMan = [NSFileManager defaultManager];
    NSError *error = nil;
    
    // copy write to a temp dir, then copy to the destination once done
    NSURL *tempDir = [fileMan URLForDirectory:NSItemReplacementDirectory
                                     inDomain:NSUserDomainMask
                            appropriateForURL:destURL
                                       create:YES
                                        error:&error];
    
    
    [fileMan createDirectoryAtURL:tempDir
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error];
    if (error)
    {
        [self completeSaving:NO];
        return;
    }
    
    // now copy over the settings & description files
    [self.backupDescription writeToURL:[tempDir URLByAppendingPathComponent:BACKUP_FILENAME_MUSTANG]
                            atomically:YES
                              encoding:NSUTF8StringEncoding
                                 error:&error];
    
    if (error)
    {
        [self completeSaving:NO];
        return;
    }
    
    // Saving of the settings file
    NSURL *settingsFile = [_folderURL URLByAppendingPathComponent:SETTINGS_FILENAME];
    NSXMLDocument *settingsXML = [[NSXMLDocument alloc] initWithContentsOfURL:settingsFile
                                                                      options:NSXMLDocumentTidyXML
                                                                        error:&error];
    NSXMLElement *docRoot = [settingsXML rootElement];
    // replace the first three QA nodes
    NSNumber *qaIndex1 = (NSNumber *)[self.quickAccessPresets objectAtIndex:0];
    MFPreset *preset1 = (MFPreset *)[self.presets objectAtIndex:[qaIndex1 intValue]];
    int index1 = [self indexForPreset:preset1];
    NSXMLElement *qa1 = [NSXMLElement elementWithName:@"QA" stringValue:[NSString stringWithFormat:@"%d", index1]];
    [docRoot replaceChildAtIndex:0 withNode:qa1];
    
    NSNumber *qaIndex2 = (NSNumber *)[self.quickAccessPresets objectAtIndex:1];
    MFPreset *preset2 = (MFPreset *)[self.presets objectAtIndex:[qaIndex2 intValue]];
    int index2 = [self indexForPreset:preset2];
    NSXMLElement *qa2 = [NSXMLElement elementWithName:@"QA" stringValue:[NSString stringWithFormat:@"%d", index2]];
    [docRoot replaceChildAtIndex:1 withNode:qa2];
    
    NSNumber *qaIndex3 = (NSNumber *)[self.quickAccessPresets objectAtIndex:2];
    MFPreset *preset3 = (MFPreset *)[self.presets objectAtIndex:[qaIndex3 intValue]];
    int index3 = [self indexForPreset:preset3];
    NSXMLElement *qa3 = [NSXMLElement elementWithName:@"QA" stringValue:[NSString stringWithFormat:@"%d", index3]];
    [docRoot replaceChildAtIndex:2 withNode:qa3];
    
//    NSString *dtdString = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>";
    NSString *settingsData = [settingsXML XMLStringWithOptions:NSXMLNodePrettyPrint];
//    NSString *exportString = [NSString stringWithFormat:@"%@%@", dtdString, settingsData];
    [settingsData writeToURL:[tempDir URLByAppendingPathComponent:SETTINGS_FILENAME]
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error];
    
    if (error)
    {
        [self completeSaving:NO];
        return;
    }
    
    // now rename and copy over the items in the Presets folder based on their new order
    BOOL presetsCopied = [self copyPresetFilesToNewDir:tempDir];
    if (presetsCopied == NO)
    {
        [self completeSaving:NO];
    }
    
    [fileMan replaceItemAtURL:destURL
                withItemAtURL:tempDir
               backupItemName:[NSString stringWithFormat:@"%@_backup", [destURL lastPathComponent]]
                      options:0
             resultingItemURL:&destURL
                        error:&error];
    
    if (error)
    {
        [self completeSaving:NO];
    }
    
    _newFolderURL = destURL;
    
    // If we made it this far, we're good
    [self completeSaving:YES];
}

- (BOOL) copyPresetFilesToNewDir:(NSURL *)url
{
    NSFileManager *fileMan = [NSFileManager defaultManager];
    
    //NSURL *oldPresetDir = [_folderURL URLByAppendingPathComponent:PRESET_FOLDER];
    NSURL *oldFuseDir = [_folderURL URLByAppendingPathComponent:FUSE_FOLDER];
    NSURL *newPresetDir = [url URLByAppendingPathComponent:PRESET_FOLDER];
    NSURL *newFuseDir = [url URLByAppendingPathComponent:FUSE_FOLDER];
    NSError *error = nil;
    
    if (error)
    {
        NSLog(@"*** ERROR: error saving fuse files");
        return NO;
    }
    
    error = nil;
    [fileMan createDirectoryAtURL:newPresetDir
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error];
    if (error)
    {
        return NO;
    }
    
    error = nil;
    [fileMan createDirectoryAtURL:newFuseDir
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error];
    if (error)
    {
        return NO;
    }
    
    for (int i = 0; i < _presets.count; i++)
    {
        MFPreset *cPreset = [_presets objectAtIndex:i];
        NSString *oldFilename = [cPreset.fileURL lastPathComponent];
        //NSLog(@"old fileName: %@", oldFilename);
        
        int oldIndex = [[oldFilename substringToIndex:2] intValue];
        int newIndex = i;
        //NSLog(@"    old: %d new: %d", oldIndex, newIndex);
        
        NSString *presetName = [oldFilename substringFromIndex:2];
        NSString *newFilename = [NSString stringWithFormat:@"%02d%@", newIndex, presetName];
        //NSLog(@"    newFilename: %@", newFilename);
        
        [fileMan copyItemAtPath:[cPreset.fileURL path]
                         toPath:[[newPresetDir path] stringByAppendingPathComponent:newFilename]
                          error:&error];
        
        // now move the item from the FUSE folder to it's new spot
        NSString *oldFuseFilename = [NSString stringWithFormat:@"%02d.fuse", oldIndex];
        NSString *newFuseFilename = [NSString stringWithFormat:@"%02d.fuse", newIndex];
        
        [fileMan copyItemAtPath:[[oldFuseDir path] stringByAppendingPathComponent:oldFuseFilename]
                         toPath:[[newFuseDir path] stringByAppendingPathComponent:newFuseFilename]
                          error:&error];
        
        if (error)
        {
            NSLog(@"*** ERROR: %@", error);
            return NO;
        }
    }
    
    return YES;
}

- (void) completeSaving:(BOOL)success
{
    if (_saveCompletionBlock)
        _saveCompletionBlock(success, _newFolderURL);
}


- (MFPreset *) presetForQASlot:(int)qaSlot
{
    int theIndex = [[self.quickAccessPresets objectAtIndex:qaSlot] intValue];
    MFPreset *preset = [self.presets objectAtIndex:theIndex];
    return preset;
}

- (void) setPreset:(MFPreset *)preset toQASlot:(int)qaSlot
{
    int index = [self indexForPreset:preset];
    [self.quickAccessPresets setObject:[NSNumber numberWithInt:index]
                    atIndexedSubscript:qaSlot];
}

- (int) indexForPreset:(MFPreset *)preset
{
    for (int i = 0; i < self.presets.count; i++)
    {
        MFPreset *cPreset = (MFPreset *)[self.presets objectAtIndex:i];
        if ([preset.uuid isEqualToString:cPreset.uuid])
        {
            return i;
        }
    }
    
    return -1;
}

- (NSString *) newUUID
{
    NSString *uuidString = nil;
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    if (uuid)
    {
        uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        CFRelease(uuid);
    }
    return uuidString;
}

@end
