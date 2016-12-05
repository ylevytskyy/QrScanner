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
  @IBOutlet weak var orientationLabel: UILabel!
}

extension ViewController {
  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    qrScanner = QRScanner()
    qrScanner?.delegate = self
    qrScanner?.start()

    decodedLabel.layer.anchorPoint = CGPoint.zero

    decodedLabel.layer.borderColor = UIColor.red.cgColor
    decodedLabel.layer.borderWidth = 1
  }

  func performQRCodeDetection(image: CIImage) -> String? {
    guard let detector = detector else {
      return nil
    }

    let features = detector.features(in: image)
    for feature in features as! [CIQRCodeFeature] {
      if let decoded = feature.messageString {
        return decoded
      }
    }

    return nil
  }
}

extension ViewController: QRScannerProtocol {
  // MARK: - QRScannerProtocol

  public func didProcess(_ image: UIImage?, trace: UIImage?, qrCode: UIImage?, top: CGPoint, bottom: CGPoint, right: CGPoint, cross: CGPoint, found: Bool, orientation: QRCodeOrientation) {
    originalImageView.image = image
    tracesImageView?.image = trace
    qrImageView?.image = qrCode

    orientationLabel.text = "\(orientation) + \(orientation.rawValue)"

    decodedLabel.isHidden = true
    orientationLabel.isHidden = true

    guard let image = image else {
      return
    }
    guard let cgImage = qrCode?.cgImage else {
      return
    }

    let ciImage = CIImage(cgImage: cgImage)
    if let decoded = performQRCodeDetection(image: ciImage) {
      // Set position
      setPosition(leftPoint: bottom, rightPoint: cross, image: image, decoded: decoded)

      // Update timer
      timer?.invalidate()
      timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
        self.showLabel = false
      }

      // Update UI state
      showLabel = true
      decodedLabel.isHidden = false
      orientationLabel.isHidden = false
    } else if showLabel {
      decodedLabel.isHidden = false
      orientationLabel.isHidden = false
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

  fileprivate func setPosition(leftPoint: CGPoint, rightPoint: CGPoint, image: UIImage, decoded: String?) {
    //
    // Calculate adjusted position
    let l = ViewController.position(inImageView: originalImageView, image: image, origin: CGPoint(x: leftPoint.x, y: leftPoint.y))
    let r = ViewController.position(inImageView: originalImageView, image: image, origin: CGPoint(x: rightPoint.x, y: rightPoint.y))

    //
    // Calculate adjusted angle
    let dx = r.x - l.x
    let dy = r.y - l.y
    let angle = atan2(dy, dx)

    //
    // Update position, size and rotation
    decodedLabel.transform = CGAffineTransform.identity
    decodedLabel.origin = l
    decodedLabel.transform = CGAffineTransform(rotationAngle: angle)

    decodedLabel.text = decoded
    decodedLabel.sizeToFit()
  }
}
