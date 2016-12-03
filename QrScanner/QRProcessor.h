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
  template<typename _Tp> class Point_;
  typedef Point_<float> Point2f;
  class Mat;
}

enum CV_QR_Orientation {
  CV_QR_NORTH,
  CV_QR_EAST,
  CV_QR_SOUTH,
  CV_QR_WEST,
};

class QRProcessor {
public:
  typedef void (*Callback)(void *callbackData, const cv::Mat &image, const cv::Mat &trace, const cv::Mat &qrCode, const cv::Point2f &top, const cv::Point2f &bottom, const cv::Point2f &right, const cv::Point2f &cross, bool found, CV_QR_Orientation orientation);
  
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
