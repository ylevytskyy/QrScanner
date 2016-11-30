//
//  ViewController.swift
//  QrScanner
//
//  Created by Yuriy Levytskyy on 11/28/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  fileprivate var qrScanner: QRScanner!

  lazy var detector: CIDetector? = {
    let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
    return CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: options)
  }()

  @IBOutlet weak var originalImageView: UIImageView!
  @IBOutlet weak var tracesImageView: UIImageView!
  @IBOutlet weak var qrImageView: UIImageView!
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

  public func didProcess(_ image: UIImage!, trace: UIImage!, qrCode: UIImage!, top: CGRect, bottom: CGRect, right: CGRect, cross:CGPoint, found: Bool, orientation: QRProcessorOrientation) {
    originalImageView.image = image
    tracesImageView.image = trace
    qrImageView.image = qrCode
    
    let ciImage = CIImage(cgImage: qrCode.cgImage!)
    if let decode = performQRCodeDetection(image: ciImage) {
      print("top: \(top) bottom: \(bottom) right: \(right) image: \(image.size) found: \(found)")
      
      decodedLabel.text = decode
    }
  }
}
