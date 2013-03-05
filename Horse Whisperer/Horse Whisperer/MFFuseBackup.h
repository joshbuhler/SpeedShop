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
typedef void (^MFFuseBackupSaveCompletion)(BOOL, NSURL*);

@interface MFFuseBackup : NSObject

@property (nonatomic, strong) NSURL *folderURL;
@property (nonatomic, strong) NSString *backupDescription;

@property (nonatomic, strong) NSMutableArray *presets;

- (void) loadBackup:(NSURL *)url withCompletion:(MFFuseBackupCompletion)block;
- (void) saveWithCompletion:(MFFuseBackupSaveCompletion)block;
- (void) saveAsNewBackup:(NSURL *)url withCompletion:(MFFuseBackupSaveCompletion)block;

@end
