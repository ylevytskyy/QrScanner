//
//  QRScanner.h
//  QrScanner
//
//  Created by Yuriy Levytskyy on 11/28/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, QRCodeOrientation) {
  QRCodeOrientation_North,
  QRCodeOrientation_East,
  QRCodeOrientation_South,
  QRCodeOrientation_West
};

/// QR code scanner delagate
@protocol QRScanner<NSObject>
/// Called when captured frame has been processed
- (void)didProcess:(nullable UIImage *)image        ///< Original image
             trace:(nullable UIImage *)trace        ///< Image with traces
            qrCode:(nullable UIImage *)qrCode       ///< Image with extracted QR bar
               top:(CGPoint)top                     ///< Coordinates of top left QR bar
            bottom:(CGPoint)bottom                  ///< Coordinates of bottom left QR bar
             right:(CGPoint)right                   ///< Coordinates of top right QR bar
             cross:(CGPoint)cross                   ///< Coordinates of bottom right QR bar
             found:(BOOL)found                      ///< True if bar code was recognized
       orientation:(QRCodeOrientation)orientation;  ///< Orientation of QR bar
@end

/// QR code scanner
@interface QRScanner : NSObject
/// QR code delagate
@property(nullable, weak) id<QRScanner> delegate;

/// Designated initializer
///
/// @param view View to display preview
- (nullable instancetype)initWithParentView:(nullable UIView *)view;

/// Start capturing and recognizing QR codes
- (void)start;
@end
