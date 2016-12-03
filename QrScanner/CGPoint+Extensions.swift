//
//  CGPoint+Extensions.swift
//  QrScanner
//
//  Created by Yuriy Levytskyy on 12/3/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

import Foundation

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
