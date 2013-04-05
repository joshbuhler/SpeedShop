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
    NSURL *gdec30dir;
}

@end

@implementation Horse_WhispererTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    sampleBackupDir = [[NSBundle mainBundle] URLForResource:@"SampleBackups" withExtension:nil];
    
    fuse270dir = [sampleBackupDir URLByAppendingPathComponent:@"Mustang3_Fuse270/2013_02_27_21_09_59/"];
    gdec30dir = [sampleBackupDir URLByAppendingPathComponent:@"GDEC_30/2013_02_17_19_24_50/"];
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
    STAssertTrue([fileMan fileExistsAtPath:[gdec30dir path]], @"Sample backup not found - G-Dec 30");
}

- (void) testMustangLoad
{
    MFFuseBackup *backup = [[MFFuseBackup alloc] init];
    [backup loadBackup:fuse270dir withCompletion:^(BOOL success) {
        STAssertTrue(success, @"Failed to load backup");
        
        STAssertTrue([backup.backupDescription isEqualToString:@"TestBackup - Mustang 3 - Fuse 2.7"], @"Failed to load backup name");
        
        STAssertTrue([backup.presets count] == 100, @"Failed to find 100 presets");
    }];
}

- (void) testGDecLoad
{
    MFFuseBackup *backup = [[MFFuseBackup alloc] init];
    [backup loadBackup:gdec30dir withCompletion:^(BOOL success) {
        STAssertTrue(success, @"Failed to load backup");
        
        STAssertTrue([backup.backupDescription isEqualToString:@"Now with sorted Blues goodness!"], @"Failed to load backup name");
        
        STAssertTrue([backup.presets count] == 100, @"Failed to find 100 presets");
    }];
}

- (void) testBackupValidation
{
    MFFuseBackup *mustangBackup = [[MFFuseBackup alloc] init];
    mustangBackup.folderURL = fuse270dir;
    STAssertTrue([mustangBackup validateBackupContents], @"Validation of sample contents failed - Mustang");
    
    MFFuseBackup *gDecBackup = [[MFFuseBackup alloc] init];
    gDecBackup.folderURL = gdec30dir;
    STAssertTrue([gDecBackup validateBackupContents], @"Validation of sample contents failed - G-DEC");
}


@end
