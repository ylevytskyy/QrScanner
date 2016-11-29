//
//  QRScanner.h
//  QrScanner
//
//  Created by Yuriy Levytskyy on 11/28/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, QRProcessorOrientation) {
  QRProcessorOrientation_North,
  QRProcessorOrientation_East,
  QRProcessorOrientation_South,
  QRProcessorOrientation_West
};

@protocol QRProcessor <NSObject>
-(void) didProcess:(UIImage *)image traces: (UIImage *)traces qrCode: (UIImage *)qrCode top: (CGPoint)top bottom: (CGPoint)bottom right: (CGPoint)right cross: (CGPoint)cross found: (BOOL) found orientation: (QRProcessorOrientation) orientation;
@end

@interface QRScanner : NSObject
@property(weak) id<QRProcessor> delegate;

- (void) start;
- (void) process;
@end
