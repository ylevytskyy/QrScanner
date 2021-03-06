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

  fileprivate var infoView: InfoView!

  fileprivate lazy var detector: CIDetector? = {
    let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
    return CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: options)
  }()

  // MARK: - Outlets

  @IBOutlet weak var originalImageView: UIImageView!
  @IBOutlet weak var tracesImageView: UIImageView?
  @IBOutlet weak var qrImageView: UIImageView?
  @IBOutlet weak var orientationLabel: UILabel!
}

extension ViewController {
  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    qrScanner = QRScanner()
    qrScanner?.delegate = self
    qrScanner?.start()

    infoView = Bundle.main.loadNib(as: InfoView.self)
    infoView.layer.anchorPoint = CGPoint.zero
    infoView.layer.borderColor = UIColor.black.cgColor
    infoView.layer.borderWidth = 1
    view.addSubview(infoView)
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

    infoView.isHidden = true
    orientationLabel.isHidden = true

    guard let image = image else {
      return
    }
    guard let cgImage = qrCode?.cgImage else {
      return
    }

    if found {
      let ciImage = CIImage(cgImage: cgImage)
      if let decoded = performQRCodeDetection(image: ciImage) {
        infoView.decodedLabel.text = decoded
      }

      // Set position
      setPosition(view: infoView, leftPoint: bottom, rightPoint: cross, image: image, decoded: infoView.decodedLabel.text)

      // Update timer
      timer?.invalidate()
      timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
        self.showLabel = false
        self.infoView.decodedLabel.text = nil
      }

      // Update UI state
      showLabel = infoView.decodedLabel.text != nil
    }

    if showLabel {
      infoView.isHidden = false
      orientationLabel.isHidden = false
    }
  }
}

extension ViewController {
  // MARK: - Implementation

  private class func position(inImageView imageView: UIImageView, image: UIImage, origin: CGPoint) -> CGPoint {
    let kx = imageView.bounds.width / image.size.width
    let ky = imageView.bounds.height / image.size.height

    let x = origin.x * kx
    let y = origin.y * ky

    return CGPoint(x: x, y: y).integral
  }

  fileprivate func setPosition(view: UIView, leftPoint: CGPoint, rightPoint: CGPoint, image: UIImage, decoded: String?) {
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
    view.transform = CGAffineTransform.identity
    view.frame = self.view.bounds
    view.origin = l
    view.size = view.systemLayoutSizeFitting(UILayoutFittingExpandedSize)
    view.transform = CGAffineTransform(rotationAngle: angle)
  }
}
