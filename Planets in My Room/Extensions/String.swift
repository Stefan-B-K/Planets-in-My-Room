
import UIKit

extension String {
   func attrSuperScript(from: Int, length: Int) -> NSMutableAttributedString {
    let font: UIFont? = UIFont(name: "Helvetica", size:16)
    let fontSuper: UIFont? = UIFont(name: "Helvetica", size:10)
    let attString = NSMutableAttributedString(string: self, attributes: [.font:font!])
    attString.setAttributes([.font:fontSuper!, .baselineOffset:6], range: NSRange(location:from, length: length))
    return attString
  }
  
  func toAttributedString() -> NSMutableAttributedString {
    return NSMutableAttributedString(string: self)
  }
}
