//
//  MFFuseBackup.h
//  Horse Whisperer
//
//  Created by Josh Buhler on 3/2/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFPreset.h"

typedef void (^MFFuseBackupCompletion)(BOOL);

@interface MFFuseBackup : NSObject
{
    MFFuseBackupCompletion  _completionBlock;
}

@property (nonatomic, strong) NSURL *folderURL;
@property (nonatomic, strong) NSString *backupDescription;

@property (nonatomic, strong) NSMutableArray *presets;

- (void) loadBackup:(NSURL *)url withCompletion:(MFFuseBackupCompletion)block;

@end
