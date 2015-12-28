//
//  TestIOWebview.h
//  TestIO
//
//  Created by Nissim Pardo on 28/12/2015.
//  Copyright © 2015 nisso. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IODelegate <NSObject>
- (void)onReady;
- (void)onConnected;
- (void)onMessage:(NSString *)message;
- (void)onError:(NSString *)error;

@end

@interface TestIOWebview : UIWebView
- (void)connect;
@property (nonatomic, weak) id<IODelegate> ioDelegate;

@property (nonatomic, copy) NSString *partnerId;
@property (nonatomic, copy) NSString *queueId;
@end
