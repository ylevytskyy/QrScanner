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
  var truncated: CGPoint {
    return CGPoint(x: Int(x), y: Int(y))
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

  public func didProcess(_ image: UIImage!, trace: UIImage!, qrCode: UIImage!, top: CGRect, bottom: CGRect, right: CGRect, cross: CGPoint, found: Bool, orientation: QRProcessorOrientation) {
    originalImageView.image = image
    tracesImageView?.image = trace
    qrImageView?.image = qrCode
    
    decodedLabel.isHidden = true

    let ciImage = CIImage(cgImage: qrCode.cgImage!)
    if let decode = performQRCodeDetection(image: ciImage) {
      print("top: \(top) bottom: \(bottom) right: \(right) image: \(image.size) found: \(found)")

      decodedLabel.text = decode
      decodedLabel.sizeToFit()
      decodedLabel.setOrigin(origin: ViewController.labelPosition(imageView: originalImageView, image: image, origin: bottom.origin + bottom.size))
      
      timer?.invalidate()
      timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
        self.showLabel = false
      }
      showLabel = true
      decodedLabel.isHidden = false
    } else if showLabel {
//      decodedLabel.setOrigin(origin: ViewController.labelPosition(imageView: originalImageView, image: image, origin: bottom.origin + bottom.size))
      decodedLabel.isHidden = !found
    }
  }
}

extension ViewController {
  fileprivate class func labelPosition(imageView: UIImageView, image: UIImage, origin: CGPoint) -> CGPoint {
    let kx = imageView.bounds.width/image.size.width
    let ky = imageView.bounds.height/image.size.height
    
    let x = origin.x * kx
    let y = origin.y * ky
    
    return CGPoint(x: x, y: y).truncated
  }
}
