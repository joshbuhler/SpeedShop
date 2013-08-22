//
// Created by Wolfram Esser on 01.07.13.
// Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFPreset.h"
#import "MFFuseBackupMemento.h"


@implementation MFFuseBackupMemento {

}

- (id)initWithBackupState:(NSArray *)presets
                qaPresets:(NSArray *)qaPresets
            qaPresetsUUID:(NSArray *)qaPresetsUUID
        backupDescription:(NSString *)aDescription
{
    self = [super init];
    if (self) {
        _backupDescription = [[NSString alloc] initWithString:aDescription];

        // perform deep copy of presets array, as names of presets may have been edited
        _presets = [NSKeyedUnarchiver unarchiveObjectWithData: [NSKeyedArchiver archivedDataWithRootObject: presets]];
        _quickAccessPresets = [[NSMutableArray alloc] initWithArray:qaPresets];
        _quickAccessPresetsUUID = [[NSMutableArray alloc] initWithArray:qaPresetsUUID];
    }
    return self;
}

-(NSString *) description
{
    NSMutableString * desc = [[NSMutableString alloc] initWithString:@"Memento: "];
    [desc appendFormat:@"00:%@ ", [_presets objectAtIndex:0]];
    NSUInteger qa0id = (NSUInteger) [[_quickAccessPresets objectAtIndex:0] intValue];
    MFPreset *mfp = [_presets objectAtIndex:qa0id];
    [desc appendFormat:@"QA0:%@ ", mfp];

    return desc;
}



@end