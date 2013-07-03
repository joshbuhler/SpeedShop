//
//  MFFuseBackup.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 3/2/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFFuseBackup.h"
#import "MFFuseBackup+MFFuseBackup_Private.h"
#import "MFFuseBackupMemento.h"
#import "MFFuseBackupHistory.h"

NSString *FUSE_FOLDER = @"FUSE";
NSString *PRESET_FOLDER = @"Presets";
NSString *BACKUP_FILENAME_GDEC = @"GD_BackupName.fuse";
NSString *BACKUP_FILENAME_MUSTANG = @"MU_BackupName.fuse";
NSString *BACKUP_FILENAME_MUSTANG_V2 = @"M2_BackupName.fuse";
NSString *SETTINGS_FILENAME = @"SystemSettings.fuse";

@interface MFFuseBackup()
{
    MFFuseBackupCompletion      _loadCompletionBlock;
    MFFuseBackupSaveCompletion  _saveCompletionBlock;
    MFFuseBackupHistory *_backupHistory;

    NSURL   *_newFolderURL;
    
    // Used for XML parsing
    NSMutableString *currentElementValue;
    NSMutableArray *_quickAccessPresets;
    NSMutableArray *_quickAccessPresetsUUID;

}

@property (nonatomic, strong) NSMutableArray *presets;

-(void)storeStateToMemento;
- (void) restoreStateFromMemento:(MFFuseBackupMemento *)memento;

@end

@implementation MFFuseBackup

- (id)init {
    self = [super init];
    if (self) {
        _isModified = NO;
        _backupHistory = [[MFFuseBackupHistory alloc] init];
    }
    return self;
}


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
    _quickAccessPresets = [[NSMutableArray alloc] init];
    _quickAccessPresetsUUID = [[NSMutableArray alloc] init];
    
    [self loadBackupContents];
    _isModified = NO;
    [_backupHistory removeAllObjects];
    [self storeStateToMemento];
}

// Saves to the existing location
- (void) saveWithCompletion:(MFFuseBackupSaveCompletion)block
{
    _saveCompletionBlock = block;

    [self saveToURL:self.folderURL];
    _isModified = NO;
    [_backupHistory removeAllObjects];
}

- (void) saveAsNewBackup:(NSURL *)url withCompletion:(MFFuseBackupSaveCompletion)block
{
    _saveCompletionBlock = block;

    // create a new folder at the specified path - filename must be a date, otherwise
    // FUSE won't see it
    NSDate *now = [NSDate date];
    NSDateFormatter *filenameFormat = [[NSDateFormatter alloc] init];
    [filenameFormat setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
    NSString *dateFileName = [filenameFormat stringFromDate:now];

    NSURL *destURL = [url URLByAppendingPathComponent:dateFileName];
    [self saveToURL:destURL];
    _isModified = NO;
    [_backupHistory removeAllObjects];
}

- (void)setBackupDescription:(NSString *)newBackupDescription {
    [self storeStateToMemento];
    _backupDescription = newBackupDescription;
    _isModified = YES;
}




#pragma mark - Private Preset Loading

- (BOOL) validateBackupContents
{
    // Simple check to make sure that everything we need is in it's place
    // We should have four items:
    // - "FUSE" folder
    // - "Presets" folder
    // - "MU_BackupName.fuse" or "M2_BackupName.fuse" or "GD_BackupName.fuse" file
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
        _ampSeries = AmpSeries_Mustang;
    }
    
    NSURL *backupFileMustang_V2 = [_folderURL URLByAppendingPathComponent:BACKUP_FILENAME_MUSTANG_V2];
    if ([fileMan fileExistsAtPath:[backupFileMustang_V2 path]] == YES)
    {
        backupFileFound = YES;
        _ampSeries = AmpSeries_Mustang_V2;
    }
    
    NSURL *backupFileGDec = [_folderURL URLByAppendingPathComponent:BACKUP_FILENAME_GDEC];
    if ([fileMan fileExistsAtPath:[backupFileGDec path]] == YES)
    {
        backupFileFound = YES;
        _ampSeries = AmpSeries_GDec;
    }
    
    if (!backupFileFound)
        return NO;
    
    // Look for a settings file if it's a Mustang series
    if (_ampSeries == AmpSeries_Mustang || _ampSeries == AmpSeries_Mustang_V2)
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
    NSString *fileName = nil;
    if (_ampSeries == AmpSeries_Mustang)
        fileName = BACKUP_FILENAME_MUSTANG;
    
    if (_ampSeries == AmpSeries_Mustang_V2)
        fileName = BACKUP_FILENAME_MUSTANG_V2;
    
    if (_ampSeries == AmpSeries_GDec)
        fileName = BACKUP_FILENAME_GDEC;
    
    NSURL *backupFile = [_folderURL URLByAppendingPathComponent:fileName];
    
    NSData *data = [NSData dataWithContentsOfURL:backupFile];
    NSString *desc = [[NSString alloc] initWithBytes:[data bytes]
                                              length:[data length]
                                            encoding:NSUTF8StringEncoding];
    
    self.backupDescription = desc;    
}

- (void) loadAmpSettings
{
    if (_ampSeries == AmpSeries_GDec)
        return;
    
    NSURL *settingsFile = [_folderURL URLByAppendingPathComponent:SETTINGS_FILENAME];
    
    NSXMLParser *cParser = [[NSXMLParser alloc] initWithContentsOfURL:settingsFile];
    
    currentElementValue = nil;
    _quickAccessPresets = [[NSMutableArray alloc] init];
    _quickAccessPresetsUUID = [[NSMutableArray alloc] init];
    
    cParser.delegate = self;
    [cParser setShouldResolveExternalEntities:YES];
    [cParser parse];
}

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

        if (![[cURL pathExtension] isEqualToString:@"fuse"]) {
            continue;
        }

        MFPreset *cPreset = [[MFPreset alloc] init];

        cPreset.backup = self;
        cPreset.uuid = [self newUUID];

        [cPreset loadPresetFile:cURL];

        [self.presets addObject:cPreset];
    }

    // after loading all presets we can remember the UUIDs of the quick access presets
    for (int j = 0; j < _quickAccessPresets.count; j++)
    {
        int presetNumber = [[_quickAccessPresets objectAtIndex:j] intValue];
        NSString *qaUUID = ((MFPreset*)[self.presets objectAtIndex:presetNumber]).uuid;
        [_quickAccessPresetsUUID addObject:qaUUID];
    }

    [self completeLoading:YES];
}

- (void) completeLoading:(BOOL)success
{
    if (_loadCompletionBlock)
        _loadCompletionBlock(success);
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


#pragma mark - Private Exporting / Saving
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
    NSString *backupFileName = nil;
    if (_ampSeries == AmpSeries_Mustang)
        backupFileName = BACKUP_FILENAME_MUSTANG;
    
    if (_ampSeries == AmpSeries_Mustang_V2)
        backupFileName = BACKUP_FILENAME_MUSTANG_V2;

    if (_ampSeries == AmpSeries_GDec)
        backupFileName = BACKUP_FILENAME_GDEC;
    
    [self.backupDescription writeToURL:[tempDir URLByAppendingPathComponent:backupFileName]
                            atomically:YES
                              encoding:NSUTF8StringEncoding
                                 error:&error];
    
    if (error)
    {
        [self completeSaving:NO];
        return;
    }
    
    // Saving of the settings file
    if (_ampSeries == AmpSeries_Mustang || _ampSeries == AmpSeries_Mustang_V2)
    {
        NSURL *settingsFile = [_folderURL URLByAppendingPathComponent:SETTINGS_FILENAME];
        NSXMLDocument *settingsXML = [[NSXMLDocument alloc] initWithContentsOfURL:settingsFile
                                                                          options:NSXMLDocumentTidyXML
                                                                            error:&error];
        
        NSXMLElement *docRoot = [settingsXML rootElement];
        // replace the first three QA nodes
        MFPreset *preset1 = [self presetForQASlot:0];
        int index1 = [self indexForPreset:preset1];
        NSXMLElement *qa1 = [NSXMLElement elementWithName:@"QA" stringValue:[NSString stringWithFormat:@"%d", index1]];
        [docRoot replaceChildAtIndex:0 withNode:qa1];
        
        MFPreset *preset2 = [self presetForQASlot:1];
        int index2 = [self indexForPreset:preset2];
        NSXMLElement *qa2 = [NSXMLElement elementWithName:@"QA" stringValue:[NSString stringWithFormat:@"%d", index2]];
        [docRoot replaceChildAtIndex:1 withNode:qa2];
        
        MFPreset *preset3 = [self presetForQASlot:2];
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
    }
    
    
    
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


#pragma mark - Other Private Stuff

// Get the preset for a QA slot, identified by the preset's UUID
- (MFPreset *)presetForQASlot:(int)qaSlot
{
    NSString* qaPresetUUID = [_quickAccessPresetsUUID objectAtIndex:qaSlot];
    
    for (int i = 0; i < self.presets.count; i++)
    {
        MFPreset *cPreset = (MFPreset *)[self.presets objectAtIndex:i];
        if ([qaPresetUUID isEqualToString:cPreset.uuid])
            return cPreset;
    }
    
    return nil;
}


// Set the preset for a QA slot, linking is done via the preset's UUID
- (void) setPreset:(MFPreset *)preset toQASlot:(int)qaSlot
{
    // No change. This preset is already in this QA slot
    if ([[_quickAccessPresetsUUID objectAtIndex:qaSlot] isEqualToString:[preset uuid]])
        return;

    [_quickAccessPresetsUUID setObject:[preset uuid]
                    atIndexedSubscript:qaSlot];

    MFPreset *qaPreset = [self presetForQASlot:qaSlot];
    NSUInteger qaPresetIndex = [_presets indexOfObject:qaPreset];
    NSString *qaPresetIndexString = [[NSString alloc] initWithFormat:@"%lu", qaPresetIndex];
    [_quickAccessPresets setObject:qaPresetIndexString
                    atIndexedSubscript:qaSlot];

    [self storeStateToMemento];
    _isModified = YES;
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


#pragma mark - Presets Access Methods
- (NSUInteger)presetsCount {
    return _presets.count;
}

- (MFPreset *)presetsObjectAtIndex:(NSUInteger)anIndex {
    return [_presets objectAtIndex:anIndex];
}

- (void)presetsRemoveObjectsInArray:(NSArray *)anOtherArray {
    [_presets removeObjectsInArray:anOtherArray];
    _isModified = YES;
}

- (void)presetsInsertObjects:(NSArray *)anOtherArray atIndexes:(NSIndexSet *)anIndexSet {
    [_presets insertObjects:anOtherArray atIndexes:anIndexSet];
    [self storeStateToMemento];
    _isModified = YES;
}



#pragma mark - Undo/Redo Methods
- (void)storeStateToMemento {
    if ([_presets count] == 0)
        return;

    MFFuseBackupMemento * memento = [[MFFuseBackupMemento alloc] initWithBackupState:_presets
                                                                           qaPresets:_quickAccessPresets
                                                                       qaPresetsUUID:_quickAccessPresetsUUID
                                                                   backupDescription:_backupDescription ];
    [_backupHistory addObject:memento];
}


- (void) restoreStateFromMemento:(MFFuseBackupMemento *)memento {
    if (memento){
        _presets = [[NSMutableArray alloc] initWithArray:memento.presets];
        _quickAccessPresets = [[NSMutableArray alloc] initWithArray:memento.quickAccessPresets];
        _quickAccessPresetsUUID = [[NSMutableArray alloc] initWithArray:memento.quickAccessPresetsUUID];
        _backupDescription = [[NSString alloc] initWithString:memento.backupDescription];
    }
}


- (void)performUndo {
    MFFuseBackupMemento * memento = [_backupHistory undo];
    if (memento)
        [self restoreStateFromMemento:memento];
}

- (void)performRedo {
    MFFuseBackupMemento * memento = [_backupHistory redo];
    if (memento)
        [self restoreStateFromMemento:memento];
}

- (BOOL)isUndoable {
    return [_backupHistory isUndoable];
}

- (BOOL)isRedoable {
    return [_backupHistory isRedoable];
}

// we need this for small backupDescription changes
// which should not go to the undo history and thus
// are not yet propagated to this class
- (void)forceModifiedYes {
    _isModified = YES;
}


@end
