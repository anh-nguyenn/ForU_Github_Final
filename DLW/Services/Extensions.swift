//
//  Extensions.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import UIKit
import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension UIView {
    public var viewWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    public var viewHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
}

/// Allows the initialisation of a UIColor based on the hexcode.
extension UIColor {
    static var veryLightGray: UIColor = UIColor(red: 237, green: 237, blue: 237, alpha: 1)
    
    convenience init(rgb: UInt) {
            self.init(rgb: rgb, alpha: 1.0)
        }
    
    convenience init(rgb: UInt, alpha: CGFloat) {
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x0000FF) / 255.0,
                alpha: CGFloat(alpha)
            )
        }
}

/// Allows the initialisation of a Color based on the hexcode.
extension Color {
  init(_ hex: UInt, alpha: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: alpha
    )
  }
}
