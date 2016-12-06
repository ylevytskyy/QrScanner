//
//  Bundle+Extensions.swift
//  QrScanner
//
//  Created by Yuriy Levytskyy on 12/6/16.
//  Copyright © 2016 Yuriy Levytskyy. All rights reserved.
//

import Foundation

extension Bundle {
  func loadNib<T>(as `class` : T.Type) -> T? {
    let nibName = "\(`class`)"
    guard let objects = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil) else {
      return nil
    }
    
    for currentObject in objects {
      if let object = currentObject as? T {
        return object
      }
    }
    return nil
  }
}
