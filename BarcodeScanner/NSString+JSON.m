//
//  NSString+JSON.m
//  BarcodeScanner
//
//  Created by Nissim Pardo on 28/12/2015.
//  Copyright © 2015 Draconis Software. All rights reserved.
//

#import "NSString+JSON.h"

@implementation NSString (JSON)

- (NSDictionary *)parsed {
    NSData *jsonData = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        NSLog(@"ERROR parsing JSON %@", error);
        return nil;
    }
    return parsed;
}

@end
