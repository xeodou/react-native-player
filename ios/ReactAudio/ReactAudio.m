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

RCT_EXPORT_METHOD(prepare:(NSString *)url:(BOOL) bAutoPlay) {
  
  if(!([url length]>0)) return;
  
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
  [[AVAudioSession sharedInstance] setActive: YES error: nil];
  [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
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
  [self.bridge.eventDispatcher sendDeviceEventWithName: @"finishListener"
                                                  body: @{@"status": @"finished" }];
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



@end
