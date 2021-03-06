//
//  QRScanner.m
//  QrScanner
//
//  Created by Yuriy Levytskyy on 11/28/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

#import <opencv2/imgcodecs/ios.h>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/highgui.hpp>
#import <opencv2/opencv.hpp>

#import "QRScanner.h"

#import "QRProcessor.h"

static void callback(void *callbackData, const cv::Mat &image,
                     const cv::Mat &trace, const cv::Mat &qrCode,
                     const cv::Point2f &top, const cv::Point2f &bottom,
                     const cv::Point2f &right, const cv::Point2f &cross,
                     bool found, CV_QR_Orientation orientation) {
  auto topPoint = CGPointMake(top.x, top.y);
  auto bottomPoint = CGPointMake(bottom.x, bottom.y);
  auto rightPoint = CGPointMake(right.x, right.y);
  auto crossPoint = CGPointMake(cross.x, cross.y);

  @autoreleasepool {
    __block UIImage *originalImage = MatToUIImage(image.clone());
    __block UIImage *traceImage = MatToUIImage(trace.clone());
    __block UIImage *qrCodeImage = MatToUIImage(qrCode.clone());

    dispatch_async(dispatch_get_main_queue(), ^{
      auto qrScanner = (__bridge QRScanner *)callbackData;
      [qrScanner.delegate didProcess:originalImage
                               trace:traceImage
                              qrCode:qrCodeImage
                                 top:topPoint
                              bottom:bottomPoint
                               right:rightPoint
                               cross:crossPoint
                               found:found
                         orientation:QRCodeOrientation(orientation)];
    });
  }
}

@interface QRScanner ()<CvVideoCameraDelegate>
@property(nonatomic, assign) QRProcessor *qrProcessor;
@property(nonatomic, strong) CvVideoCamera *videoCamera;
@end

@implementation QRScanner
// Must always override super's designated initializer.
- (instancetype)init {
  return [self initWithParentView:nil];
}

- (instancetype)initWithParentView:(UIView *)view {
  if (self = [super init]) {
    _qrProcessor = new QRProcessor(callback, (__bridge void *)self);

    _videoCamera = [[CvVideoCamera alloc] initWithParentView:view];
    _videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    _videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    _videoCamera.defaultAVCaptureVideoOrientation =
        AVCaptureVideoOrientationPortrait;
    _videoCamera.grayscaleMode = NO;
    _videoCamera.delegate = self;
  }
  return self;
}

- (void)dealloc {
  delete _qrProcessor;
}

- (void)start {
  [self.videoCamera start];
}

- (void)process {
  self.qrProcessor->process();
}

#pragma mark - CvVideoCameraDelegate

- (void)processImage:(cv::Mat &)image {
  self.qrProcessor->process(image);
}

@end
