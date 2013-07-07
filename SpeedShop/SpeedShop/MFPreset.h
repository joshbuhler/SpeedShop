//
//  MFPreset.h
//  Horse Whisperer
//
//  Created by Josh Buhler on 2/27/13.
//  Copyright (c) 2013 Joshua Buhler. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    AmpModel_Fender_57_Deluxe = 103,
    AmpModel_Fender_59_Bassman = 100,
    AmpModel_Fender_57_Champ = 124,
    AmpModel_Fender_65_Deluxe_Reverb = 83,
    AmpModel_Fender_65_Princeton = 106,
    AmpModel_Fender_65_Twin_Reverb = 117,
    AmpModel_Fender_Super_Sonic = 114,
    AmpModel_British_60s = 97,
    AmpModel_British_70s = 121,
    AmpModel_British_80s = 94,
    AmpModel_American_90s = 93,
    AmpModel_Metal_2000 = 109
} AmpModel;

typedef enum
{
    FX_Stomp_Empty = 0,
    FX_Stomp_Overdrive = 60,
    FX_Stomp_Wah = 73,
    FX_Stomp_Touch_Wah = 74,
    FX_Stomp_Fuzz = 26,
    FX_Stomp_Fuzz_Touch_Wah = 28,
    FX_Stomp_Simple_Comp = 136,
    FX_Stomp_Compressor = 7
} FXStomp;

typedef enum
{
    FX_Modulation_Empty = 0,
    FX_Modulation_Sine_Chorus = 18,
    FX_Modulation_Triangle_Chorus = 19,
    FX_Modulation_Sine_Flanger = 24,
    FX_Modulation_Triangle_Flanger = 25,
    FX_Modulation_Vibratone = 45,
    FX_Modulation_Vintage_Tremolo = 64,
    FX_Modulation_Sine_Tremolo = 65,
    FX_Modulation_Ring_Modulator = 34,
    FX_Modulation_Step_Filter = 41,
    FX_Modulation_Phaser = 79,
    FX_Modulation_Pitch_Shifter = 31
} FXModulation;

typedef enum
{
    FX_Delay_Empty = 0,
    FX_Delay_Mono = 22,
    FX_Delay_Mono_Echo_Filter = 67,
    FX_Delay_Stereo_Echo_Filter = 72,
    FX_Delay_Multitap = 68,
    FX_Delay_Ping_Pong = 69,
    FX_Delay_Ducking = 21,
    FX_Delay_Reverse = 70,
    FX_Delay_Tape = 43,
    FX_Delay_Stereo_Tape = 42
} FXDelay;

typedef enum
{
    FX_Reverb_Empty = 0,
    FX_Reverb_Small_Hall = 36,
    FX_Reverb_Large_Hall = 58,
    FX_Reverb_Small_Room = 38,
    FX_Reverb_Large_Room = 59,
    FX_Reverb_Small_Plate = 78,
    FX_Reverb_Large_Plate = 75,
    FX_Reverb_Ambient = 76,
    FX_Reverb_Arena = 77,
    FX_Reverb_Fender_63_Spring = 33,
    FX_Reverb_Fender_65_Spring = 11
} FXReverb;


@class MFFuseBackup;

extern NSString *const DropTypeMFPreset;

@interface MFPreset : NSObject <NSCoding, NSXMLParserDelegate>

@property (nonatomic, strong) MFFuseBackup *backup;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *description;

@property (nonatomic, readonly) AmpModel ampModel;
@property (nonatomic, readonly) FXStomp fxStomp;
@property (nonatomic, readonly) FXModulation fxModulation;
@property (nonatomic, readonly) FXDelay fxDelay;
@property (nonatomic, readonly) FXReverb fxReverb;

// For tracking a preset as it moves around. Odds are good that we'll have name
// overlaps, so comparing a preset name is no good. When a preset is loaded
// with the backup, we'll generate a uuid to save with the preset.
@property (nonatomic, strong) NSString *uuid;

- (void) loadPresetFile:(NSURL *)url;

- (NSURL *) fileURL;
- (NSString *) description;


+ (NSString *) getNameForAmpModel:(AmpModel)model;
+ (NSString *) getNameForFXStomp:(FXStomp)model;
+ (NSString *) getNameForFXModulation:(FXModulation)model;
+ (NSString *) getNameForFXDelay:(FXDelay)model;
+ (NSString *) getNameForFXReverb:(FXReverb)model;

@end
