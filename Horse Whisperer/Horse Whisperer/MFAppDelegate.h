//
//  MFAppDelegate.h
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MFAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *ampPresetTable;
@property (weak) IBOutlet NSTextField *backupNameField;
@property (weak) IBOutlet NSTextField *presetNameField;

- (IBAction)onReloadBtn:(id)sender;
- (IBAction)onOpenBackupFolder:(id)sender;

@end
