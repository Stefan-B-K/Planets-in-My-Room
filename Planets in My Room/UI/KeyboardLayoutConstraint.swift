
import UIKit

public class KeyboardLayoutConstraint: NSLayoutConstraint {
  
  private var offset : CGFloat = 0
  private var keyboardVisibleHeight : CGFloat = 0
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    offset = constant
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(KeyboardLayoutConstraint.keyboardWillShowNotification(_:)),
                                           name: UIWindow.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(KeyboardLayoutConstraint.keyboardWillHideNotification(_:)),
                                           name: UIWindow.keyboardWillHideNotification, object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  // MARK: Notification
  
  @objc func keyboardWillShowNotification(_ notification: Notification) {
    if let userInfo = notification.userInfo {
      if let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
        let frame = frameValue.cgRectValue
        keyboardVisibleHeight = frame.size.height
      }
      
      self.updateConstant()
      switch (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber, userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber) {
      case let (.some(duration), .some(curve)):
        
        let options = UIView.AnimationOptions(rawValue: curve.uintValue)
        let keyWindow = UIApplication.shared.connectedScenes
          .filter({$0.activationState == .foregroundActive})
          .compactMap({$0 as? UIWindowScene})
          .first?.windows
          .filter({$0.isKeyWindow}).first
        DispatchQueue.main.async {
          UIView.animate(
            withDuration: TimeInterval(duration.doubleValue),
            delay: 0,
            options: options,
            animations: {
              keyWindow?.layoutIfNeeded()
              return
            }, completion: nil)
        }
        
      default:
        
        break
      }
      
    }
    
  }
  
  @objc func keyboardWillHideNotification(_ notification: NSNotification) {
    keyboardVisibleHeight = 0
    self.updateConstant()
    
    if let userInfo = notification.userInfo {
      
      switch (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber, userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber) {
      case let (.some(duration), .some(curve)):
        
        let options = UIView.AnimationOptions(rawValue: curve.uintValue)
        let keyWindow = UIApplication.shared.connectedScenes
          .filter({$0.activationState == .foregroundActive})
          .compactMap({$0 as? UIWindowScene})
          .first?.windows
          .filter({$0.isKeyWindow}).first
        DispatchQueue.main.async {
          UIView.animate(
            withDuration: TimeInterval(duration.doubleValue),
            delay: 0,
            options: options,
            animations: {
              keyWindow?.layoutIfNeeded()
              return
            }, completion: { finished in
            })
        }
      default:
        break
      }
    }
  }
  
  func updateConstant() {
    self.constant = offset - keyboardVisibleHeight
  }
  
}
