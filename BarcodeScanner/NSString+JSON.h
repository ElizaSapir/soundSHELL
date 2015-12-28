//
//  NSString+JSON.h
//  BarcodeScanner
//
//  Created by Nissim Pardo on 28/12/2015.
//  Copyright © 2015 Draconis Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (JSON)
@property (nonatomic, copy, readonly) NSDictionary *parsed;
@end


