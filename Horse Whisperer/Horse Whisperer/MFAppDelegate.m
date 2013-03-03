//
//  MFAppDelegate.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import "MFAppDelegate.h"
#import "MFFuseBackup.h"

@interface MFAppDelegate()

@property (nonatomic, strong) NSMutableArray *ampPresets;
@property (nonatomic, strong) MFFuseBackup *currentBackup;

@end


NSString *PresetDropType = @"presetDropType";

@implementation MFAppDelegate

@synthesize ampPresets = _ampPresets;
@synthesize currentBackup = _currentBackup;

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

#pragma mark - File Loading


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
    
    NSMutableArray *draggedItemsArray = [[NSMutableArray alloc] init];
    
    NSUInteger currentItemIndex;
    NSRange range = NSMakeRange(0, [rowIndexes lastIndex] + 1);
     
    while ([rowIndexes getIndexes:&currentItemIndex maxCount:1 inIndexRange:&range] > 0)
    {
        NSObject *cItem = [self.ampPresets objectAtIndex:currentItemIndex];
        NSLog(@"cItem: %@", cItem);
        [draggedItemsArray addObject:cItem];
    }
    
    // remove the items from the preset list
    [_ampPresets removeObjectsInArray:draggedItemsArray];
    
    // now put them in their new location
    NSIndexSet *newIndexes = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(row, draggedItemsArray.count)];
    [_ampPresets insertObjects:draggedItemsArray atIndexes:newIndexes];
        
    [self.ampPresetTable reloadData];

    return YES;
}


#pragma mark - UI Actions
- (IBAction)onReloadBtn:(id)sender
{
    [self.ampPresetTable reloadData];
}

- (IBAction)onOpenBackupFolder:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setAllowsMultipleSelection:NO];

    // Open to the default Fuse backup directory (if it exists)
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *defaultFuseDir = [docsDir stringByAppendingPathComponent:@"Fender/FUSE/Backups/"];
    
    NSFileManager *fileMan = [NSFileManager defaultManager];
    if ([fileMan fileExistsAtPath:defaultFuseDir])
    {
        NSString *openDir = [NSString stringWithFormat:@"file://localhost%@", defaultFuseDir];
        [panel setDirectoryURL:[NSURL URLWithString:openDir]];
    }
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        
        if (result == NSOKButton)
        {        
            NSArray *folders = [panel URLs];
            
            // only allowing one item to be selected, so it should just be the first one
            NSURL *cFolder = (NSURL *)[folders objectAtIndex:0];
            NSLog(@"selected folder: %@", cFolder);
            
            dispatch_async(dispatch_get_current_queue(), ^{
                [self loadBackupFile:cFolder];
            });
        }
    }];
}

- (void) loadBackupFile:(NSURL *)url
{
    self.currentBackup = [MFFuseBackup backupFromFolder:url];
    
    if (self.currentBackup == nil)
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Unable to load a backup"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"No valid FUSE backups were found in the selected folder."];
        
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:nil];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshUI];
    });
}

- (void) refreshUI
{
    [self.presetNameField setStringValue:self.currentBackup.backupDescription];
}

@end
