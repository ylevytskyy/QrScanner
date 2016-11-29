//
//  ViewController.swift
//  QrScanner
//
//  Created by Yuriy Levytskyy on 11/28/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  fileprivate let qrScanner = QRScanner()

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

    qrScanner.delegate = self
    qrScanner.start()

    DispatchQueue.global().async {
      while true {
        self.qrScanner.process()
      }
    }
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

  func didProcess(_ image: UIImage!, traces: UIImage!, qrCode: UIImage!) {
    originalImageView.image = image
    tracesImageView.image = traces
    qrImageView.image = qrCode

    let ciImage = CIImage(cgImage: qrCode.cgImage!)
    if let decode = performQRCodeDetection(image: ciImage) {
      decodedLabel.text = decode
    }
  }
}
