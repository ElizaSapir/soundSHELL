//
//  ShellProgressView.m
//  BarcodeScanner
//
//  Created by Nissim Pardo on 29/12/2015.
//  Copyright © 2015 Draconis Software. All rights reserved.
//

#import "ShellProgressView.h"

@implementation ShellProgressView {
    int lastProgress;
}

- (void)setProgress:(float)progress {
    if (progress * 22 > lastProgress) {
        lastProgress = progress * 22;
        self.image = [UIImage imageNamed:[NSString stringWithFormat:@"logoFullEmpty%d", lastProgress]];
    }
}

@end
