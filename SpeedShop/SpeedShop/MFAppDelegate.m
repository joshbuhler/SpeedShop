//
//  MFAppDelegate.m
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#define APPLICATION_NAME @"Speed Shop"

#import "MFAppDelegate.h"
#import "MFFuseBackup.h"

@interface MFAppDelegate()

@property (nonatomic, strong) MFFuseBackup *currentBackup;
@property (nonatomic, strong) MFPreset *currentPreset;

@end

@implementation MFAppDelegate

#pragma mark - Main Window Delegate Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
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
    
    [self.ampModelField setStringValue:@""];
    [self.stompField setStringValue:@""];
    [self.modField setStringValue:@""];
    [self.delayField setStringValue:@""];
    [self.reverbField setStringValue:@""];
    
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
    self.detailsHeader.font = headerFont;
    
    self.backupNameField.font = fieldFont;
    self.presetNameField.font = fieldFont;
    self.authorNameField.font = fieldFont;
    self.presetDescriptionField.font = fieldFont;
    
    self.stompField.font = fieldFont;
    self.modField.font = fieldFont;
    self.delayField.font = fieldFont;
    self.reverbField.font = fieldFont;

    [_window setTitle:APPLICATION_NAME];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (![_window isVisible])
        return NSTerminateNow;

    if (self.currentBackup.isModified)
    {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Do you really want to procede?", @"")
                                         defaultButton:NSLocalizedString(@"No", @"")
                                       alternateButton:NSLocalizedString(@"Yes", @"")
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Your backup has been modified, and unsaved changes will be lost.", @"")];
        [alert setAlertStyle: NSCriticalAlertStyle];

        NSInteger buttonReturn = [alert runModal];
        if (buttonReturn +1000 == NSAlertSecondButtonReturn) // Ask Apple, why the actual return value has a difference of 1000 to the predefined return value
            return NSTerminateCancel;
    }
    return NSTerminateNow;
}

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    SEL theAction = [menuItem action];

    if (theAction == @selector(onSaveSelected:) || theAction == @selector(onSaveAsSelected:))
        return self.currentBackup.isModified;

    if (theAction == @selector(onCopyPresetlist:) && !self.currentBackup)
        return NO;

    if (theAction == @selector(onUndo:) && ![self.currentBackup isUndoable])
        return NO;

    if (theAction == @selector(onRedo:) && ![self.currentBackup isRedoable])
        return NO;

    return YES;
}


- (BOOL)windowShouldClose:(id)sender {
    if ([self applicationShouldTerminate:nil] == NSTerminateCancel)
        return NO;
    else
        return YES;
}


- (void) controlTextDidChange:(NSNotification *)obj
{
    if ([obj object] == self.backupNameField)
    {
        if (self.currentBackup == nil)
            return;

        // we don't want an undo memento for every tiny change.
        // so we only enable SAVE-menu and write modified to the window title
        [self.currentBackup forceModifiedYes];
        [self refreshWindowTitle];
    }
}


- (void) controlTextDidEndEditing:(NSNotification *)aNotification
{
    if ([aNotification object] == self.backupNameField)
    {
        if (self.currentBackup == nil)
            return;

        // user ended editing of backup description
        // now we store the string and implicitly store an undo memento
        self.currentBackup.backupDescription = self.backupNameField.stringValue;
        [self refreshUI];
    }
}

- (void) refreshUI
{
    if (self.ampPresetTable.selectedRowIndexes.count == 0)
        self.currentPreset = nil;

    [self.backupNameField setStringValue:self.currentBackup.backupDescription ?: @""];
    [self.presetNameField setStringValue:self.currentPreset.name ?: @""];
    [self.authorNameField setStringValue:self.currentPreset.author ?: @""];
    [self.presetDescriptionField setStringValue:self.currentPreset.description ?: @""];
    
    if (self.currentPreset)
    {
        [self.ampModelField setStringValue:[MFPreset getNameForAmpModel:self.currentPreset.ampModel]];
        [self.stompField setStringValue:[MFPreset getNameForFXStomp:self.currentPreset.fxStomp]];
        [self.modField setStringValue:[MFPreset getNameForFXModulation:self.currentPreset.fxModulation]];
        [self.delayField setStringValue:[MFPreset getNameForFXDelay:self.currentPreset.fxDelay]];
        [self.reverbField setStringValue:[MFPreset getNameForFXReverb:self.currentPreset.fxReverb]];
    }

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

    [self refreshWindowTitle];
}


- (void)refreshWindowTitle {
    if (self.currentBackup.isModified)
        [_window setTitle:[[NSString alloc] initWithFormat:@"%@ %@", APPLICATION_NAME, NSLocalizedString(@"modified", @"") ]];
    else
        [_window setTitle:APPLICATION_NAME];
}

// Open command fired by the "Open Recent >" menu
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSURL *cFolder = [[NSURL alloc] initFileURLWithPath:filename isDirectory:YES];
    NSLog(@"Open Recent Folder: >%@<", cFolder);

    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDir] && isDir)
    {
        dispatch_async(dispatch_get_current_queue(), ^{
            [self loadBackupFile:cFolder];
        });
        [self refreshUI];
        [self.ampPresetTable deselectAll:nil];

        return YES;  // keep in "Open Recent >" menu
    }

    return NO;  // remove from "Open Recent >" menu
}

#pragma mark - Tableview Delegate Methods

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger count = 0;
    
    if (self.currentBackup)
        count = [self.currentBackup presetsCount];
    
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
        MFPreset *cPreset = [self.currentBackup presetsObjectAtIndex:(NSUInteger) row];
        returnValue = cPreset.name;
    }
    
    return returnValue;
}

- (BOOL) tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSMutableDictionary *dragData = [[NSMutableDictionary alloc] init];
    [dragData setObject:rowIndexes forKey:@"rowIndexes"];
    [dragData setObject:[self.currentBackup presetsObjectAtIndex:rowIndexes.firstIndex] forKey:@"preset"];
    
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
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Illegal Drag'n'Drop Operation", @"")
                                         defaultButton:NSLocalizedString(@"OK", @"")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"It is impossible to insert a range into itself.", @"")];
        
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:nil];
        return NO;
    }

    while ([rowIndexes getIndexes:&currentItemIndex maxCount:1 inIndexRange:&range] > 0)
    {
        NSObject *cItem = [self.currentBackup presetsObjectAtIndex:currentItemIndex];
        [draggedItemsArray addObject:cItem];
        NSLog(@"dragged: %@", ((MFPreset*)cItem).name);
    }
    NSLog(@"first dragged Index: %ld", (long)[rowIndexes firstIndex]);
    NSLog(@"dropped on: %ld", (long)row);
    
    // remove the items from the preset list
    [self.currentBackup presetsRemoveObjectsInArray:draggedItemsArray];

    // items have been removed, so we have to correct the target row if it is *after* the dragged items
    if ([rowIndexes firstIndex] < row)
        row = row - draggedItemsArray.count + 1;

    // now put them in their new location
    NSIndexSet *newIndexes = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(row, draggedItemsArray.count)];
    [self.currentBackup presetsInsertObjects:draggedItemsArray atIndexes:newIndexes];

    [self.ampPresetTable reloadData];
    [self.ampPresetTable deselectAll:nil];
    // re-select the dragged items for improved user feedback
    [self.ampPresetTable selectRowIndexes:newIndexes byExtendingSelection:NO];
    [self refreshUI];

    return YES;
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = self.ampPresetTable.selectedRow;
    
    if (selectedRow < 0)
        return;
    
    // if multiple items are selected, we don't have a "currentPreset"
    if (self.ampPresetTable.selectedRowIndexes.count == 1)
        self.currentPreset = [self.currentBackup presetsObjectAtIndex:(NSUInteger) selectedRow];
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
    // Unsaved changes? does user really want to load other data?
    if ([self applicationShouldTerminate:nil] == NSTerminateCancel)
        return;

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
            [self refreshUI];
            [self.ampPresetTable deselectAll:nil];
        }
    }];
}

- (IBAction)onSaveSelected:(id)sender
{
    [self.ampPresetTable deselectAll:nil];

    self.currentBackup.backupDescription = self.backupNameField.stringValue;

    [self.currentBackup saveWithCompletion:^(BOOL success, NSURL *newURL)
    {
        NSAlert *alert;
        if (success)
        {
            alert = [NSAlert alertWithMessageText:NSLocalizedString(@"The backup file has been saved", @"")
                                    defaultButton:NSLocalizedString(@"OK", @"")
                                  alternateButton:nil
                                      otherButton:nil
                        informativeTextWithFormat:NSLocalizedString(@"SaveMessageOK", @""), [[newURL absoluteString] lastPathComponent]];

            [self loadBackupFile:newURL];
            [self refreshUI];
        }
        else
        {
            alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to save backup", @"")
                                    defaultButton:NSLocalizedString(@"OK", @"")
                                  alternateButton:nil
                                      otherButton:nil
                        informativeTextWithFormat:NSLocalizedString(@"There was an error trying to save the new backup file.", @"")];
        }

        [alert beginSheetModalForWindow:self.window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:nil];
    }];
}

- (IBAction)onSaveAsSelected:(id)sender
{
    [self.ampPresetTable deselectAll:nil];

    // Save to the default Fuse backup directory - otherwise Fuse won't see it
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *defaultFuseDir = [docsDir stringByAppendingPathComponent:@"Fender/FUSE/Backups/"];

    NSFileManager *fileMan = [NSFileManager defaultManager];
    if ([fileMan fileExistsAtPath:defaultFuseDir])
    {
        self.currentBackup.backupDescription = self.backupNameField.stringValue;

        NSString *openDir = [NSString stringWithFormat:@"file://localhost%@", defaultFuseDir];

        [self.currentBackup saveAsNewBackup:[NSURL URLWithString:openDir] withCompletion:^(BOOL success, NSURL *newURL)
        {
            NSAlert *alert;
            if (success)
            {
                alert = [NSAlert alertWithMessageText:NSLocalizedString(@"The new backup file has been saved", @"")
                                        defaultButton:NSLocalizedString(@"OK", @"")
                                      alternateButton:nil
                                          otherButton:nil
                            informativeTextWithFormat:NSLocalizedString(@"SaveMessageOK", @""), [[newURL absoluteString] lastPathComponent]];

                [self loadBackupFile:newURL];
                [self refreshUI];
            }
            else
            {
                alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to save backup", @"")
                                        defaultButton:NSLocalizedString(@"OK", @"")
                                      alternateButton:nil
                                          otherButton:nil
                            informativeTextWithFormat:NSLocalizedString(@"There was an error trying to save the new backup file.", @"")];
            }

            [alert beginSheetModalForWindow:self.window
                              modalDelegate:nil
                             didEndSelector:nil
                                contextInfo:nil];
        }];
    }
}


- (IBAction)onCopyPresetlist:(id)sender
{
    if (! self.currentBackup)
        return;

    NSString *thePresetList;
    thePresetList = [[NSString alloc] init];

    for (int i=0; i < [self.currentBackup presetsCount]; i++)
    {
        MFPreset *cPreset = [self.currentBackup presetsObjectAtIndex:(NSUInteger) i];
        if (cPreset)
        {
            thePresetList = [thePresetList stringByAppendingFormat:@"%02d", i];
            thePresetList = [thePresetList stringByAppendingString:@"\t"];
            thePresetList = [thePresetList stringByAppendingString:cPreset.name];
            thePresetList = [thePresetList stringByAppendingString:@"\n"];
        }
    }

    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:thePresetList  forType:NSStringPboardType];

    NSAlert *alert;
    alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Copy Presetlist", @"")
                            defaultButton:NSLocalizedString(@"OK", @"")
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:NSLocalizedString(@"Copied all your preset numbers and names to the clipboard.", @"")];

    [alert beginSheetModalForWindow:self.window
                      modalDelegate:nil
                     didEndSelector:nil
                        contextInfo:nil];

    [self.ampPresetTable deselectAll:nil];
}


- (IBAction)onUndo:(id)sender
{
    if (! self.currentBackup)
        return;
    [self.currentBackup performUndo];

    self.currentPreset = nil;
    [self.ampPresetTable reloadData];
    [self.ampPresetTable deselectAll:nil];
    [self refreshUI];
}


- (IBAction)onRedo:(id)sender
{
    if (! self.currentBackup)
        return;
    [self.currentBackup performRedo];

    self.currentPreset = nil;
    [self.ampPresetTable reloadData];
    [self.ampPresetTable deselectAll:nil];
    [self refreshUI];
}

#pragma mark - File Loading
- (void) loadBackupFile:(NSURL *)url
{
    self.currentBackup = [[MFFuseBackup alloc] init];

    // put the to be loaded folder on top of the "Open Recent >" menu
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];

    [self.currentBackup loadBackup:url withCompletion:^(BOOL success)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
            {
                self.currentPreset = [self.currentBackup presetsObjectAtIndex:0];
                [self.ampPresetTable reloadData];
                [self refreshUI];
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
    [self refreshUI];
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

//    MFPreset *oldPreset = [self.currentBackup presetForQASlot:qaSlot];
//
//    if (![oldPreset.uuid isEqualToString:qaView.preset.uuid])   // any change?
        [self.currentBackup setPreset:qaView.preset toQASlot:qaSlot];

    [self refreshUI];
}


@end
