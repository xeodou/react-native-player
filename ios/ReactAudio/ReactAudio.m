//
//  MyObjcClass.m
//  use_nativeModules
//
//  Created by Q on 2016. 8. 25..
//  Copyright © 2016년 Facebook. All rights reserved.
//

#import "ReactAudio.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ReactAudio()
{
    NSTimer *timer;
    CMTime duration;
    CMTime currentTime;
    
}

@end


@implementation ReactAudio

@synthesize bridge = _bridge;


RCT_EXPORT_MODULE();


- (ReactAudio *)init
{
    self = [super init];
    if (self) {
        [self setSharedAudioSessionCategory];
        [self registerAudioInterruptionNotifications];
        [self registerRemoteControlEvents];
        [self setNowPlayingInfo:true];
        NSLog(@"AudioPlayer initialized");
    }
    
    return self;
}

- (void)dealloc
{
    [self unregisterAudioInterruptionNotifications];
    [self unregisterRemoteControlEvents];
}

#pragma mark - Pubic API


RCT_EXPORT_METHOD(prepare:(NSString *)url:(BOOL) bAutoPlay) {
    
    
    if(!([url length]>0)) return;
    
    [self activate];
    [self.bridge.eventDispatcher sendDeviceEventWithName: @"onPlayerStateChanged"
                                                    body: @{@"playbackState": @4 }];
    
    NSURL *soundUrl = [[NSURL alloc] initWithString:url];
    self.playerItem = [AVPlayerItem playerItemWithURL:soundUrl];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    
    if(bAutoPlay) {
        [self.player play];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(startSending:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    });
}


-(void)playFinished:(NSNotification *)notification{
    [self.playerItem seekToTime:kCMTimeZero];
    [self.bridge.eventDispatcher sendDeviceEventWithName: @"onPlayerStateChanged"
                                                    body: @{@"playbackState": @5 }];
}


RCT_EXPORT_METHOD(stop) {
    
    [self.player pause];
    CMTime newTime = CMTimeMakeWithSeconds(0, 1);
    [self.player seekToTime:newTime];
    
}

RCT_EXPORT_METHOD(seekTo:(int) nSecond) {
    CMTime newTime = CMTimeMakeWithSeconds(nSecond/1000, 1);
    [self.player seekToTime:newTime];
}

RCT_EXPORT_METHOD(getDuration:(RCTResponseSenderBlock)callback){
    //this is kind of crude but it will prevent the app from crashing due to a "NAN" return(this allows the getDuration method to be executed in the componentDidMount function of the React class without the app crashing
    while(self.playerItem.status != AVPlayerItemStatusReadyToPlay){
    }
    
    float duration = CMTimeGetSeconds(self.playerItem.duration);
    float durationInMilliSeconds = duration * 1000;
    callback(@[[[NSNumber alloc] initWithFloat:durationInMilliSeconds]]);
}


RCT_EXPORT_METHOD(play) {
    
    [self activate];
    [self.player play];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(startSending:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    });
}

RCT_EXPORT_METHOD(resume) {
    
    [self.player play];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(startSending:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    });
}

-(void) startSending: (NSTimer *)timer {
    
    currentTime = self.player.currentItem.currentTime;
    [self.bridge.eventDispatcher sendDeviceEventWithName: @"onUpdatePosition"
                                                    body: @{@"currentPosition": @(CMTimeGetSeconds(currentTime)*1000) }];
}

RCT_EXPORT_METHOD(pause) {
    
    [self.player pause];
    [timer invalidate];
    timer = nil;
    
}

#pragma mark - Audio Session


-(void)activate {
    
    NSError *categoryError = nil;
    
    [[AVAudioSession sharedInstance] setActive:YES error:&categoryError];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&categoryError];
}

- (void)deactivate
{
    NSError *categoryError = nil;
    
    [[AVAudioSession sharedInstance] setActive:NO error:&categoryError];
    
    if (categoryError) {
        NSLog(@"Error setting category! %@", [categoryError description]);
    }
}

- (void)setSharedAudioSessionCategory
{
    NSError *categoryError = nil;
    self.isPlayingWithOthers = [[AVAudioSession sharedInstance] isOtherAudioPlaying];
    
    [[AVAudioSession sharedInstance] setActive:NO error:&categoryError];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&categoryError];
    // [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&categoryError];
    
    if (categoryError) {
        NSLog(@"Error setting category! %@", [categoryError description]);
    }
}

- (void)registerAudioInterruptionNotifications
{
    // Register for audio interrupt notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAudioInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
    // Register for route change notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onRouteChangeInterruption:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
}

- (void)unregisterAudioInterruptionNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification
                                                  object:nil];
}

- (void)onAudioInterruption:(NSNotification *)notification
{
    // Get the user info dictionary
    NSDictionary *interruptionDict = notification.userInfo;
    
    // Get the AVAudioSessionInterruptionTypeKey enum from the dictionary
    NSInteger interuptionType = [[interruptionDict valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    
    // Decide what to do based on interruption type
    switch (interuptionType)
    {
        case AVAudioSessionInterruptionTypeBegan:
            NSLog(@"Audio Session Interruption case started.");
            [self.player pause];
            break;
            
        case AVAudioSessionInterruptionTypeEnded:
            NSLog(@"Audio Session Interruption case ended.");
            self.isPlayingWithOthers = [[AVAudioSession sharedInstance] isOtherAudioPlaying];
            (self.isPlayingWithOthers) ? [self.player pause] : [self.player play];
            break;
            
        default:
            NSLog(@"Audio Session Interruption Notification case default.");
            break;
    }
}

- (void)onRouteChangeInterruption:(NSNotification *)notification
{
    
    NSDictionary *interruptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interruptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason)
    {
        case AVAudioSessionRouteChangeReasonUnknown:
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonUnknown");
            break;
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // A user action (such as plugging in a headset) has made a preferred audio route available.
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonNewDeviceAvailable");
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            // The previous audio output path is no longer available.
            [self.player pause];
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // The category of the session object changed. Also used when the session is first activated.
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonCategoryChange"); //AVAudioSessionRouteChangeReasonCategoryChange
            break;
            
        case AVAudioSessionRouteChangeReasonOverride:
            // The output route was overridden by the app.
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonOverride");
            break;
            
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            // The route changed when the device woke up from sleep.
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonWakeFromSleep");
            break;
            
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            // The route changed because no suitable route is now available for the specified category.
            NSLog(@"routeChangeReason : AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory");
            break;
    }
}


#pragma mark - Remote Control Events

- (void)registerRemoteControlEvents
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.playCommand addTarget:self action:@selector(didReceivePlayCommand:)];
    [commandCenter.pauseCommand addTarget:self action:@selector(didReceivePauseCommand:)];
    [commandCenter.togglePlayPauseCommand addTarget:self action:@selector(didReceiveToggleCommand:)];
    [commandCenter.nextTrackCommand addTarget:self action:@selector(didReceiveNextTrackCommand:)];
    [commandCenter.previousTrackCommand addTarget:self action:@selector(didReceivePreviousTrackCommand:)];
    commandCenter.playCommand.enabled = YES;
    commandCenter.pauseCommand.enabled = YES;
    commandCenter.nextTrackCommand.enabled = YES;
    commandCenter.previousTrackCommand.enabled = YES;
    commandCenter.stopCommand.enabled = NO;
}

- (void)didReceivePlayCommand:(MPRemoteCommand *)event
{
    [self.player play];
}

- (void)didReceivePauseCommand:(MPRemoteCommand *)event
{
    [self.player pause];
}

- (void)didReceiveToggleCommand:(MPRemoteCommand *)event
{
    if (self.player.rate == 1.0f) {
        [self.player pause];
    } else {
        [self.player play];
    }
}

- (void)didReceiveNextTrackCommand:(MPRemoteCommand *)event
{
    [self.bridge.eventDispatcher sendDeviceEventWithName: @"onRemoteControl"
                                                    body: @{@"action": @"NEXT" }];
}

- (void)didReceivePreviousTrackCommand:(MPRemoteCommand *)event
{
    [self.bridge.eventDispatcher sendDeviceEventWithName: @"onRemoteControl"
                                                    body: @{@"action": @"PREV" }];
}

- (void)unregisterRemoteControlEvents
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.playCommand removeTarget:self];
    [commandCenter.pauseCommand removeTarget:self];
}

- (void)setNowPlayingInfo:(bool)isPlaying
{
    // TODO Get artwork from stream
    // MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc]initWithImage:[UIImage imageNamed:@"webradio1"]];
    
    NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSDictionary *nowPlayingInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"blah", MPMediaItemPropertyAlbumTitle,
                                    @"", MPMediaItemPropertyAlbumArtist,
                                    appName ? appName : @"", MPMediaItemPropertyTitle,
                                    [NSNumber numberWithFloat:isPlaying ? 1.0f : 0.0],MPNowPlayingInfoPropertyPlaybackRate, nil];
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;
}


@end
