
import UIKit

class CreditsView: UIView {
  var view: UIView!
  
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var solView: UIView!
  
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
    configView()
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if previousTraitCollection!.userInterfaceStyle == .light {
      solView.radialGradient(colors: [UIColor(named: "CreditsViewLight")!, .clear])
    } else {
      solView.clearRadialGradient()
    }
    view.setNeedsDisplay()
  }
  
  private func configView() {
    
    let creditsPath = Bundle.main.url(forResource: "Credits", withExtension: "rtf")!
    let attributedString = try! NSMutableAttributedString(url: creditsPath, documentAttributes: nil)
    
    let paragraph = NSMutableParagraphStyle()
    paragraph.paragraphSpacing = 5
    paragraph.headIndent = 10
    paragraph.alignment = .justified
    paragraph.tabStops = [NSTextTab(textAlignment: .left, location: 15)]
    
    let attributes = [
      NSAttributedString.Key.paragraphStyle: paragraph,
    ]
    attributedString.addAttributes(attributes, range: NSRange(location:0, length: textView.attributedText.length))
    
    textView.attributedText = attributedString
    textView.isUserInteractionEnabled = true
    textView.isEditable = false
    textView.textColor = UIColor(named: "TextColor")
    textView.font = UIFont(name: "Helvetica", size: 14)!
    textView.linkTextAttributes = [
      .foregroundColor: UIColor(named: "hyperlink")!,
      .underlineColor: UIColor.clear
    ]
    if traitCollection.userInterfaceStyle == .dark {
      solView.radialGradient(colors: [UIColor(named: "CreditsViewLight")!, .clear])
    }
  }
}
