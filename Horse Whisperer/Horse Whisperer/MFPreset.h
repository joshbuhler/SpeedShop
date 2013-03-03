//
//  MFPreset.h
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFPreset : NSObject <NSXMLParserDelegate>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *description;

- (void) loadPresetFile:(NSURL *)url;

@end
