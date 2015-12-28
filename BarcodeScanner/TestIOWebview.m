//
//  TestIOWebview.m
//  TestIO
//
//  Created by Nissim Pardo on 28/12/2015.
//  Copyright © 2015 nisso. All rights reserved.
//

#import "TestIOWebview.h"
#import "NSString+JSON.h"

typedef NS_ENUM(NSInteger, Status) {
    StatusConnected,
    StatusMessage,
    StatusError
};

@interface NSDictionary (JSON)
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, readonly) Status status;
@end

@implementation NSDictionary (JSON)

- (NSString *)type {
    return self[@"type"];
}

- (NSString *)message {
    return self[@"value"];
}

- (Status)status {
    if ([self.type isEqualToString:@"connected"]) {
        return StatusConnected;
    } else if ([self.type isEqualToString:@"message"]) {
        return StatusMessage;
    } else {
        return StatusError;
    }
}

@end

@interface TestIOWebview()<UIWebViewDelegate>

@end

@implementation TestIOWebview

- (void)connect {
    NSString *js = [@"go('http://dev-backend15.dev.kaltura.com:3000/?" stringByAppendingFormat:@"p=%@&x=%@','%@')", _partnerId, _queueId, _queueId];
    [self stringByEvaluatingJavaScriptFromString:js];
}
- (void)awakeFromNib {
    self.delegate = self;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"testIO" withExtension:@"html"];
    [self loadRequest:[NSURLRequest requestWithURL:url]];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    NSArray *pathComponents = url.pathComponents;
    if ([pathComponents.lastObject isEqualToString:@"testIO.html"]) {
        return YES;
    }
    NSDictionary *params = [pathComponents.lastObject parsed];
    switch (params.status) {
        case StatusConnected:
            [_ioDelegate onConnected];
            break;
        case StatusMessage:
            [_ioDelegate onMessage:params.message];
            break;
        case StatusError:
            [_ioDelegate onError:params.message];
            break;
    }
    return NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
//    [webView stringByEvaluatingJavaScriptFromString:@"go('http://dev-backend15.dev.kaltura.com:3000/?p=101&x=q3', 'q3')"];
    [_ioDelegate onReady];
}
@end
