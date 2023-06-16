
import UIKit

class UpgradeView: UIView {
  var view: UIView!
  
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var buyButton: UIButton!
  @IBOutlet weak var restoreButton: UIButton!
  
  var parentVC: PlanetARium? {
    return self.next as? PlanetARium
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
    configView()
  }
  
  private func configView() {
    buyButton.layer.cornerRadius = 8
    restoreButton.layer.cornerRadius = 8
    
    buyButton.addTarget(parentVC, action: #selector(parentVC?.buyUpgrade), for: .touchUpInside)
    restoreButton.addTarget(parentVC, action: #selector(parentVC?.restoreUpgrade), for: .touchUpInside)
    
    let upgradeInfoPath = Bundle.main.url(forResource: "UpgradeInfo", withExtension: "rtf")!
    let attributedString = try! NSMutableAttributedString(url: upgradeInfoPath, documentAttributes: nil)

    let paragraph = NSMutableParagraphStyle()
    paragraph.paragraphSpacing = 12
    paragraph.lineSpacing = 15
    paragraph.alignment = .justified

    let attributes = [
      NSAttributedString.Key.paragraphStyle: paragraph,
    ]
    attributedString.addAttributes(attributes, range: NSRange(location:0, length: textView.attributedText.length))

    textView.attributedText = attributedString
    textView.isUserInteractionEnabled = false
    textView.isEditable = false
    textView.textColor = UIColor(named: "TextColor")
    textView.font = UIFont(name: "Helvetica", size: 18)!
  }
  
  
  @IBAction func buyPressed(_ sender: UIButton) {

  }
  
  @IBAction func restorePressed(_ sender: UIButton) {

  }
}
