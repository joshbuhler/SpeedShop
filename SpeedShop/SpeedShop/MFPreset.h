//
//  MFPreset.h
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MFFuseBackup;

extern NSString *const DropTypeMFPreset;

@interface MFPreset : NSObject <NSCoding, NSXMLParserDelegate>

@property (nonatomic, strong) MFFuseBackup *backup;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *description;

// For tracking a preset as it moves around. Odds are good that we'll have name
// overlaps, so comparing a preset name is no good. When a preset is loaded
// with the backup, we'll generate a uuid to save with the preset.
@property (nonatomic, strong) NSString *uuid;

- (void) loadPresetFile:(NSURL *)url;

- (NSURL *) fileURL;

@end
