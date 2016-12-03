//
//  ViewController.swift
//  QrScanner
//
//  Created by Yuriy Levytskyy on 11/28/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  // MARK: - Properties
  
  fileprivate var qrScanner: QRScanner!

  fileprivate var timer: Timer?
  fileprivate var showLabel = false

  fileprivate lazy var detector: CIDetector? = {
    let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
    return CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: options)
  }()

  // MARK: - Outlets
  
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

    decodedLabel.layer.borderColor = UIColor.red.cgColor
    decodedLabel.layer.borderWidth = 1
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

extension ViewController: QRScannerProtocol {
  // MARK: - QRScannerProtocol

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
      // Calculate origin
      let origin = ViewController.position(inImageView: originalImageView, image: image, origin: CGPoint(x: bottom.x, y: bottom.y))
      let c = ViewController.position(inImageView: originalImageView, image: image, origin: CGPoint(x: cross.x, y: cross.y))
      
      // Calculate adjusted angle
      let dx = c.x - origin.x
      let dy = c.y - origin.y
      let angle = atan2(dy, dx)

      print("top: \(top) bottom: \(bottom) right: \(right) cross:\(cross) image: \(image.size) found: \(found) dx: \(dx) dy: \(dy) angle: \(angle) orientation: \(orientation)")

      // Update position, size and rotation
      decodedLabel.origin = origin
      decodedLabel.transform = CGAffineTransform(rotationAngle: angle)
      decodedLabel.text = decode
      decodedLabel.sizeToFit()

      // Update timer
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
  // MARK: - Implementation
  
  fileprivate class func position(inImageView imageView: UIImageView, image: UIImage, origin: CGPoint) -> CGPoint {
    let kx = imageView.bounds.width / image.size.width
    let ky = imageView.bounds.height / image.size.height

    let x = origin.x * kx
    let y = origin.y * ky

    return CGPoint(x: x, y: y).integral
  }
}
