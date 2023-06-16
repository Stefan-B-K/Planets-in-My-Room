
import UIKit

class InfoView: UIView {
  var view: UIView!
  
  @IBOutlet weak var radius: UILabel!
  @IBOutlet weak var mass: UILabel!
  @IBOutlet weak var gravity: UILabel!
  @IBOutlet weak var orbitalRadius: UILabel!
  @IBOutlet weak var orbitalPeriod: UILabel!
  @IBOutlet weak var rotationPeriod: UILabel!
  @IBOutlet weak var satellites: UILabel!
  @IBOutlet weak var url: UITextView!
  
  
  @IBOutlet weak var orbitalRadiusView: UIStackView!
  @IBOutlet weak var orbitalPeriodView: UIStackView!
  @IBOutlet weak var satellitesView: UIStackView!
  
  var celestial: Celestial? {
    didSet {
      configInfo()
      view.setNeedsDisplay()
    }
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    loadViewFromNib()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    loadViewFromNib()
  }
  
  private func loadViewFromNib() {
    let bundle = Bundle(for: type(of: self))
    let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
    let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
    view.frame = bounds
    view.autoresizingMask = [
      UIView.AutoresizingMask.flexibleWidth,
      UIView.AutoresizingMask.flexibleHeight
    ]
    addSubview(view)
    self.view = view
  }
  
  private func configInfo() {
    guard let celestial = celestial else {
      radius.text = ""
      mass.text = ""
      gravity.text = ""
      orbitalRadius.text = ""
      orbitalPeriod.text = ""
      rotationPeriod.text = ""
      satellites.text = ""
      url.attributedText = nil
      return
    }
    // RADIUS
    radius.text = (celestial.info.radius == 1
                   ? Double(Celestial.earthRadius).formatToString() + " km"
                   : celestial.info.radius.formatToString() + " × Earth")
    //MASS
    mass.attributedText = celestial.info.mass == 1
    ? "\(Celestial.earthMass.base) × 1021 t".attrSuperScript(from: 12, length: 2)
    : (celestial.info.mass.formatToString() + " × Earth").toAttributedString()
    // GRAVITY
    gravity.attributedText = celestial.info.gravity == 1
    ? "\(Celestial.earthGravity) m/s2".attrSuperScript(from: 7, length: 1)
    : (celestial.info.gravity.formatToString() + " × Earth").toAttributedString()
    // ORBITAL RADIUS
    if let orbitalRadius = celestial.info.orbitalRadius {
      self.orbitalRadiusView.isHidden = false
      self.orbitalRadius.text = {
        if orbitalRadius < 1 {
          return (orbitalRadius * 1_000_000).formatToString() + " km"
        }
        if orbitalRadius < 1000 {
          return "\(orbitalRadius) million km"
        }
        return "\((orbitalRadius / 1000).roundTo(to: 2)) billion km"
      }()
    }
    else { orbitalRadiusView.isHidden = true }
    // ORBITAL PERIOD
    if let orbitalPeriod = celestial.info.orbitalPeriod {
      self.orbitalPeriodView.isHidden = false
      self.orbitalPeriod.text = periodToString(orbitalPeriod)
    }
    else { orbitalPeriodView.isHidden = true }
    // ROTATION PERIOD
    rotationPeriod.text = periodToString(abs(celestial.info.rotationPeriod))
    rotationPeriod.text! += celestial.info.rotationPeriod < 0 ? " (retrograde)" : ""
    if let satellites = celestial.info.satellites {
      self.satellitesView.isHidden = false
      self.satellites.text = satellites.joined(separator: ", ")
    }
    else { satellitesView.isHidden = true }
    // MORE INFO
    let attributedString = NSMutableAttributedString(string: "Wikipedia")
    attributedString.setAttributes([.link: URL(string: celestial.info.url)!],
                                   range: NSMakeRange(0, 9))
    url.attributedText = attributedString
    url.isUserInteractionEnabled = true
    url.isEditable = false
    url.linkTextAttributes = [
        .foregroundColor: UIColor(named: "hyperlink")!,
        .underlineStyle: NSUnderlineStyle.single.rawValue,
        .font: UIFont(name: "Helvetica", size: 16)!
    ]
  }
  
  private func periodToString(_ period: Double) -> String {
    if period > 365 {
      return String(format: "%.01f", period / 365.2) + " years"
    }
    if period > 2 {
      return String(format: "%.f", period) + " days"
    }
    return String(format: "%.01f", (period * 24).roundTo(to: 1)) + " hours"
  }
  

  
  
}


