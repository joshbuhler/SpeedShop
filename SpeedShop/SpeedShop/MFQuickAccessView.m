//
//  MFQuickAccessView.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 3/5/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFQuickAccessView.h"

@interface MFQuickAccessView()

@property (nonatomic, strong) IBOutlet NSTextField *presetLabel;
@property (nonatomic, strong) IBOutlet NSView *view;

@end

@implementation MFQuickAccessView
    MFPreset * _preset;
    int _ampIndex;      // the global (00-99) index where the current QA preset is stored on the amp


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code here.
        [self registerForDraggedTypes:[NSArray arrayWithObject:DropTypeMFPreset]];
        
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"MFQuickAccessView"
                                              bundle:[NSBundle mainBundle]];
        [nib instantiateNibWithOwner:self
                     topLevelObjects:nil];
                      
        [self addSubview:self.view];
        
        self.canAcceptDrag = YES;
        
        self.presetLabel.font = [NSFont fontWithName:@"Open Sans Light" size:14.0f];
    }
    
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self addSubview:self.view];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}


- (MFPreset *) preset
{
    return _preset;
}


- (void)setPreset:(MFPreset *)newPreset fromAmpIndex:(int) newAmpIndex
{
    _preset = newPreset;
    _ampIndex = newAmpIndex;
    
    [self refreshUI];
}

- (void) refreshUI
{
    if (_preset)
        [_presetLabel setStringValue:[NSString stringWithFormat:@"[%02d]\n%@", _ampIndex, _preset.name]];
}


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pBoard = [sender draggingPasteboard];
    NSDragOperation dragOp = [sender draggingSourceOperationMask];
    
    if ([[pBoard types] containsObject:DropTypeMFPreset] && _canAcceptDrag)
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
        NSData *rowData = [pBoard dataForType:DropTypeMFPreset];
        NSMutableDictionary *dragData = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
        
        _preset = [dragData objectForKey:@"preset"];
        NSIndexSet * theIndexes = [dragData objectForKey:@"rowIndexes"];
        _ampIndex = theIndexes.firstIndex;

        if (self.delegate)
        {
            if ([self.delegate respondsToSelector:@selector(presetDidChangeForQAView:)])
            {
                [self.delegate presetDidChangeForQAView:self];
            }
        }
    }
    
    return YES;
}



@end
