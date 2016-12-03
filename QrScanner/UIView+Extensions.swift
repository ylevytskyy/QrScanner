//
//  UIView+Extensions.swift
//  QrScanner
//
//  Created by Yuriy Levytskyy on 12/3/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

import UIKit

extension UIView {
  var origin: CGPoint {
    get {
      return frame.origin
    }
    set {
      frame = CGRect(origin: newValue, size: frame.size)
    }
  }

  var size: CGSize {
    get {
      return frame.size
    }
    set {
      frame = CGRect(origin: frame.origin, size: newValue)
    }
  }
}
