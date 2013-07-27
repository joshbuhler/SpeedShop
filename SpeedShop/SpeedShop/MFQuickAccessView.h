//
//  MFQuickAccessView.h
//  Horse Whisperer
//
//  Created by Josh Buhler on 3/5/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFFuseBackup.h"

@class MFQuickAccessView;
@protocol MFQuickAccessViewDelegate <NSObject>

@optional
- (void) presetDidChangeForQAView:(MFQuickAccessView *)qaView;

@end



@interface MFQuickAccessView : NSView

@property (nonatomic, strong) id delegate;

@property (nonatomic, assign) BOOL canAcceptDrag;

- (void)setPreset:(MFPreset *)newPreset fromAmpIndex:(int) newAmpIndex;
- (MFPreset *) preset;

@end
