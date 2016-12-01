//
//  QRScanner.m
//  QrScanner
//
//  Created by Yuriy Levytskyy on 11/28/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/videoio/cap_ios.h>

#include <iostream>
#include <cmath>

#import "QRScanner.h"

using namespace cv;
using namespace std;

const int CV_QR_NORTH = 0;
const int CV_QR_EAST = 1;
const int CV_QR_SOUTH = 2;
const int CV_QR_WEST = 3;

CGRect from(cv::Rect rect) {
  return CGRectMake(rect.x, rect.y, rect.width, rect.height);
}

@protocol QRProcessorPrivate <NSObject>
-(void) didProcessPrivate:(const cv::Mat&)image trace: (const cv::Mat&)trace qrCode: (const cv::Mat&)qrCode top: (CGRect)top bottom: (CGRect)bottom right: (CGRect)right cross: (CGPoint)cross found: (BOOL) found orientation: (QRProcessorOrientation) orientation;
@end


class QRProcessor {
public:
  id<QRProcessorPrivate> qrProcessor;
  
public:
  QRProcessor()
  : DBG(true)
  {
  }
  
  bool start() {
    capture.reset(new VideoCapture());
    capture->open(0);
    
    if(!capture->isOpened()) {
      cerr << " ERR: Unable find input Video source." << endl;
      return false;
    }
    
    //Step	: Capture a frame from Image Input for creating and initializing manipulation variables
    //Info	: Inbuilt functions from OpenCV
    //Note	:

    return true;
  }
  
  void process() {
    if(!capture->isOpened()) {
      cerr << " ERR: Video source not opened." << endl;
      return;
    }
    
    *capture >> image;						// Capture Image from Image Input
    if(image.empty()) {
      cerr << "ERR: Unable to query image from capture device.\n" << endl;
      return;
    }
    
    process(image);
  }
  
  void process(const Mat &image) {
    if (gray.get() == nullptr) {
      gray.reset(new Mat(image.size(), CV_MAKETYPE(image.depth(), 1)));			// To hold Grayscale Image
      edges.reset(new Mat(image.size(), CV_MAKETYPE(image.depth(), 1)));			// To hold Grayscale Image
      traces.reset(new Mat(image.size(), CV_8UC3));								// For Debug Visuals
    }
    
    *traces = Scalar(0,0,0);
    qr_raw = Mat::zeros(100, 100, CV_8UC3 );
    qr = Mat::zeros(100, 100, CV_8UC3 );
    qr_gray = Mat::zeros(100, 100, CV_8UC1);
    qr_thres = Mat::zeros(100, 100, CV_8UC1);
    Point2f cross;
    bool iflag = false;
    
    cvtColor(image, *gray, CV_RGB2GRAY);		// Convert Image captured from Image Input to GrayScale
    Canny(*gray, *edges, 100, 200, 3);		// Apply Canny edge detection on the gray image
    
    findContours(*edges, contours, hierarchy, RETR_TREE, CHAIN_APPROX_SIMPLE); // Find contours with hierarchy
    
    mark = 0;								// Reset all detected marker count for this frame
    
    // Get Moments for all Contours and the mass centers
    vector<Moments> mu(contours.size());
  		vector<Point2f> mc(contours.size());
    
    for(int i = 0; i < contours.size(); ++i) {
      mu[i] = moments(contours[i], false);
      mc[i] = Point2f(mu[i].m10/mu[i].m00, mu[i].m01/mu[i].m00);
    }
    
    
    // Start processing the contour data
    
    // Find Three repeatedly enclosed contours A,B,C
    // NOTE: 1. Contour enclosing other contours is assumed to be the three Alignment markings of the QR code.
    // 2. Alternately, the Ratio of areas of the "concentric" squares can also be used for identifying base Alignment markers.
    // The below demonstrates the first method
    
    for(int i = 0; i < contours.size(); i++) {
      int k = i;
      int c = 0;
      
      while(hierarchy[k][2] != -1) {
        k = hierarchy[k][2] ;
        c = c + 1;
      }
      if(hierarchy[k][2] != -1)
        c = c+1;
      
      if (c >= 5) {
        if (mark == 0)		A = i;
        else if  (mark == 1)	B = i;		// i.e., A is already found, assign current contour to B
        else if  (mark == 2)	C = i;		// i.e., A and B are already found, assign current contour to C
        mark = mark + 1 ;
      }
    }
    
    int top = -1,right = -1,bottom = -1;
    CGRect topRect = CGRectZero;
    CGRect bottomRect = CGRectZero;
    CGRect rightRect = CGRectZero;
    
    if (mark >= 2) { // Ensure we have (atleast 3; namely A,B,C) 'Alignment Markers' discovered
      // We have found the 3 markers for the QR code; Now we need to determine which of them are 'top', 'right' and 'bottom' markers
      
      // Determining the 'top' marker
      // Vertex of the triangle NOT involved in the longest side is the 'outlier'
      
      AB = cv_distance(mc[A],mc[B]);
      BC = cv_distance(mc[B],mc[C]);
      CA = cv_distance(mc[C],mc[A]);
      
      if (AB > BC && AB > CA) {
        outlier = C; median1=A; median2=B;
      } else if (CA > AB && CA > BC) {
        outlier = B;
        median1 = A;
        median2 = C;
      } else if (BC > AB && BC > CA) {
        outlier = A;
        median1 = B;
        median2 = C;
      }
						
      top = outlier;							// The obvious choice
      
      dist = cv_lineEquation(mc[median1], mc[median2], mc[outlier]);	// Get the Perpendicular distance of the outlier from the longest side
      slope = cv_lineSlope(mc[median1], mc[median2],align);		// Also calculate the slope of the longest side
      
      // Now that we have the orientation of the line formed median1 & median2 and we also have the position of the outlier w.r.t. the line
      // Determine the 'right' and 'bottom' markers
      
      if (align == 0) {
        bottom = median1;
        right = median2;
      } else if (slope < 0 && dist < 0 ) { // Orientation - North
        bottom = median1;
        right = median2;
        orientation = CV_QR_NORTH;
      } else if (slope > 0 && dist < 0 ) { // Orientation - East
        right = median1;
        bottom = median2;
        orientation = CV_QR_EAST;
      } else if (slope < 0 && dist > 0 ) { // Orientation - South
        right = median1;
        bottom = median2;
        orientation = CV_QR_SOUTH;
      } else if (slope > 0 && dist > 0) { // Orientation - West
        bottom = median1;
        right = median2;
        orientation = CV_QR_WEST;
      }
      
      
      // To ensure any unintended values do not sneak up when QR code is not present
      if (top < contours.size() && right < contours.size() && bottom < contours.size() && contourArea(contours[top]) > 10 && contourArea(contours[right]) > 10 && contourArea(contours[bottom]) > 10) {
        vector<Point2f> L,M,O, tempL,tempM,tempO;
        Point2f N;
        
        vector<Point2f> src,dst;		// src - Source Points basically the 4 end co-ordinates of the overlay image
        // dst - Destination Points to transform overlay image
        
        Mat warp_matrix;
        
        cv_getVertices(contours,top,slope,tempL);
        cv_getVertices(contours,right,slope,tempM);
        cv_getVertices(contours,bottom,slope,tempO);
        
        cv_updateCornerOr(orientation, tempL, L); 			// Re-arrange marker corners w.r.t orientation of the QR code
        cv_updateCornerOr(orientation, tempM, M); 			// Re-arrange marker corners w.r.t orientation of the QR code
        cv_updateCornerOr(orientation, tempO, O); 			// Re-arrange marker corners w.r.t orientation of the QR code
        
        iflag = getIntersectionPoint(M[1],M[2],O[3],O[2],N);
        
        
        src.push_back(L[0]);
        src.push_back(M[1]);
        src.push_back(N);
        src.push_back(O[3]);
        
        dst.push_back(Point2f(0,0));
        dst.push_back(Point2f(qr.cols,0));
        dst.push_back(Point2f(qr.cols, qr.rows));
        dst.push_back(Point2f(0, qr.rows));
        
        if (src.size() == 4 && dst.size() == 4 ) { // Failsafe for WarpMatrix Calculation to have only 4 Points with src and dst
          warp_matrix = getPerspectiveTransform(src, dst);
          warpPerspective(image, qr_raw, warp_matrix, cv::Size(qr.cols, qr.rows));
          copyMakeBorder(qr_raw, qr, 10, 10, 10, 10, BORDER_CONSTANT, Scalar(255,255,255));
          
          cvtColor(qr, qr_gray, CV_RGB2GRAY);
          threshold(qr_gray, qr_thres, 127, 255, CV_THRESH_BINARY);
        }
        
        //Draw contours on the image
     
        // Insert Debug instructions here
        if(DBG) {
          // Debug Prints
          // Visualizations for ease of understanding
          if (slope > 5)
            circle(*traces, cv::Point(10,20) , 5 ,  Scalar(0,0,255), -1, 8, 0 );
          else if (slope < -5)
            circle(*traces, cv::Point(10,20) , 5 ,  Scalar(255,255,255), -1, 8, 0);
          
          // Draw contours on Trace image for analysis
          drawContours(*traces, contours, top , Scalar(255,0,100), 1, 8, hierarchy, 0);
          drawContours(*traces, contours, right , Scalar(255,0,100), 1, 8, hierarchy, 0);
          drawContours(*traces, contours, bottom , Scalar(255,0,100), 1, 8, hierarchy, 0);
          
          // Draw points (4 corners) on Trace image for each Identification marker
          circle(*traces, L[0], 2,  Scalar(255,255,0), -1, 8, 0);
          circle(*traces, L[1], 2,  Scalar(0,255,0), -1, 8, 0);
          circle(*traces, L[2], 2,  Scalar(0,0,255), -1, 8, 0);
          circle(*traces, L[3], 2,  Scalar(128,128,128), -1, 8, 0);
          
          circle( *traces, M[0], 2,  Scalar(255,255,0), -1, 8, 0 );
          circle( *traces, M[1], 2,  Scalar(0,255,0), -1, 8, 0 );
          circle( *traces, M[2], 2,  Scalar(0,0,255), -1, 8, 0 );
          circle( *traces, M[3], 2,  Scalar(128,128,128), -1, 8, 0 );
          
          circle( *traces, O[0], 2,  Scalar(255,255,0), -1, 8, 0 );
          circle( *traces, O[1], 2,  Scalar(0,255,0), -1, 8, 0 );
          circle( *traces, O[2], 2,  Scalar(0,0,255), -1, 8, 0 );
          circle( *traces, O[3], 2,  Scalar(128,128,128), -1, 8, 0 );
          
          // Draw point of the estimated 4th Corner of (entire) QR Code
          circle( *traces, N, 2,  Scalar(255,255,255), -1, 8, 0 );
          
          // Draw the lines used for estimating the 4th Corner of QR Code
          line(*traces,M[1],N,Scalar(0,0,255),1,8,0);
          line(*traces,O[3],N,Scalar(0,0,255),1,8,0);
          
          
          // Show the Orientation of the QR Code wrt to 2D Image Space
          int fontFace = FONT_HERSHEY_PLAIN;
          
          if(orientation == CV_QR_NORTH) {
            putText(*traces, "NORTH", cv::Point(20,30), fontFace, 1, Scalar(0, 255, 0), 1, 8);
          }
          else if (orientation == CV_QR_EAST) {
            putText(*traces, "EAST", cv::Point(20,30), fontFace, 1, Scalar(0, 255, 0), 1, 8);
          }
          else if (orientation == CV_QR_SOUTH) {
            putText(*traces, "SOUTH", cv::Point(20,30), fontFace, 1, Scalar(0, 255, 0), 1, 8);
          }
          else if (orientation == CV_QR_WEST) {
            putText(*traces, "WEST", cv::Point(20,30), fontFace, 1, Scalar(0, 255, 0), 1, 8);
          }
          
          // Debug Prints

          topRect = from(cv::minAreaRect(contours[top]).boundingRect());
          bottomRect = from(cv::minAreaRect(contours[bottom]).boundingRect());
          rightRect = from(cv::minAreaRect(contours[right]).boundingRect());
        }
      }
    }
    
      CGPoint crossPoint = CGPointMake(cross.x, cross.y);
      [qrProcessor didProcessPrivate:image trace:*traces qrCode:qr_thres top: topRect bottom: bottomRect right: rightRect cross: crossPoint found: iflag orientation: QRProcessorOrientation(orientation)];
  }
  
private:
  // Routines
  
  // Function: Routine to get Distance between two points
  // Description: Given 2 points, the function returns the distance
  
  static float cv_distance(Point2f P, Point2f Q) {
    return sqrt(pow(abs(P.x - Q.x),2) + pow(abs(P.y - Q.y),2)) ;
  }
  
  
  // Function: Perpendicular Distance of a Point J from line formed by Points L and M; Equation of the line ax+by+c=0
  // Description: Given 3 points, the function derives the line quation of the first two points,
  //	  calculates and returns the perpendicular distance of the the 3rd point from this line.
  
  static float cv_lineEquation(Point2f L, Point2f M, Point2f J) {
    float a,b,c,pdist;
    
    a = -((M.y - L.y) / (M.x - L.x));
    b = 1.0;
    c = (((M.y - L.y) /(M.x - L.x)) * L.x) - L.y;
    
    // Now that we have a, b, c from the equation ax + by + c, time to substitute (x,y) by values from the Point J
    
    pdist = (a * J.x + (b * J.y) + c) / sqrt((a * a) + (b * b));
    return pdist;
  }
  
  // Function: Slope of a line by two Points L and M on it; Slope of line, S = (x1 -x2) / (y1- y2)
  // Description: Function returns the slope of the line formed by given 2 points, the alignement flag
  //	  indicates the line is vertical and the slope is infinity.
  
  static float cv_lineSlope(Point2f L, Point2f M, int& alignement) {
    float dx,dy;
    dx = M.x - L.x;
    dy = M.y - L.y;
    
    if ( dy != 0)
    {
      alignement = 1;
      return (dy / dx);
    }
    else				// Make sure we are not dividing by zero; so use 'alignement' flag
    {
      alignement = 0;
      return 0.0;
    }
  }
  
  // Function: Routine to calculate 4 Corners of the Marker in Image Space using Region partitioning
  // Theory: OpenCV Contours stores all points that describe it and these points lie the perimeter of the polygon.
  //	The below function chooses the farthest points of the polygon since they form the vertices of that polygon,
  //	exactly the points we are looking for. To choose the farthest point, the polygon is divided/partitioned into
  //	4 regions equal regions using bounding box. Distance algorithm is applied between the centre of bounding box
  //	every contour point in that region, the farthest point is deemed as the vertex of that region. Calculating
  //	for all 4 regions we obtain the 4 corners of the polygon ( - quadrilateral).
  static void cv_getVertices(vector<vector<cv::Point> > contours, int c_id, float slope, vector<Point2f>& quad) {
    cv::Rect box;
    box = boundingRect( contours[c_id]);
    
    Point2f M0,M1,M2,M3;
    Point2f A, B, C, D, W, X, Y, Z;
    
    A =  box.tl();
    B.x = box.br().x;
    B.y = box.tl().y;
    C = box.br();
    D.x = box.tl().x;
    D.y = box.br().y;
    
    
    W.x = (A.x + B.x) / 2;
    W.y = A.y;
    
    X.x = B.x;
    X.y = (B.y + C.y) / 2;
    
    Y.x = (C.x + D.x) / 2;
    Y.y = C.y;
    
    Z.x = D.x;
    Z.y = (D.y + A.y) / 2;
    
    float dmax[4];
    dmax[0]=0.0;
    dmax[1]=0.0;
    dmax[2]=0.0;
    dmax[3]=0.0;
    
    float pd1 = 0.0;
    float pd2 = 0.0;
    
    if (slope > 5 || slope < -5) {
      for(int i = 0; i < contours[c_id].size(); ++i) {
        pd1 = cv_lineEquation(C,A,contours[c_id][i]);	// Position of point w.r.t the diagonal AC
        pd2 = cv_lineEquation(B,D,contours[c_id][i]);	// Position of point w.r.t the diagonal BD
        
        if((pd1 >= 0.0) && (pd2 > 0.0)) {
          cv_updateCorner(contours[c_id][i],W,dmax[1],M1);
        } else if((pd1 > 0.0) && (pd2 <= 0.0)) {
          cv_updateCorner(contours[c_id][i],X,dmax[2],M2);
        } else if((pd1 <= 0.0) && (pd2 < 0.0)) {
          cv_updateCorner(contours[c_id][i],Y,dmax[3],M3);
        } else if((pd1 < 0.0) && (pd2 >= 0.0)) {
          cv_updateCorner(contours[c_id][i],Z,dmax[0],M0);
        }
        else
          continue;
      }
    } else {
      int halfx = (A.x + B.x) / 2;
      int halfy = (A.y + D.y) / 2;
      
      for(int i = 0; i < contours[c_id].size(); ++i) {
        if((contours[c_id][i].x < halfx) && (contours[c_id][i].y <= halfy)) {
          cv_updateCorner(contours[c_id][i],C,dmax[2],M0);
        } else if((contours[c_id][i].x >= halfx) && (contours[c_id][i].y < halfy)) {
          cv_updateCorner(contours[c_id][i],D,dmax[3],M1);
        } else if((contours[c_id][i].x > halfx) && (contours[c_id][i].y >= halfy)) {
          cv_updateCorner(contours[c_id][i],A,dmax[0],M2);
        } else if((contours[c_id][i].x <= halfx) && (contours[c_id][i].y > halfy)) {
          cv_updateCorner(contours[c_id][i],B,dmax[1],M3);
        }
      }
    }
    
    quad.push_back(M0);
    quad.push_back(M1);
    quad.push_back(M2);
    quad.push_back(M3);
  }
  
  // Function: Compare a point if it more far than previously recorded farthest distance
  // Description: Farthest Point detection using reference point and baseline distance
  static void cv_updateCorner(Point2f P, Point2f ref , float& baseline,  Point2f& corner) {
    float temp_dist;
    temp_dist = cv_distance(P,ref);
    
    if(temp_dist > baseline) {
      baseline = temp_dist;			// The farthest distance is the new baseline
      corner = P;						// P is now the farthest point
    }
  }
  
  // Function: Sequence the Corners wrt to the orientation of the QR Code
  static void cv_updateCornerOr(int orientation, vector<Point2f> IN,vector<Point2f> &OUT) {
    Point2f M0,M1,M2,M3;
    if(orientation == CV_QR_NORTH) {
      M0 = IN[0];
      M1 = IN[1];
      M2 = IN[2];
      M3 = IN[3];
    } else if (orientation == CV_QR_EAST) {
      M0 = IN[1];
      M1 = IN[2];
      M2 = IN[3];
      M3 = IN[0];
    } else if (orientation == CV_QR_SOUTH) {
      M0 = IN[2];
      M1 = IN[3];
      M2 = IN[0];
      M3 = IN[1];
    } else if (orientation == CV_QR_WEST) {
      M0 = IN[3];
      M1 = IN[0];
      M2 = IN[1];
      M3 = IN[2];
    }
    
    OUT.push_back(M0);
    OUT.push_back(M1);
    OUT.push_back(M2);
    OUT.push_back(M3);
  }
  
  // Function: Get the Intersection Point of the lines formed by sets of two points
  static bool getIntersectionPoint(Point2f a1, Point2f a2, Point2f b1, Point2f b2, Point2f& intersection) {
    Point2f p = a1;
    Point2f q = b1;
    Point2f r(a2-a1);
    Point2f s(b2-b1);
    
    if(cross(r,s) == 0) {
      return false;
    }
    
    float t = cross(q-p,s)/cross(r,s);
    
    intersection = p + t*r;
    return true;
  }
  
  static float cross(Point2f v1, Point2f v2) {
    return v1.x*v2.y - v1.y*v2.x;
  }
  
private:
  std::auto_ptr<VideoCapture> capture;
  Mat image;

  std::auto_ptr<Mat> gray;			// To hold Grayscale Image
  std::auto_ptr<Mat> edges;			// To hold Grayscale Image
  std::auto_ptr<Mat> traces;		// For Debug Visuals
  
  Mat qr,qr_raw,qr_gray,qr_thres;

  vector<vector<cv::Point> > contours;
  vector<Vec4i> hierarchy;

  int mark,A,B,C,median1,median2,outlier;
  float AB,BC,CA, dist,slope, areat,arear,areab, large, padding;

  int align,orientation;
  
  int DBG;						// Debug Flag
};

// EOF

@interface QRScanner () <QRProcessorPrivate, CvVideoCameraDelegate>
@property (nonatomic, assign) QRProcessor* qrProcessor;
@property (nonatomic, strong) CvVideoCamera* videoCamera;
@end

@implementation QRScanner
-(instancetype) init {
  if (self = [super init]) {
    _qrProcessor = new QRProcessor();
    _qrProcessor->qrProcessor = self;
  }
  return self;
}

-(instancetype) initWithParentView:(UIView *)view {
  if (self = [super init]) {
    _qrProcessor = new QRProcessor();
    _qrProcessor->qrProcessor = self;
    
    _videoCamera = [[CvVideoCamera alloc] initWithParentView:view];
    _videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    _videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    _videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    _videoCamera.grayscaleMode = NO;
    _videoCamera.delegate = self;
  }
  return self;
}

- (void) start {
  if (self.videoCamera) {
    [self.videoCamera start];
  } else {
    self.qrProcessor->start();
  }
}

- (void) process {
  self.qrProcessor->process();
}

- (void) dealloc {
  delete _qrProcessor;
}

-(void) didProcessPrivate:(const cv::Mat&)original trace: (const cv::Mat&)trace qrCode: (const cv::Mat&)qrCode top: (CGRect)top bottom: (CGRect)bottom right: (CGRect)right cross: (CGPoint)cross found: (BOOL) found orientation: (QRProcessorOrientation) orientation {
  @autoreleasepool {
    cv::Mat rgb;
    cvtColor(original, rgb, CV_BGR2RGB);
    
    __block UIImage *originalImage = MatToUIImage(rgb);
    __block UIImage *traceImage = MatToUIImage(trace);
    __block UIImage *qrCodeImage = MatToUIImage(qrCode);
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate didProcess:originalImage trace:traceImage qrCode:qrCodeImage top: top bottom: bottom right: right cross: cross found: found orientation: orientation];
    });
  }
}

- (void)processImage:(cv::Mat &)image {
  self.qrProcessor->process(image);
}

@end
