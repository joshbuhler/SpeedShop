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
NSString *BACKUP_FILENAME = @"MU_BackupName.fuse";
NSString *SETTINGS_FILENAME = @"SystemSettings.fuse";

@implementation MFFuseBackup

@synthesize folderURL = _folderURL;
@synthesize presets = _presets;

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
    
    [self loadBackupContents];
}


#pragma mark - Private Methods

- (BOOL) validateBackupContents
{
    // Simple check to make sure that everything we need is in it's place
    // We should have four items:
    // - "FUSE" folder
    // - "Presets" folder
    // - "MU_BackupName.fuse" file
    // - "SystemSettings.fuse" file
    
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
    
    NSURL *backupFile = [_folderURL URLByAppendingPathComponent:BACKUP_FILENAME];
    if ([fileMan fileExistsAtPath:[backupFile path]] == NO)
        return NO;
    
    NSURL *settingsFile = [_folderURL URLByAppendingPathComponent:SETTINGS_FILENAME];
    if ([fileMan fileExistsAtPath:[settingsFile path]] == NO)
        return NO;
    
    
    // Looks like on the surface everything is cool to begin parsing
    return YES;
}

- (void) loadBackupContents
{
    [self loadBackupDescription];
    
    // TODO: delegate progress method for loading status (we do have to analyze 99 files, after all)
    [self loadPresetFiles];
}

- (void) loadBackupDescription
{
    NSURL *backupFile = [_folderURL URLByAppendingPathComponent:BACKUP_FILENAME];
    
    NSData *data = [NSData dataWithContentsOfURL:backupFile];
    NSString *desc = [[NSString alloc] initWithBytes:[data bytes]
                                              length:[data length]
                                            encoding:NSUTF8StringEncoding];
    
    self.backupDescription = desc;    
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
        NSLog(@"fileName: %@", [presetContents objectAtIndex:i]);
        
        NSURL *cURL = [presetDir URLByAppendingPathComponent:[presetContents objectAtIndex:i]];
        MFPreset *cPreset = [[MFPreset alloc] init];
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
- (void) saveBackup:(NSURL *)url withCompletion:(MFFuseBackupCompletion)block
{
    _saveCompletionBlock = block;
    
    NSFileManager *fileMan = [NSFileManager defaultManager];
    
    // create a new folder at the specified path
    NSError *error = nil;
    [fileMan createDirectoryAtURL:url
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error];
    if (error)
    {
        [self completeSaving:NO];
        return;
    }
    
    // now copy over the settings & description files
    NSURL *backupFile = [_folderURL URLByAppendingPathComponent:BACKUP_FILENAME];
    [fileMan copyItemAtPath:[backupFile path]
                     toPath:[[url path] stringByAppendingPathComponent:BACKUP_FILENAME]
                      error:&error];
    
    if (error)
    {
        [self completeSaving:NO];
        return;
    }
    
    
    NSURL *settingsFile = [_folderURL URLByAppendingPathComponent:SETTINGS_FILENAME];
    [fileMan copyItemAtPath:[settingsFile path]
                     toPath:[[url path] stringByAppendingPathComponent:SETTINGS_FILENAME]
                      error:&error];
    
    if (error)
    {
        [self completeSaving:NO];
        return;
    }
    
    // now rename and copy over the items in the Presets folder based on their new order
    [self copyPresetFilesToNewDir:url];
    
    [self completeSaving:YES];
}

- (void) copyPresetFilesToNewDir:(NSURL *)url
{
    NSFileManager *fileMan = [NSFileManager defaultManager];
    
    NSURL *oldPresetDir = [_folderURL URLByAppendingPathComponent:PRESET_FOLDER];
    NSURL *newPresetDir = [url URLByAppendingPathComponent:PRESET_FOLDER];
    NSError *error = nil;
    NSArray *presetContents = [fileMan contentsOfDirectoryAtPath:[oldPresetDir path] error:&error];
    
    if (error)
    {
        NSLog(@"*** ERROR: error saving fuse files");
        [self completeSaving:NO];
        return;
    }
    
    error = nil;
    [fileMan createDirectoryAtURL:newPresetDir
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error];
    if (error)
    {
        [self completeSaving:NO];
        return;
    }
    
    for (int i = 0; i < _presets.count; i++)
    {
        MFPreset *cPreset = [_presets objectAtIndex:i];
        NSString *oldFilename = [cPreset.fileURL lastPathComponent];
        NSLog(@"old fileName: %@", oldFilename);
        
        int oldIndex = [[oldFilename substringToIndex:2] intValue];
        int newIndex = i;
        NSLog(@"    old: %d new: %d", oldIndex, newIndex);
        
        NSString *presetName = [oldFilename substringFromIndex:2];
        NSString *newFilename = [NSString stringWithFormat:@"%02d%@", newIndex, presetName];
        NSLog(@"    newFilename: %@", newFilename);
        
        [fileMan copyItemAtPath:[cPreset.fileURL path]
                         toPath:[[newPresetDir path] stringByAppendingPathComponent:newFilename]
                          error:&error];
    }
    
    /*
    for (int i = 0; i < presetContents.count; i++)
    {
        NSString *oldFilename = [presetContents objectAtIndex:i];
        NSLog(@"old fileName: %@", oldFilename);
        
        int oldIndex = [[oldFilename substringToIndex:2] intValue];
        int newIndex = i;
        NSLog(@"old: %d new: %d", oldIndex, newIndex);
    }
     */
}

- (void) completeSaving:(BOOL)success
{
    if (_saveCompletionBlock)
        _saveCompletionBlock(success);
}

@end
