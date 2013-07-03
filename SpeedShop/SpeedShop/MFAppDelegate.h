//
//  MFAppDelegate.h
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFQuickAccessView.h"

@interface MFAppDelegate : NSObject <NSApplicationDelegate
        , NSTableViewDataSource
        , NSTableViewDelegate
        , MFQuickAccessViewDelegate
        , NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *ampPresetTable;
@property (weak) IBOutlet NSTextField *backupNameField;
@property (weak) IBOutlet NSTextField *presetNameField;
@property (weak) IBOutlet NSTextField *authorNameField;
@property (weak) IBOutlet NSTextField *presetDescriptionField;
@property (weak) IBOutlet MFQuickAccessView *qaBox1;
@property (weak) IBOutlet MFQuickAccessView *qaBox2;
@property (weak) IBOutlet MFQuickAccessView *qaBox3;
@property (weak) IBOutlet NSTextField *cBackupHeader;
@property (weak) IBOutlet NSTextField *nameHeader;
@property (weak) IBOutlet NSTextField *authorHeader;
@property (weak) IBOutlet NSTextField *descHeader;
@property (weak) IBOutlet NSTextField *qa1Header;
@property (weak) IBOutlet NSTextField *qa2Header;
@property (weak) IBOutlet NSTextField *qa3Header;

- (IBAction)onReloadBtn:(id)sender;

- (IBAction)onOpenBackupFolder:(id)sender;
- (IBAction)onSaveSelected:(id)sender;
- (IBAction)onSaveAsSelected:(id)sender;
- (IBAction)onCopyPresetlist:(id)sender;
- (IBAction)onUndo:(id)sender;
- (IBAction)onRedo:(id)sender;

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (BOOL)windowShouldClose:(id)sender;
@end
