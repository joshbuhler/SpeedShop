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
{
    BOOL    _backupModified;
}

@property (nonatomic, strong) MFFuseBackup *currentBackup;
@property (nonatomic, strong) MFPreset *currentPreset;

@end

@implementation MFAppDelegate

@synthesize currentBackup = _currentBackup;

#pragma mark - View LifeCycle

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application    
    _backupModified = NO;
        
    // init drag/drop for the tableview
    [_ampPresetTable registerForDraggedTypes:[NSArray arrayWithObject:DropTypeMFPreset]];
    
    self.qaBox1.delegate = self;
    self.qaBox2.delegate = self;
    self.qaBox3.delegate = self;
    
    // empty the placeholder text (want to keep that around for working in IB though)
    [self.backupNameField setStringValue:@""];
    [self.presetNameField setStringValue:@""];
    [self.authorNameField setStringValue:@""];
    [self.presetDescriptionField setStringValue:@""];
    
    // Custom font for headers
    NSFont *headerFont = [NSFont fontWithName:@"Open Sans Extrabold" size:20.0f];
    NSFont *fieldFont = [NSFont fontWithName:@"Open Sans Light" size:14.0f];
    self.cBackupHeader.font = headerFont;
    self.nameHeader.font = headerFont;
    self.authorHeader.font = headerFont;
    self.descHeader.font = headerFont;
    self.qa1Header.font = headerFont;
    self.qa2Header.font = headerFont;
    self.qa3Header.font = headerFont;
    
    self.backupNameField.font = fieldFont;
    self.presetNameField.font = fieldFont;
    self.authorNameField.font = fieldFont;
    self.presetDescriptionField.font = fieldFont;
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

#pragma mark - Tableview Delegate Methods

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger count = 0;
    
    if (self.currentBackup)
        count = self.currentBackup.presets.count;
    
    return count;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id returnValue = nil;
    
    NSString *columnID = [tableColumn identifier];
        
    if ([columnID isEqualToString:@"presetIndex"])
    {
        returnValue = [NSString stringWithFormat:@"%02ld", row];
    }
    
    if ([columnID isEqualToString:@"presetName"])
    {
        MFPreset *cPreset = [self.currentBackup.presets objectAtIndex:row];
        returnValue = cPreset.name;
    }
    
    return returnValue;
}

- (BOOL) tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSMutableDictionary *dragData = [[NSMutableDictionary alloc] init];
    [dragData setObject:rowIndexes forKey:@"rowIndexes"];
    [dragData setObject:[self.currentBackup.presets objectAtIndex:rowIndexes.firstIndex] forKey:@"preset"];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dragData];
    [pboard declareTypes:[NSArray arrayWithObject:DropTypeMFPreset] owner:self];
    
    [pboard setData:data forType:DropTypeMFPreset];
    
    return YES;
}

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if ([info draggingSource] == self.ampPresetTable)
    {
        if (dropOperation == NSTableViewDropOn)
        {
            [tableView setDropRow:row dropOperation:NSTableViewDropOn];
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
    NSData *rowData = [pBoard dataForType:DropTypeMFPreset];
    NSMutableDictionary *dragData = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    
    NSIndexSet *rowIndexes = [dragData objectForKey:@"rowIndexes"];
    
    NSMutableArray *draggedItemsArray = [[NSMutableArray alloc] init];
    
    NSUInteger currentItemIndex;
    NSRange range = NSMakeRange(0, [rowIndexes lastIndex] + 1);

    // prevent illegal multi-select drag'n'drops
    if (row >= [rowIndexes firstIndex] && row <= [rowIndexes lastIndex])
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Illegal Drag'n'Drop Operation"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"It is impossible to insert a range into itself."];
        
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:nil];
        return NO;
    }

    while ([rowIndexes getIndexes:&currentItemIndex maxCount:1 inIndexRange:&range] > 0)
    {
        NSObject *cItem = [self.currentBackup.presets objectAtIndex:currentItemIndex];
        [draggedItemsArray addObject:cItem];
        NSLog(@"dragged: %@", ((MFPreset*)cItem).name);
    }
    NSLog(@"first dragged Index: %ld", (long)[rowIndexes firstIndex]);
    NSLog(@"dropped on: %ld", (long)row);
    
    // remove the items from the preset list
    [self.currentBackup.presets removeObjectsInArray:draggedItemsArray];

    // items have been removed, so we have to correct the target row if it is *after* the dragged items
    if ([rowIndexes firstIndex] < row)
        row = row - draggedItemsArray.count + 1;

    // now put them in their new location
    NSIndexSet *newIndexes = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(row, draggedItemsArray.count)];
    [self.currentBackup.presets insertObjects:draggedItemsArray atIndexes:newIndexes];
        
    [self.ampPresetTable reloadData];
    [self.ampPresetTable deselectAll:nil];
    
    _backupModified = YES;

    return YES;
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = self.ampPresetTable.selectedRow;
    
    if (selectedRow < 0)
        return;
    
    // if multiple items are selected, we don't have a "currentPreset"
    if (self.ampPresetTable.selectedRowIndexes.count == 1)
        self.currentPreset = [self.currentBackup.presets objectAtIndex:selectedRow];
    else
        self.currentPreset = nil;
    
    [self refreshUI];
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

#pragma mark - File Loading
- (void) loadBackupFile:(NSURL *)url
{
    self.currentBackup = [[MFFuseBackup alloc] init];
    [self.currentBackup loadBackup:url withCompletion:^(BOOL success)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
            {
                self.currentPreset = [self.currentBackup.presets objectAtIndex:0];
                [self.ampPresetTable reloadData];
                [self refreshUI];
                
                _backupModified = NO;
            }
            else
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
            }
            
        });
    }];    
}

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    SEL theAction = [menuItem action];
    
    if (theAction == @selector(onSaveSelected:) || theAction == @selector(onSaveAsSelected:))
        return _backupModified;
    
    return YES;
}

- (IBAction)onSaveSelected:(id)sender
{
    [self.currentBackup saveWithCompletion:^(BOOL success, NSURL *newURL)
     {
         NSString *msg = @"You'll now need to use Fender FUSE to transfer the backup to your amp.\nUse backup folder: ";
         msg = [msg stringByAppendingString:[[newURL absoluteString] lastPathComponent]];

         NSAlert *alert;
         if (success)
         {
             alert = [NSAlert alertWithMessageText:@"The backup file has been saved"
                                     defaultButton:@"OK"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:msg];
             
             // todo: reload the newly saved file
             [self loadBackupFile:newURL];
         }
         else
         {
             alert = [NSAlert alertWithMessageText:@"Unable to save backup"
                                     defaultButton:@"OK"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"There was an error trying to save the new backup file."];
         }
         
         [alert beginSheetModalForWindow:self.window
                           modalDelegate:nil
                          didEndSelector:nil
                             contextInfo:nil];
     }];
}

- (IBAction)onSaveAsSelected:(id)sender
{
    //NSSavePanel *panel = [NSSavePanel savePanel];
    
    // Save to the default Fuse backup directory - otherwise Fuse won't see it
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *defaultFuseDir = [docsDir stringByAppendingPathComponent:@"Fender/FUSE/Backups/"];
    
    NSFileManager *fileMan = [NSFileManager defaultManager];
    if ([fileMan fileExistsAtPath:defaultFuseDir])
    {
        NSString *openDir = [NSString stringWithFormat:@"file://localhost%@", defaultFuseDir];
        
        self.currentBackup.backupDescription = self.backupNameField.stringValue;
        
        [self.currentBackup saveAsNewBackup:[NSURL URLWithString:openDir] withCompletion:^(BOOL success, NSURL *newURL)
         {
             NSString *msg = @"You'll now need to use Fender FUSE to transfer the backup to your amp.\nUse backup folder: ";
             msg = [msg stringByAppendingString:[[newURL absoluteString] lastPathComponent]];
             
             NSAlert *alert;
             if (success)
             {
                 alert = [NSAlert alertWithMessageText:@"The new backup file has been saved"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:msg];
                 
                 // todo: reload the newly saved file
                 [self loadBackupFile:newURL];
             }
             else
             {
                 alert = [NSAlert alertWithMessageText:@"Unable to save backup"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"There was an error trying to save the new backup file."];
             }
             
             [alert beginSheetModalForWindow:self.window
                               modalDelegate:nil
                              didEndSelector:nil
                                 contextInfo:nil];
         }];
        //[panel setDirectoryURL:[NSURL URLWithString:openDir]];
    }
    
    
    /*
    [panel beginWithCompletionHandler:^(NSInteger result) {
        
        if (result == NSOKButton)
        {
            NSLog(@"url: %@", panel.URL);
            [self.currentBackup saveBackup:panel.URL withCompletion:^(BOOL success)
            {
                NSAlert *alert;
                if (success)
                {
                    alert = [NSAlert alertWithMessageText:@"The new backup file has been saved"
                                                     defaultButton:@"OK"
                                                   alternateButton:nil
                                                       otherButton:nil
                                         informativeTextWithFormat:@""];
                    
                    // todo: reload the newly saved file
                    [self loadBackupFile:panel.URL];
                }
                else
                {
                    alert = [NSAlert alertWithMessageText:@"Unable to save backup"
                                            defaultButton:@"OK"
                                          alternateButton:nil
                                              otherButton:nil
                                informativeTextWithFormat:@"There was an error trying to save the new backup file."];
                }
                
                [alert beginSheetModalForWindow:self.window
                                  modalDelegate:nil
                                 didEndSelector:nil
                                    contextInfo:nil];
            }];
        }
    }];
    */
}

- (void) refreshUI
{
    [self.backupNameField setStringValue:self.currentBackup.backupDescription ?: @""];
    [self.presetNameField setStringValue:self.currentPreset.name ?: @""];
    [self.authorNameField setStringValue:self.currentPreset.author ?: @""];
    [self.presetDescriptionField setStringValue:self.currentPreset.description ?: @""];
    
    if (self.currentBackup.ampSeries == AmpSeries_Mustang || self.currentBackup.ampSeries == AmpSeries_Mustang_V2)
    {
        self.qaBox1.preset = [self.currentBackup presetForQASlot:0] ?: nil;
        self.qaBox2.preset = [self.currentBackup presetForQASlot:1] ?: nil;
        self.qaBox3.preset = [self.currentBackup presetForQASlot:2] ?: nil;
        
        self.qaBox1.canAcceptDrag = YES;
        self.qaBox2.canAcceptDrag = YES;
        self.qaBox3.canAcceptDrag = YES;
    }
    else
    {
        self.qaBox1.preset = nil;
        self.qaBox2.preset = nil;
        self.qaBox3.preset = nil;
        
        self.qaBox1.canAcceptDrag = NO;
        self.qaBox2.canAcceptDrag = NO;
        self.qaBox3.canAcceptDrag = NO;
    }
}

- (void) controlTextDidChange:(NSNotification *)obj
{
    if ([obj object] == self.backupNameField)
    {
        if (self.currentBackup == nil)
            return;
        
        self.currentBackup.backupDescription = self.backupNameField.stringValue;
        _backupModified = YES;
    }
}

- (void) presetDidChangeForQAView:(MFQuickAccessView *)qaView
{
    int qaSlot = 0;
    if (qaView == self.qaBox1)
    {
        qaSlot = 0;
    }
    
    if (qaView == self.qaBox2)
    {
        qaSlot = 1;
    }
    
    if (qaView == self.qaBox3)
    {
        qaSlot = 2;
    }
    
    [self.currentBackup setPreset:qaView.preset toQASlot:qaSlot];
    _backupModified = YES;
}

@end
