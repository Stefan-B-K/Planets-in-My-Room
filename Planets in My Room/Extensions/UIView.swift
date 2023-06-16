
import UIKit.UIView

extension UIView {
  // For insert layer in background
  func addSliderGradient(colors:[UIColor]){
    let gradient = CAGradientLayer()
    gradient.frame = self.bounds
    gradient.startPoint = CGPoint(x: 0.1, y: 0.5)
    gradient.endPoint = CGPoint(x: 0.9, y: 0.5)
    gradient.colors = colors.map{$0.cgColor}
    gradient.name = "slider"
    self.layer.insertSublayer(gradient, at: 0)
  }
  
  func clearSliderGradient() {
    self.layer.sublayers?.first { $0.name == "slider" }!.removeFromSuperlayer()
  }
  
  func radialGradient(colors:[UIColor]) {
    let gradient = CAGradientLayer()
    gradient.type = .radial
    gradient.frame = self.bounds
    gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
    gradient.endPoint = CGPoint(x: 1, y: 1)
    gradient.locations = [0.5, 1]
    gradient.colors = colors.map{$0.cgColor}
    gradient.name = "radial"
    self.layer.insertSublayer(gradient, at: 0)
  }
  
  func clearRadialGradient() {
    if let _ = self.layer.sublayers?.first (where: { $0.name == "radial" }) {
      self.layer.sublayers?.first { $0.name == "radial" }!.removeFromSuperlayer()
    }
  }
}
