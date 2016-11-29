//
//  QRScanner.h
//  QrScanner
//
//  Created by Yuriy Levytskyy on 11/28/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol QRProcessor <NSObject>
-(void) didProcess:(UIImage *)image traces: (UIImage *)traces qrCode: (UIImage *)qrCode;
@end

@interface QRScanner : NSObject
@property(weak) id<QRProcessor> delegate;

- (void) start;
- (void) process;
@end
