//
//  QRProcessor.hpp
//  QrScanner
//
//  Created by Yuriy Levytskyy on 12/2/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

#ifndef QRProcessor_hpp
#define QRProcessor_hpp

// Forward declarations
namespace cv {
template <typename _Tp>
class Point_;
typedef Point_<float> Point2f;
class Mat;
}

/// QR code orientation
enum CV_QR_Orientation {
  CV_QR_NORTH,  ///< Orientation - north (bottom and cross points at the bottom)
  CV_QR_EAST,   ///< Orientation - east
  CV_QR_SOUTH,  ///< Orientation - south
  CV_QR_WEST,   ///< Orientation - west
};

class QRProcessor {
 public:
  typedef void (*Callback)(void *callbackData, const cv::Mat &image,
                           const cv::Mat &trace, const cv::Mat &qrCode,
                           const cv::Point2f &top, const cv::Point2f &bottom,
                           const cv::Point2f &right, const cv::Point2f &cross,
                           bool found, CV_QR_Orientation orientation);

 public:
  QRProcessor(Callback callback, void *callbackData);
  ~QRProcessor();

 public:
  bool startCapture();

  void process();
  void process(const cv::Mat &image);

 private:
  struct Implementation;
  Implementation *pThis;
};

#endif /* QRProcessor_hpp */
