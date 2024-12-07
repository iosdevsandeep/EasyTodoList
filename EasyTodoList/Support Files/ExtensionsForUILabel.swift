//
//  ExtensionsForUILabel.swift
//  EasyTodoList
//
//  Created by Vupadhi iOS on 06/12/24.
//

import Foundation
import UIKit

extension UILabel {
    var strikeThrough: Bool {
        get {
            return true
        }
        set {
            if newValue {
                let attributtedString = NSMutableAttributedString(string: self.text ?? "")
                attributtedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: attributtedString.length))
                attributtedString.addAttribute(.foregroundColor, value: UIColor.systemGray, range: NSRange(location: 0, length: attributtedString.length))
                self.attributedText = attributtedString
            }
            else {
                let attributtedString = NSMutableAttributedString(string: self.text ?? "")
                self.attributedText = attributtedString
            }
        }
    }
}
