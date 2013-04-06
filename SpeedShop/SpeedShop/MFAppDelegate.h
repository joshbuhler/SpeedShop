//
//  MFAppDelegate.h
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFQuickAccessView.h"

@interface MFAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, MFQuickAccessViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *ampPresetTable;
@property (weak) IBOutlet NSTextField *backupNameField;
@property (weak) IBOutlet NSTextField *presetNameField;
@property (weak) IBOutlet NSTextField *authorNameField;
@property (weak) IBOutlet NSTextField *presetDescriptionField;
@property (weak) IBOutlet MFQuickAccessView *qaBox1;
@property (weak) IBOutlet MFQuickAccessView *qaBox2;
@property (weak) IBOutlet MFQuickAccessView *qaBox3;

- (IBAction)onReloadBtn:(id)sender;

- (IBAction)onOpenBackupFolder:(id)sender;

- (IBAction)onSaveSelected:(id)sender;
- (IBAction)onSaveAsSelected:(id)sender;

@end