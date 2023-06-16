
import Foundation

extension Double {
    func roundTo(to places: Int) -> Double {
        let precision = pow (10, Double(places))
        var n = self
        n *= precision
        n.round()
        n /= precision
        return n
    }
  func formatToString() -> String {
    let formatter = NumberFormatter()
    formatter.groupingSeparator = " "
    formatter.numberStyle = .decimal
    if self > 10 {
      formatter.maximumFractionDigits = 0
    } else if self >= 0.01{
      formatter.maximumFractionDigits = 2
      formatter.minimumFractionDigits = 2
    } else {
      formatter.maximumFractionDigits = 3
      formatter.minimumFractionDigits = 3
    }
    return formatter.string(from: self as NSNumber)!
  }
  
}
