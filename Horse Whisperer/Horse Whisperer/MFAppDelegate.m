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



@implementation MFAppDelegate

@synthesize ampPresets = _ampPresets;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
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

#pragma mark - UI Actions
- (IBAction)onReloadBtn:(id)sender
{
    [self.ampPresetTable reloadData];
}
@end
