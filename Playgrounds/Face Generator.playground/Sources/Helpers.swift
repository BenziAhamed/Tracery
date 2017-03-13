import Foundation
import UIKit

public extension UIColor {
    
    convenience init(hex:String) {
        var rgb:CUnsignedInt = 0
        let scanner = Scanner(string: hex)
        if hex.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        scanner.scanHexInt32(&rgb)
        let r:CGFloat = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g:CGFloat = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b:CGFloat = CGFloat((rgb & 0x0000FF))  / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
    
}
