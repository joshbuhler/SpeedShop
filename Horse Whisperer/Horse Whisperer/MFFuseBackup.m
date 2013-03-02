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

- (id) initWithBackupFolder:(NSURL *)url
{
    NSAssert(url != nil, @"URL must be supplied to init method.");
    
    self = [super init];
    
    self.folderURL = url;
    
    if (![self validateBackupContents])
        return nil;
    
    [self loadBackupContents];
    
    return self;
}


+ (MFFuseBackup *) backupFromFolder:(NSURL *)url
{
    MFFuseBackup *newBackup = [[MFFuseBackup alloc] initWithBackupFolder:url];
    
    return newBackup;
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
    if ([fuseContents count] <= 0)
        return NO;
    
    // now the Presets directory
    NSURL *presetDir = [_folderURL URLByAppendingPathComponent:PRESET_FOLDER];
    if ([fileMan fileExistsAtPath:[presetDir path]] == NO)
        return NO;
    
    NSArray *presetContents = [fileMan contentsOfDirectoryAtPath:[presetDir path] error:&error];
    if ([presetContents count] <= 0)
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

@end
