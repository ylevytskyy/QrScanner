//
//  ViewController.swift
//  QrScanner
//
//  Created by Yuriy Levytskyy on 11/28/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

import UIKit

func - (point: CGPoint, size: CGSize) -> CGPoint {
  return CGPoint(x: point.x - size.width, y: point.y - size.height)
}

func + (point: CGPoint, size: CGSize) -> CGPoint {
  return CGPoint(x: point.x + size.width, y: point.y + size.height)
}

extension CGPoint {
  /// Integral version
  public var integral: CGPoint {
    return CGPoint(
      x: CoreGraphics.floor(x),
      y: CoreGraphics.floor(y))
  }
}

extension UIView {
  func setOrigin(origin: CGPoint) {
    frame = CGRect(origin: origin, size: frame.size)
  }
}

class ViewController: UIViewController {
  fileprivate var qrScanner: QRScanner!
  
  fileprivate var timer: Timer?
  fileprivate var showLabel = false
  
  fileprivate var labelView: UIView!
//  fileprivate let label = UILabel()

  lazy var detector: CIDetector? = {
    let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
    return CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: options)
  }()

  @IBOutlet weak var originalImageView: UIImageView!
  @IBOutlet weak var tracesImageView: UIImageView?
  @IBOutlet weak var qrImageView: UIImageView?
  @IBOutlet weak var decodedLabel: UILabel!
}

extension ViewController {
  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    qrScanner = QRScanner(parentView: nil)
    qrScanner?.delegate = self
    qrScanner?.start()
    
    labelView = UIView(frame: CGRect(x: 20, y: 20, width: 200, height: 200))
    labelView.layer.borderColor = UIColor.red.cgColor
    labelView.layer.borderWidth = 3
    labelView.clipsToBounds = true
    labelView.backgroundColor = UIColor.brown
    originalImageView.addSubview(labelView)
  }

  func performQRCodeDetection(image: CIImage) -> String? {
    var decode: String?
    if let detector = detector {
      let features = detector.features(in: image)
      for feature in features as! [CIQRCodeFeature] {
        decode = feature.messageString
      }
    }
    return decode
  }
}

extension ViewController: QRProcessor {
  // MARK: - QRProcessor

  public func didProcess(_ image: UIImage?, trace: UIImage?, qrCode: UIImage?, top: CGPoint, bottom: CGPoint, right: CGPoint, cross: CGPoint, found: Bool, orientation: QRProcessorOrientation) {
    originalImageView.image = image
    tracesImageView?.image = trace
    qrImageView?.image = qrCode
    
    decodedLabel.isHidden = true
    
    guard let image = image else {
      return
    }
    guard let cgImage = qrCode?.cgImage else {
      return
    }

    let ciImage = CIImage(cgImage: cgImage)
    if let decode = performQRCodeDetection(image: ciImage) {
      let bottomX = bottom.x
      let bottomY = bottom.y
      
      let dx = cross.x - bottomX
      let dy = cross.y - bottomY
      let angle = atan2(dy, dx)
      
      print("top: \(top) bottom: \(bottom) right: \(right) cross:\(cross) image: \(image.size) found: \(found) dx: \(dx) dy: \(dy) angle: \(angle) orientation: \(orientation)")

      decodedLabel.text = decode
      decodedLabel.sizeToFit()
      decodedLabel.setOrigin(origin: ViewController.labelPosition(imageView: originalImageView, image: image, origin: CGPoint(x: bottomX, y: bottomY)))
      decodedLabel.transform = CGAffineTransform(rotationAngle: angle)
      
      labelView.frame = CGRect(origin: ViewController.labelPosition(imageView: originalImageView, image: image, origin: CGPoint(x: bottomX, y: bottomY)), size: CGSize(width: 100, height: 100))
      labelView.transform = CGAffineTransform(rotationAngle: angle)
      
      timer?.invalidate()
      timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
        self.showLabel = false
      }
      showLabel = true
      decodedLabel.isHidden = false
    } else if showLabel {
      decodedLabel.isHidden = false
    }
  }
}

extension ViewController {
  fileprivate class func labelPosition(imageView: UIImageView, image: UIImage, origin: CGPoint) -> CGPoint {
    let kx = imageView.bounds.width/image.size.width
    let ky = imageView.bounds.height/image.size.height
    
    let x = origin.x * kx
    let y = origin.y * ky
    
    return CGPoint(x: x, y: y).integral
  }
}
