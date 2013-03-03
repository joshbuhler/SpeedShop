//
//  MFFuseBackup.h
//  Horse Whisperer
//
//  Created by Josh Buhler on 3/2/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFFuseBackup : NSObject

@property (nonatomic, strong) NSURL *folderURL;
@property (nonatomic, strong) NSString *backupDescription;

@property (nonatomic, strong) NSMutableArray *presets;

+ (MFFuseBackup *) backupFromFolder:(NSURL *)url;

- (id) initWithBackupFolder:(NSURL *)url;

@end
