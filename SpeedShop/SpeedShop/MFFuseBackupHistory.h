//
// Created by Wolfram Esser on 01.07.13.
// Copyright (c) 2013 Joshua Buhler. All rights reserved.
//
// Holds a private list of MFBackupMemento objects with backup snapshots
// a lower index in the array means a more past app state
// a higher index means a more recent app state


#import <Foundation/Foundation.h>


@interface MFFuseBackupHistory : NSObject
- (id) init;

- (BOOL)isUndoable;
- (BOOL)isRedoable;

- (MFFuseBackupMemento *)undo;
- (MFFuseBackupMemento *)redo;

- (void)addObject:(MFFuseBackupMemento *)aMemento;
- (void) removeAllObjects;
@end