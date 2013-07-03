//
// Created by Wolfram Esser on 01.07.13.
// Copyright (c) 2013 Joshua Buhler. All rights reserved.
//
// The MFFuseBackupMemento holds a single time snapshot of the edited backup.
// These mementos are stored in the MFFuseBackupHistory to enable undo/redo
//


#import <Foundation/Foundation.h>


@interface MFFuseBackupMemento : NSObject
{
}

-(NSString *) description;

- (id)initWithBackupState:(NSArray *)presets
                qaPresets:(NSArray *)qaPresets
            qaPresetsUUID:(NSArray *)qaPresetsUUID
        backupDescription:(NSString *)aDescription;

@property (nonatomic, strong, readonly) NSString *backupDescription;
@property (nonatomic, strong, readonly) NSMutableArray *presets;
@property (nonatomic, strong, readonly) NSMutableArray *quickAccessPresets;
@property (nonatomic, strong, readonly) NSMutableArray *quickAccessPresetsUUID;

@end