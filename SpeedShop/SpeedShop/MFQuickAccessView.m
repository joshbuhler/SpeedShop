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

@synthesize preset = _preset;
@synthesize presetLabel;
@synthesize canAcceptDrag;
@synthesize view;
@synthesize delegate;

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

- (void) setPreset:(MFPreset *)preset
{
    _preset = preset;
    
    [self refreshUI];
}

- (void) refreshUI
{
    NSString *presetName = @"";
    if (_preset)
        presetName = _preset.name;
        
    [self.presetLabel setStringValue:presetName];
}


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pBoard = [sender draggingPasteboard];
    NSDragOperation dragOp = [sender draggingSourceOperationMask];
    
    if ([[pBoard types] containsObject:DropTypeMFPreset] && canAcceptDrag)
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
        
        MFPreset *thePreset = [dragData objectForKey:@"preset"];
        self.preset = thePreset;
        [presetLabel setStringValue:thePreset.name];
        
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
