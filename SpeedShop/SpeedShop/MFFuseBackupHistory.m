//
// Created by Wolfram Esser on 01.07.13.
// Copyright (c) 2013 Joshua Buhler. All rights reserved.
//


#import "MFPreset.h"
#import "MFFuseBackupMemento.h"
#import "MFFuseBackupHistory.h"


@interface MFFuseBackupHistory() {

    NSUInteger _cursor;    // points to current state in the app. Can be moved by user via Undo/Redo actions
}

@property (nonatomic, strong) NSMutableArray * history;

@end



@implementation MFFuseBackupHistory {

}

- (id)init {
    self = [super init];
    if (self) {
        _cursor = (NSUInteger) -1;   // no current state
        _history = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)isUndoable {
    if ([self.history count] > 1 && _cursor >= 1){
        return YES;
    }
    return NO;
}

- (BOOL)isRedoable {
    if ([self.history count] > 1 && _cursor < [self.history count]-1) {
        return YES;
    }
    return NO;
}

- (MFFuseBackupMemento *)undo {
    if ([self isUndoable]) {
        _cursor--;
        MFFuseBackupMemento *memento = [self.history objectAtIndex:_cursor];
        return memento;
    }
    return nil;
}

- (MFFuseBackupMemento *)redo {
    if ([self isRedoable]) {
        _cursor++;
        MFFuseBackupMemento * memento = [self.history objectAtIndex:_cursor];
        return memento;
    }
    return nil;
}


- (void)addObject:(MFFuseBackupMemento *)aMemento {
    // A new snapshot arrives, but we are not pointing to the last snapshot
    // (user did some undo, and then continued editing)
    if (_cursor < (int)[self.history count] -1)
        // So, we have to remove all future mementos from the history
        [self.history removeObjectsInRange: NSMakeRange(_cursor+1, [self.history count]-_cursor-1)];

    [self.history addObject:aMemento];
    _cursor = [self.history count] -1;
}

- (void)removeAllObjects {
    [self.history removeAllObjects];
    _cursor = (NSUInteger) -1;
}

@end
