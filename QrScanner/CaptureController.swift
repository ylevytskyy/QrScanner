//
//  CaptureController.swift
//  QrScanner
//
//  Created by Yuriy Levytskyy on 12/1/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

import UIKit
import AVFoundation

class CaptureController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
  @IBOutlet weak var originalImageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupCameraSession()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    //    view.layer.addSublayer(previewLayer)
    
    cameraSession.startRunning()
  }
  
  lazy var cameraSession: AVCaptureSession = {
    let s = AVCaptureSession()
    s.sessionPreset = AVCaptureSessionPresetLow
    return s
  }()
  
  //  lazy var previewLayer: AVCaptureVideoPreviewLayer = {
  //    let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
  //    preview?.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
  //    preview?.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
  //    preview?.videoGravity = AVLayerVideoGravityResize
  //    return preview!
  //  }()
  
  func setupCameraSession() {
    let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) as AVCaptureDevice
    
    do {
      let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
      
      cameraSession.beginConfiguration()
      
      if (cameraSession.canAddInput(deviceInput) == true) {
        cameraSession.addInput(deviceInput)
      }
      
      //      let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
      //      let audioInput = try! AVCaptureDeviceInput(device: audioDevice)
      //      cameraSession.addInput(audioInput)
      
      let dataOutput = AVCaptureVideoDataOutput()
      dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
      dataOutput.alwaysDiscardsLateVideoFrames = true
      
      if (cameraSession.canAddOutput(dataOutput) == true) {
        cameraSession.addOutput(dataOutput)
      }
      
      cameraSession.sessionPreset = AVCaptureSessionPreset640x480;
      
      cameraSession.commitConfiguration()
      
      let queue = DispatchQueue(label: "com.epam.videoQueue")
      dataOutput.setSampleBufferDelegate(self, queue: queue)
    }
    catch let error as NSError {
      NSLog("\(error), \(error.localizedDescription)")
    }
  }
  
  // MARK: = AVCaptureVideoDataOutputSampleBufferDelegate
  
  func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
    // Here you collect each frame and process it
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)! as CVImageBuffer
    let ciImage = CIImage(cvImageBuffer: pixelBuffer)
    let context = CIContext()
    let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer)))!
    let uiImage = UIImage(cgImage: cgImage)
    DispatchQueue.main.async {
      self.originalImageView.image = uiImage
    }
  }
  
  func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
    // Here you can count how many frames are dropped
  }
}
