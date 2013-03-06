//
//  MFQuickAccessView.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 3/5/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFQuickAccessView.h"
#import "MFFuseBackup.h"

@implementation MFQuickAccessView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code here.
        [self registerForDraggedTypes:[NSArray arrayWithObject:DropTypeMFPreset]];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pBoard = [sender draggingPasteboard];
    NSDragOperation dragOp = [sender draggingSourceOperationMask];
    
    if ([[pBoard types] containsObject:DropTypeMFPreset])
    {
        if (dragOp & NSDragOperationGeneric)
        {
            return NSDragOperationGeneric;
        }
    }
    
    return NSDragOperationNone;
}

- (BOOL) performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pBoard = [sender draggingPasteboard];
    
    if ([[pBoard types] containsObject:DropTypeMFPreset])
    {
        // accept the preset
        NSLog(@"preset accepted:");
    }
    
    return YES;
}

@end
