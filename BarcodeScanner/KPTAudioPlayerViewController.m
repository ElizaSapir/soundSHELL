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
#import "ShellProgressView.h"

@interface KPTAudioPlayerViewController () <UIPickerViewDataSource, UIPickerViewDelegate, IODelegate > {
    id observer;
    NSDictionary *langs;
}
@property (weak, nonatomic) IBOutlet UIView *audioControlsView;
@property (nonatomic, strong) AVPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet ShellProgressView *shellProgress;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *volumeLabel;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet TestIOWebview *webview;
@property (weak, nonatomic) IBOutlet UIPickerView *languages;
@property (weak, nonatomic) IBOutlet UIView *languagesHolderView;
@property (nonatomic, copy) NSArray *audios;
@property (nonatomic) CGRect languagesStartFrame;
@end

@implementation KPTAudioPlayerViewController

- (void)viewDidLoad {
    __weak KPTAudioPlayerViewController *weakSelf = self;
    langs = @{@"kast_en": @"English", @"kast_ge": @"German"};
    _languagesStartFrame = _languagesHolderView.frame;
    _webview.ioDelegate = self;
    [KPTRequestBuilder fetchAudioListForEntry:_jsonQRCode.parsed[@"entryId"] completion:^(NSArray *audios, NSError *error) {
        weakSelf.audios = audios;
        [KPTRequestBuilder audioFor:_audios.firstObject completion:^(NSURL *url, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf presentLanguages:YES];
                [weakSelf.languages reloadAllComponents];
                [weakSelf createPlayer:url];
            });
        }];
    }];

}

- (void)createPlayer:(NSURL *)url {
    __weak KPTAudioPlayerViewController *weakSelf = self;
    observer = nil;
    _audioPlayer = nil;
    _audioPlayer = [[AVPlayer alloc] initWithURL:url];
    observer = [_audioPlayer addPeriodicTimeObserverForInterval:CMTimeMake(20, 100)
                                                          queue:dispatch_get_main_queue()
                                                     usingBlock:^(CMTime time) {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             [weakSelf updateProgress:CMTimeGetSeconds(time)];
                                                         });
                                                     }];
}

- (void)presentLanguages:(BOOL)shouldPresent {
    CGFloat newY = _languagesHolderView.frame.origin.y - _languagesHolderView.frame.size.height + 30.0;
    CGRect newFrame = shouldPresent ? (CGRect){0, newY, _languagesHolderView.frame.size} : _languagesStartFrame;
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _languagesHolderView.frame = newFrame;
        _audioControlsView.alpha = !shouldPresent;
    } completion:^(BOOL finished) {
        _languages.hidden = !shouldPresent;
    }];
}

- (IBAction)mutePressed:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        _audioPlayer.volume = 0.0;
        _volumeSlider.enabled = NO;
    } else {
        _audioPlayer.volume = _volumeSlider.value;
        _volumeSlider.enabled = YES;
    }
}

- (IBAction)changeVolume:(UISlider *)sender {
    _audioPlayer.volume = sender.value;
    _volumeLabel.text = [NSString stringWithFormat:@"%.02f", sender.value];
}


- (IBAction)languagesPressed:(UIButton *)sender {
    [self presentLanguages:sender.selected];
    sender.selected = !sender.selected;
}

- (IBAction)disconnectPressed:(UIButton *)sender {
    
}

- (void)updateProgress:(NSTimeInterval)time {
    AVPlayerItem *item = _audioPlayer.currentItem;
    float progress = time / CMTimeGetSeconds(item.asset.duration);
//    [_progressBar setProgress:progress animated:YES];
    _shellProgress.progress = progress;
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
        float seconds = [comp.lastObject floatValue] + 1.5;
        if (_audioPlayer && CMTimeGetSeconds(_audioPlayer.currentTime) == 0 && _audioPlayer.rate == 0) {
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

//- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
//    return [_audios[row] objectForKey:@"tags"];
//}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    __weak KPTAudioPlayerViewController *weakSelf = self;
    [_audioPlayer pause];
    [KPTRequestBuilder audioFor:_audios[row] completion:^(NSURL *url, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf createPlayer:url];
        });
    }];
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title = langs[[_audios[row] objectForKey:@"tags"]];
    UIColor *color = [UIColor colorWithRed:93/255.0 green:93/255.0 blue:93/255.0 alpha:1];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:color}];
    return attString;
}

@end
