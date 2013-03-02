//
//  MFFuseBackup.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 3/2/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFFuseBackup.h"
#import "MFFuseBackup+MFFuseBackup_Private.h"

@implementation MFFuseBackup

@synthesize folderURL = _folderURL;

- (id) initWithBackupFolder:(NSURL *)url
{
    NSAssert(url != nil, @"URL must be supplied to init method.");
    
    self = [super init];
    
    self.folderURL = url;
    
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
    
    
    
    return YES;
}


@end
