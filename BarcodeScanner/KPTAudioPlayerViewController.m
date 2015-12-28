//
//  KPTAudioPlayerViewController.m
//  KalturaPlayerToolkit
//
//  Created by Nissim Pardo on 27/12/2015.
//  Copyright © 2015 Kaltura. All rights reserved.
//

#import "KPTAudioPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "KPTRequestBuilder.h"
#import "NSString+JSON.h"
#import "TestIOWebview.h"

@interface KPTAudioPlayerViewController () <UIPickerViewDataSource, UIPickerViewDelegate, IODelegate > {
    id observer;
}
@property (nonatomic, strong) AVPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *volumeLabel;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet TestIOWebview *webview;
@property (weak, nonatomic) IBOutlet UIPickerView *languages;
@property (nonatomic, copy) NSArray *audios;
@end

@implementation KPTAudioPlayerViewController

- (void)viewDidLoad {
    __weak KPTAudioPlayerViewController *weakSelf = self;
    _webview.ioDelegate = self;
    [KPTRequestBuilder fetchAudioListForEntry:_jsonQRCode.parsed[@"entryId"] completion:^(NSArray *audios, NSError *error) {
        weakSelf.audios = audios;
        [KPTRequestBuilder audioFor:_audios.firstObject completion:^(NSURL *url, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _audioPlayer = [[AVPlayer alloc] initWithURL:url];
                observer = [_audioPlayer addPeriodicTimeObserverForInterval:CMTimeMake(20, 100)
                                                                      queue:dispatch_get_main_queue()
                                                                 usingBlock:^(CMTime time) {
                                                                     [weakSelf updateProgress:CMTimeGetSeconds(time)];
                                                                     
                                                                 }];
            });
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.languages reloadAllComponents];
        });
    }];

}

- (IBAction)mutePressed:(UIBarButtonItem *)sender {
    if ([sender.title isEqualToString:@"Mute"]) {
        _audioPlayer.volume = 0.0;
        sender.title = @"Unmute";
        _volumeSlider.enabled = NO;
    } else {
        _audioPlayer.volume = _volumeSlider.value;
        sender.title = @"Mute";
        _volumeSlider.enabled = YES;
    }
}


- (IBAction)changeVolume:(UISlider *)sender {
    _audioPlayer.volume = sender.value;
    _volumeLabel.text = [NSString stringWithFormat:@"%.02f", sender.value];
}

- (void)updateProgress:(NSTimeInterval)time {
    AVPlayerItem *item = _audioPlayer.currentItem;
    float progress = time / CMTimeGetSeconds(item.asset.duration);
    [_progressBar setProgress:progress animated:YES];
    int min = (progress * CMTimeGetSeconds(item.asset.duration)) / 60;
    int sec = ((progress * CMTimeGetSeconds(item.asset.duration)) - (min * 60));
    _timeLabel.text = [NSString stringWithFormat:@"%.02d:%.02d", min, sec];
    
}

- (void)onReady {
    _webview.partnerId = _jsonQRCode.parsed[@"partnerId"];
    _webview.queueId = _jsonQRCode.parsed[@"qId"];
    [_webview connect];
}

- (void)onConnected {
    NSLog(@"connected");
}

- (void)onMessage:(NSString *)message {
    NSLog(@"message %@", message);
    NSArray *comp = [message componentsSeparatedByString:@"="];
    if ([comp.firstObject isEqualToString:@"pause"]) {
        [_audioPlayer pause];
    } else if ([comp.firstObject isEqualToString:@"play"]) {
        [_audioPlayer play];
    } else {
        if (_audioPlayer && CMTimeGetSeconds(_audioPlayer.currentTime) == 0 && _audioPlayer.rate == 0) {
            float seconds = [comp.lastObject floatValue] + 2.0;
            [_audioPlayer seekToTime:CMTimeMake(seconds, 1)];
            [_audioPlayer play];
        }
    }
}

- (void)onError:(NSString *)error {
    NSLog(@"error %@", error);
}


// returns the # of rows in each component..
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _audios.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [_audios[row] objectForKey:@"tags"];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    __weak KPTAudioPlayerViewController *weakSelf = self;
    [KPTRequestBuilder audioFor:_audios[row] completion:^(NSURL *url, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _audioPlayer = [[AVPlayer alloc] initWithURL:url];
//            [_audioPlayer play];
            float seconds = [_jsonQRCode.parsed[@"currentTime"] floatValue];
            CMTime time = CMTimeMake(seconds, 1);
            [_audioPlayer seekToTime:time];
            observer = [_audioPlayer addPeriodicTimeObserverForInterval:CMTimeMake(20, 100)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time) {
                                                                 [weakSelf updateProgress:CMTimeGetSeconds(time)];
                                                                 
                                                             }];
        });
    }];
    
}

@end
