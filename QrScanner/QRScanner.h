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
-(void) didProcess:(UIImage *)image trace: (UIImage *)trace qrCode: (UIImage *)qrCode top: (CGRect)top bottom: (CGPoint)bottom right: (CGRect)right cross: (CGPoint)cross found: (BOOL) found orientation: (QRProcessorOrientation) orientation;
@end

@interface QRScanner : NSObject
@property(weak) id<QRProcessor> delegate;

-(instancetype) init;
-(instancetype) initWithParentView:(UIView *)view;

- (void) start;
- (void) process;
@end
