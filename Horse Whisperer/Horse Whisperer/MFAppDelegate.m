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

@property (nonatomic, strong) NSMutableArray *ampPresets;
@property (nonatomic, strong) MFFuseBackup *currentBackup;
@property (nonatomic, strong) MFPreset *currentPreset;

@end


NSString *PresetDropType = @"presetDropType";

@implementation MFAppDelegate

@synthesize ampPresets = _ampPresets;
@synthesize currentBackup = _currentBackup;

#pragma mark - View LifeCycle

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    _backupModified = NO;
    
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
    NSData *rowData = [pBoard dataForType:PresetDropType];
    NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    
    NSMutableArray *draggedItemsArray = [[NSMutableArray alloc] init];
    
    NSUInteger currentItemIndex;
    NSRange range = NSMakeRange(0, [rowIndexes lastIndex] + 1);
     
    while ([rowIndexes getIndexes:&currentItemIndex maxCount:1 inIndexRange:&range] > 0)
    {
        NSObject *cItem = [self.currentBackup.presets objectAtIndex:currentItemIndex];
        [draggedItemsArray addObject:cItem];
    }
    
    // remove the items from the preset list
    [self.currentBackup.presets removeObjectsInArray:draggedItemsArray];
    
    // now put them in their new location
    NSIndexSet *newIndexes = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(row, draggedItemsArray.count)];
    [self.currentBackup.presets insertObjects:draggedItemsArray atIndexes:newIndexes];
        
    [self.ampPresetTable reloadData];
    
    _backupModified = YES;

    return YES;
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{   
    self.currentPreset = [self.currentBackup.presets objectAtIndex:self.ampPresetTable.selectedRow];
    
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
    
    if (theAction == @selector(onSaveSelected:))
        return _backupModified;
    
    return YES;
}

- (IBAction)onSaveSelected:(id)sender
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
        
        [self.currentBackup saveBackup:[NSURL URLWithString:openDir] withCompletion:^(BOOL success, NSURL *newURL)
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

@end
