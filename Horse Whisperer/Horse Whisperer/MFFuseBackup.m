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
NSString *PRESET_FOLDER = @"PRESETS";
NSString *BACKUP_FILENAME = @"MU_BackupName.fuse";
NSString *SETTINGS_FILENAME = @"SystemSettings.fuse";

@implementation MFFuseBackup

@synthesize folderURL = _folderURL;
@synthesize presets = _presets;

- (void) loadBackup:(NSURL *)url withCompletion:(MFFuseBackupCompletion)block
{
    self.folderURL = url;
    
    if (![self validateBackupContents])
        return;
    
    _completionBlock = block;
    
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
    [self loadFuseFiles];
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

// Loads FUSE folder contents to get an overview of the preset files. Grabs the
// basic detail info. If more detailed preset info is needed, then that will be
// loaded from the Presets folder as needed.
- (void) loadFuseFiles
{
    NSFileManager *fileMan = [NSFileManager defaultManager];
    
    NSURL *presetDir = [_folderURL URLByAppendingPathComponent:FUSE_FOLDER];
    NSError *error = nil;
    NSArray *presetContents = [fileMan contentsOfDirectoryAtPath:[presetDir path] error:&error];
    
    if (error)
    {
        NSLog(@"*** ERROR: error loading fuse files");
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

    if (_completionBlock)
    {
        _completionBlock(YES);
    }
}

@end
