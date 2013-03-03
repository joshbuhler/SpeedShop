//
//  Horse_WhispererTests.m
//  Horse WhispererTests
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "Horse_WhispererTests.h"
#import "MFFuseBackup.h"
#import "MFFuseBackup+MFFuseBackup_Private.h"

@interface Horse_WhispererTests()
{
    NSURL *sampleBackupDir;
    NSURL *fuse270dir;
}

@end

@implementation Horse_WhispererTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    sampleBackupDir = [[NSBundle mainBundle] URLForResource:@"SampleBackups" withExtension:nil];
    
    fuse270dir = [sampleBackupDir URLByAppendingPathComponent:@"Mustang3_Fuse270/2013_02_27_21_09_59/"];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void) testSampleExistence
{
    NSFileManager *fileMan = [NSFileManager defaultManager];
    STAssertTrue([fileMan fileExistsAtPath:[fuse270dir path]], @"Sample backup not found - fuse270");
}

- (void) testBackupLoad
{
    MFFuseBackup *backup = [[MFFuseBackup alloc] init];
    [backup loadBackup:fuse270dir withCompletion:^(BOOL success) {
        STAssertTrue(success, @"Failed to load backup");
        
        STAssertTrue([backup.backupDescription isEqualToString:@"TestBackup - Mustang 3 - Fuse 2.7"], @"Failed to load backup name");
        
        STAssertTrue([backup.presets count] == 100, @"Failed to find 100 presets");
    }];
}

- (void) testBackupValidation
{
    MFFuseBackup *backup = [[MFFuseBackup alloc] init];
    backup.folderURL = fuse270dir;
    STAssertTrue([backup validateBackupContents], @"Validation of sample contents failed.");
}


@end
