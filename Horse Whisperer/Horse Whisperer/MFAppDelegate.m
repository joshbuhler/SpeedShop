//
//  MFAppDelegate.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFAppDelegate.h"

@interface MFAppDelegate()

@property (nonatomic, strong) NSMutableArray *ampPresets;

@end


NSString *PresetDropType = @"presetDropType";

@implementation MFAppDelegate

@synthesize ampPresets = _ampPresets;


#pragma mark - View LifeCycle

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // init drag/drop for the tableview
    [_ampPresetTable registerForDraggedTypes:[NSArray arrayWithObject:PresetDropType]];
    
    
    // build some junk data for now
    _ampPresets = [NSMutableArray new];
    for (int i = 0; i < 100; i++)
    {
        [_ampPresets addObject:[NSString stringWithFormat:@"Preset %02d", i]];
    }
}

#pragma mark - Tableview Delegate Methods

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger count = 0;
    
    if (_ampPresets)
        count = _ampPresets.count;
    
    return count;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id returnValue = nil;
    
    NSString *columnID = [tableColumn identifier];
    
    NSString *presetName = [_ampPresets objectAtIndex:row];
    
    if ([columnID isEqualToString:@"presetIndex"])
    {
        returnValue = [NSString stringWithFormat:@"%02ld", row];
    }
    
    if ([columnID isEqualToString:@"presetName"])
    {
        returnValue = presetName;
    }
    
    return returnValue;
}

- (BOOL) tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:PresetDropType] owner:self];
    [pboard setData:data forType:PresetDropType];
    
    return YES;
}

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if ([info draggingSource] == self.ampPresetTable)
    {
        if (dropOperation == NSTableViewDropOn)
        {
            [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
            return NSDragOperationMove;
        }
        else
        {
            return NSDragOperationNone;
        }
    }
    
    return NSDragOperationNone;
}

- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pBoard = [info draggingPasteboard];
    NSData *rowData = [pBoard dataForType:PresetDropType];
    NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    
    //NSArray *allItemsArray = self.ampPresets;
    NSMutableArray *draggedItemsArray = [[NSMutableArray alloc] init];
    
    NSUInteger currentItemIndex;
    NSRange range = NSMakeRange(0, [rowIndexes lastIndex] + 1);
     
    while ([rowIndexes getIndexes:&currentItemIndex maxCount:1 inIndexRange:&range] > 0)
    {
        NSObject *cItem = [self.ampPresets objectAtIndex:currentItemIndex];
        NSLog(@"cItem: %@", cItem);
        [draggedItemsArray addObject:cItem];
        //NSLog(@"obj: %@", [draggedItemsArray objectAtIndex:0]);
    }
    
    int count;
    for (count = 0; count < [draggedItemsArray count]; count++)
    {
        NSObject *cItem = [draggedItemsArray objectAtIndex:count];
        // set new index for cItem
    }
    
    int tempRow;
    if (row == 0)
    {
        tempRow = -1;
    }
    else
    {
        tempRow = row;
    }
    
    //NSArray *startItemsArray = [self itemsWith]

    return YES;
}


#pragma mark - UI Actions
- (IBAction)onReloadBtn:(id)sender
{
    [self.ampPresetTable reloadData];
}
@end
