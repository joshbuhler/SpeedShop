//
//  MFFuseBackup.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 3/2/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFFuseBackup.h"

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


- (BOOL) validateBackupContents
{
    
    
    
    return YES;
}


@end
