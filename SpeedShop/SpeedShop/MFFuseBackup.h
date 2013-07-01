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

typedef enum
{
    AmpSeries_Mustang,
    AmpSeries_GDec,
    AmpSeries_Mustang_V2
} AmpSeries;

@interface MFFuseBackup : NSObject <NSXMLParserDelegate>

@property (nonatomic, strong) NSURL *folderURL;
@property (nonatomic, strong) NSString *backupDescription;
@property (nonatomic, readonly) BOOL isModified;

@property (nonatomic, readonly) AmpSeries ampSeries;

- (void) loadBackup:(NSURL *)url withCompletion:(MFFuseBackupCompletion)block;
- (void) saveWithCompletion:(MFFuseBackupSaveCompletion)block;
- (void) saveAsNewBackup:(NSURL *)url withCompletion:(MFFuseBackupSaveCompletion)block;
- (void) setBackupDescription:(NSString *)newBackupDescription;

- (MFPreset *)presetForQASlot:(int)qaSlot;
- (void) setPreset:(MFPreset *)preset toQASlot:(int)qaSlot;
- (id) init;

- (NSUInteger)presetsCount;
- (MFPreset *)presetsObjectAtIndex:(NSUInteger) anIndex;
- (void)presetsRemoveObjectsInArray:(NSArray *)anOtherArray;
- (void)presetsInsertObjects:(NSArray *)anOtherArray atIndexes:(NSIndexSet *)anIndexSet;

@end
