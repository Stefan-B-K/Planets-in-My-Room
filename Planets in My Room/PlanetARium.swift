
import UIKit
import SceneKit
import ARKit
import AVFoundation.AVCaptureInput
import StoreKit

class PlanetARium: UIViewController, ARSCNViewDelegate {
  @IBOutlet weak var sceneView: ARSCNView!
  @IBOutlet weak var sliderBackgroundView: ARSCNView!
  
  @IBOutlet weak var nameView: UIView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var instructionView: UIView!
  @IBOutlet weak var instructionLabel: UILabel!
  @IBOutlet weak var infoButton: HapticButton!
  @IBOutlet weak var upgradeButton: HapticButton!
  
  @IBOutlet weak var popupView: UIView!
  @IBOutlet weak var creditsView: CreditsView!
  @IBOutlet weak var upgradeView: UIView!
  
  @IBOutlet weak var distanceUI: UIView!
  @IBOutlet weak var distTextField: UITextField!
  
  @IBOutlet weak var pauseResetUI: UIStackView!
  @IBOutlet weak var resetButton: UIButton!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var pausePlayButton: UIButton!
  @IBOutlet weak var labelsButton: HapticButton!
  
  @IBOutlet weak var infoView: InfoView!
  
  @IBOutlet weak var sliderView: UIView!
  @IBOutlet weak var slider: UISlider!
  @IBOutlet weak var sliderGradientView: UIView!
  
  
  var offsetY: CGFloat = 0
  var isSolSystemRotating = false {
    didSet {
      pausePlayButton.setImage(UIImage(systemName: isSolSystemRotating ? "pause.fill" : "play.fill"), for: .normal)
    }
  }
  var isCelestialSystemRotating = false {
    didSet {
      pausePlayButton.setImage(UIImage(systemName: isCelestialSystemRotating ? "pause.fill" : "play.fill"), for: .normal)
    }
  }
  var isCelestialRotating = false {
    didSet {
      pausePlayButton.setImage(UIImage(systemName: isCelestialRotating ? "pause.fill" : "play.fill"), for: .normal)
    }
  }
  var selectionLevel: Int? = nil
  var backgroundOpacity: Float = 0.5 {
    didSet {
      sceneView.scene.background.intensity = CGFloat(backgroundOpacity)
      Config.backgroundNode.isHidden = backgroundOpacity > 0
    }
  }
  var showingPlanetLabels = false {
    didSet {
      labelsButton.setImage(UIImage(systemName: showingPlanetLabels ? "text.bubble" : "text.bubble.fill"),
                            for: .normal)
    }
  }
  var showingSatelliteLabels = false {
    didSet {
      labelsButton.setImage(UIImage(systemName: showingSatelliteLabels ? "text.bubble" : "text.bubble.fill"),
                            for: .normal)
    }
  }
  var showingSpinner = false {
    didSet {
      if showingSpinner {
        if let spinner = view.viewWithTag(111) {
          spinner.isHidden = false
        }
      } else {
        if let spinner = view.viewWithTag(111) {
          spinner.removeFromSuperview()
        }
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    SKPaymentQueue.default().add(self)
    configButtons()
    sliderBackgroundView.translatesAutoresizingMaskIntoConstraints = false
    configTapGesture()
    initialSpinner()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    checkCamera() { succes in
      if succes {
        let configuration = ARWorldTrackingConfiguration()
        self.sceneView.session.run(configuration)
        self.sliderBackgroundView.session = self.sceneView.session
        self.sliderBackgroundView.session.run(configuration)
        
        self.sceneView.delegate = self
        self.sceneView.autoenablesDefaultLighting = false
        
      } else {
        let alert = UIAlertController(title: "The app can not be used without access to the camera!", message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Exit App", style: .default) { _ in
          exit(0)
        })
        DispatchQueue.main.async {
          self.present(alert, animated: true)
        }
      }
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    NotificationCenter.default.removeObserver(self)
    sceneView.session.pause()
    sliderBackgroundView.session.pause()
  }
  
  
  // MARK: UI methods
  
  @IBAction func distButton(_ sender: UIButton) {
    configLicensedContent()
    showingSpinner.toggle()
    sceneView.scene.background.intensity = CGFloat(backgroundOpacity)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      Config.composeSolarSystem(in: self.sceneView, radius: self.distTextField!) {
        self.sliderGradientView.addSliderGradient(colors:[.clear, .black])
        let sliderConstraints = [
          self.sliderBackgroundView.leadingAnchor.constraint(equalTo: self.sceneView.leadingAnchor),
          self.sliderBackgroundView.trailingAnchor.constraint(equalTo: self.sceneView.trailingAnchor),
          self.sliderBackgroundView.bottomAnchor.constraint(equalTo: self.sceneView.bottomAnchor),
          self.sliderBackgroundView.topAnchor.constraint(equalTo: self.sceneView.topAnchor)
        ]
        NSLayoutConstraint.activate(sliderConstraints)

        self.instructionView.isHidden = false
        self.pauseResetUI.isHidden = false
        self.isSolSystemRotating = true
        self.showingPlanetLabels = true
        self.showingSpinner.toggle()
      }
    }
    DispatchQueue.main.async {
      self.distTextField.endEditing(true)
      self.distanceUI.isHidden = true
    }
  }
  
  
  @IBAction func togglePopupView(_ sender: HapticButton) {
    let infoButtonClicked = sender.name == "info"
    let popUpDirection: CGFloat = infoButtonClicked ? 1 : -1
    
    let xTranslation = popupView.frame.width / 2
    let yTranslation = popupView.frame.height / 2
    if infoButtonClicked {
      infoButton.isEnabled = false
      creditsView.isHidden = false
    } else {
      upgradeButton.isEnabled = false
      upgradeView.isHidden = false
    }
    if popupView.isHidden {
      popupView.isHidden.toggle()
      popupView.transform = popupView.transform.translatedBy(x: xTranslation * popUpDirection, y: -yTranslation).scaledBy(x: 0.01, y: 0.01)
      let scaledTransform = popupView.transform.scaledBy(x: 100, y: 100).translatedBy(x: -xTranslation * popUpDirection, y: yTranslation)
      UIView.animate(withDuration: 0.7, delay: 0, options: UIView.AnimationOptions.curveEaseOut) {
        self.popupView.transform = scaledTransform
        self.popupView.alpha = 1
        self.toggleUI()
        if infoButtonClicked { self.upgradeButton.alpha = 0 }
        else { self.infoButton.alpha = 0 }
      } completion: { _ in
        if infoButtonClicked { self.infoButton.isEnabled = true }
        else { self.upgradeButton.isEnabled = true }
      }
    } else {
      let originalTransform = popupView.transform
      let zeroTransform = originalTransform.translatedBy(x: xTranslation * popUpDirection, y: -yTranslation).scaledBy(x: 0.01, y: 0.01)
      UIView.animate(withDuration: 0.7, delay: 0, options: UIView.AnimationOptions.curveEaseIn) {
        self.popupView.transform = zeroTransform
        self.popupView.alpha = 0
        self.toggleUI()
        if infoButtonClicked { self.upgradeButton.alpha = 1 }
        else { self.infoButton.alpha = 1 }
      } completion: { _ in
        self.popupView.isHidden.toggle()
        self.popupView.transform = originalTransform
        if infoButtonClicked {
          self.infoButton.isEnabled = true
          self.creditsView.isHidden = true
        } else {
          self.upgradeButton.isEnabled = true
          self.upgradeView.isHidden = true
        }
      }
    }
  }
  
  
  @IBAction func toggleLabels(_ sender: UIButton) {
    if selectionLevel == nil { togglePlanetLabes() }
    if selectionLevel == 1 { toggleSatelliteLabes() }
  }
  
  
  @IBAction func sliderMoved(_ sender: UISlider) {
    backgroundOpacity = 1 - sender.value
  }
  
  
  @IBAction func pausePlay(_ sender: UIButton? = nil) {
    switch selectionLevel {
    case 1:
      for satellite in Config.selectedPlanetSystemsOrbits {
        if isCelestialSystemRotating {
          satellite.value.removeAllActions()
        } else {
          satellite.value.rotateAnimation(duration: satellite.key.orbitFullCircle)
        }
      }
      isCelestialSystemRotating.toggle()
    case 2:
      let selectedCelestial = Config.selectedPlanetLevel1 ?? Config.selectedCelestialLevel2
      if isCelestialRotating {
        selectedCelestial?.removeAllActions()
      } else {
        let celestial = Celestial.allCases.first { $0.rawValue == selectedCelestial?.name }
        selectedCelestial!.rotateAnimation(duration: 15, retro: celestial!.info.rotationPeriod < 0)
      }
      isCelestialRotating.toggle()
    default:
      for celestial in Config.solOrbits {
        if isSolSystemRotating {
          celestial.value.removeAllActions()
        } else {
          celestial.value.rotateAnimation(duration: celestial.key.orbitFullCircle)
        }
      }
      isSolSystemRotating.toggle()
    }
  }
  
  
  @IBAction func reset(_ sender: UIButton) {
    Config.resetSolarSystem()
    pauseResetUI.isHidden = true
    pausePlayButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    distanceUI.isHidden = false
    isSolSystemRotating = false
    instructionView.isHidden = true
    backgroundOpacity = 0.5
    slider.value = 0.5
  }
  
  
  @IBAction func backToPreviousScene(_ sender: UIButton) {
    infoView.isHidden = true
    infoView.celestial = nil
    labelsButton.isHidden = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
      self.sliderGradientView.clearSliderGradient()
      self.sliderGradientView.addSliderGradient(colors:[.clear, .black])
    }
    if Config.selectedCelestialLevel2 == nil  {
      toggleButtons()
      Config.solSunLight.categoryBitMask = Config.sunLightCategoryBitmask
      
      Config.selectedPlanetSystemCenter?.runAction(Config.fadeOutAction) {
        Config.selectedPlanetSystemCenter?.removeFromParentNode()
        Config.solarSystem.runAction(Config.fadeInAction) {
          if !self.isSolSystemRotating {
            for celestial in Config.solOrbits {
              celestial.value.removeAllActions()
            }
          }
          Config.resetLevel1Selection()
          DispatchQueue.main.async {
            self.instructionView.isHidden = false
          }
        }
      }
      selectionLevel = nil
      isCelestialSystemRotating = false
      isCelestialRotating = false
      showingSatelliteLabels = false
      isSolSystemRotating = isSolSystemRotating ? true : false
      showingPlanetLabels = showingPlanetLabels ? true : false
    } else {
      Config.selectedCelestialLevel2Center?.runAction(Config.fadeOutAction) {
        Config.selectedCelestialLevel2Center?.removeFromParentNode()
        DispatchQueue.main.async {
          self.nameLabel.text = Config.selectedPlanetSystem?.name!.capitalized
          self.instructionView.isHidden = false
        }
        Config.selectedPlanetSystemCenter?.runAction(Config.fadeInAction)
        Config.resetLevel2Selection()
      }
      selectionLevel = 1
      isCelestialSystemRotating = isCelestialSystemRotating ? true : false
    }
  }
  
  
  // MARK: Helper methods

  private func configButtons() {
    nameView.layer.cornerRadius = 20
    nameView.isHidden = true
    instructionView.layer.cornerRadius = 20
    instructionView.isHidden = true
    
    infoButton.layer.cornerRadius = 8
    infoButton.name = "info"
    upgradeButton.layer.cornerRadius = 8
    upgradeButton.isHidden = licenseUpgraded
    
    popupView.layer.cornerRadius = 20
    popupView.clipsToBounds = true
    popupView.isHidden = true
    popupView.alpha = 0
    creditsView.isHidden = true
    upgradeView.isHidden = true
    
    infoView.layer.cornerRadius = 10
    infoView.isHidden = true
    
    pauseResetUI.isHidden = true
    sliderView.layer.cornerRadius = 8
    sliderView.clipsToBounds = true
    resetButton.layer.cornerRadius = 8
    pausePlayButton.layer.cornerRadius = 8
    backButton.layer.cornerRadius = 8
    backButton.isHidden = true
    labelsButton.layer.cornerRadius = 8
    
    configSlider()
  }
  
  
  private func configSlider() {
    let thumbImage = UIImage(named: "SliderThumb")!
    slider.setThumbImage(thumbImage, for: .normal)
    slider.setThumbImage(thumbImage, for: .highlighted)
    
    let insets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
    
    let trackLeftImage = UIImage(named: "SliderTrackLeft")!
    let trackLeftResizable = trackLeftImage.resizableImage(withCapInsets: insets)
    slider.setMinimumTrackImage(trackLeftResizable, for: .normal)
    
    let trackRightImage = UIImage(named: "SliderTrackRight")!
    let trackRightResizable = trackRightImage.resizableImage(withCapInsets: insets)
    slider.setMaximumTrackImage(trackRightResizable, for: .normal)
  }
  
  
  private func toggleButtons() {
    DispatchQueue.main.async {
      self.resetButton.isHidden.toggle()
      self.backButton.isHidden.toggle()
      self.nameView.isHidden.toggle()
    }
  }
  
  
  private func togglePlanetLabes() {
    for label in Config.labelsPlanet {
      label.opacity = label.opacity == 0 ? 1 : 0
    }
    showingPlanetLabels.toggle()
  }
  
  
  private func toggleUI() {
    nameView.alpha = nameView.alpha == 0 ? 1 : 0
    instructionView.alpha = instructionView.alpha == 0 ? 1 : 0
    infoView.alpha = infoView.alpha == 0 ? 1 : 0
    distanceUI.alpha = distanceUI.alpha == 0 ? 1 : 0
    pauseResetUI.alpha = pauseResetUI.alpha == 0 ? 1 : 0
    sceneView.alpha = sceneView.alpha == 1 ? 0.5 : 1
  }
  
  
  private func initialSpinner() {
    let spinner = UIActivityIndicatorView(style: .large)
    spinner.center.x = view.bounds.midX + 0.5
    spinner.center.y = view.bounds.midY + 0.5
    spinner.startAnimating()
    spinner.tag = 111
    spinner.isHidden = true
    spinner.transform = CGAffineTransformScale(CGAffineTransformIdentity, 2, 2);
    view.addSubview(spinner)
  }
  
  
  private func toggleSatelliteLabes() {
    for satLabel in Config.selectedSatellitesLabels {
      satLabel.isHidden.toggle()
    }
    showingSatelliteLabels.toggle()
  }
  
  
  private func configTapGesture() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(onScreenTap(_:)))
    tap.numberOfTapsRequired = 1
    sceneView.addGestureRecognizer(tap)
  }
  
  @objc private func onScreenTap(_ gesture: UITapGestureRecognizer) {
    guard popupView.isHidden else {
      if !creditsView.isHidden { togglePopupView(infoButton) }
      else { togglePopupView(upgradeButton) }
      return
    }

    guard distanceUI.isHidden else { view.endEditing(true); return }
    
    let currentTouchLocation = gesture.location(in: sceneView)
    
    // level 1 selection - solar system
    guard let _ = Config.selectedPlanetSystem else {
      selectionLevelOne(currentTouchLocation)
      return
    }
    
    // zoomInOut on tap
    let selectedCelestial = [Config.selectedPlanetLevel1, Config.selectedCelestialLevel2].compactMap { $0 }.first
    if let selectedCelestial = selectedCelestial, let selectedDistance = Config.selectedDistance {
      zoomInOutCelestial(selectedCelestial, distance: selectedDistance)
      return
    }
    
    // level 2 selection - planet system - zoom to planet/satellite
    guard var hitNode = self.sceneView.hitTest(currentTouchLocation, options: nil).first?.node,
          let hitNodeName = hitNode.name,
          Celestial.allNames.dropFirst(1).contains(hitNodeName)
    else { return }
    hitNode = hitNode.clone()
    Config.selectedCelestialLevel2 = hitNode
    makeZoomedScene(Config.selectedCelestialLevel2!)
    selectionLevel = 2
    isCelestialRotating = true
  }
  
  
  private func selectionLevelOne(_ currentTouchLocation: CGPoint) {
    let licensedCelestials = licenseUpgraded
    ? Celestial.planets
    : [Celestial.sun.rawValue, Celestial.mercury.rawValue, Celestial.venus.rawValue, Celestial.earth.rawValue, Celestial.mars.rawValue]
    
    guard var hitNode = self.sceneView.hitTest(currentTouchLocation, options: nil).first?.node,
          let hitNodeName = hitNode.name,
          licensedCelestials.contains(hitNodeName) else { return }
    
    let celestial = Celestial.allCases.first(where: { $0.rawValue == hitNodeName })
    if case let celestial = celestial, celestial?.type == .planet, celestial?.satellites != nil {
      hitNode = hitNode.parent!
      nameLabel.text = hitNode.name?.capitalized
      hitNode = hitNode.clone()
      Config.selectedPlanetSystem = hitNode
      selectionLevel = 1
      isCelestialSystemRotating = true
      
      let satOrbitsNode = hitNode.childNodes.first { $0.name!.contains("-satellites") }!
      
      let sarLabelsNodes = satOrbitsNode.childNodes.compactMap { $0.childNodes }.flatMap { $0 }.compactMap { $0.childNodes.first }
      for node in sarLabelsNodes {
        Config.selectedSatellitesLabels.append(node)
      }
      toggleSatelliteLabes()
      hitNode.childNodes.first { $0.name!.contains("-label")}?.isHidden = true
      
      for satNode in satOrbitsNode.childNodes where satNode.name!.contains("-orbit") {
        let satellite = Celestial.allCases.compactMap { $0.satellites }.flatMap { $0 }.first { $0.rawValue + "-orbit" == satNode.name }!
        Config.selectedPlanetSystemsOrbits[satellite] = satNode
      }
      
    } else {
      hitNode = hitNode.clone()
      Config.selectedPlanetSystem =  hitNode
      Config.selectedPlanetLevel1 = hitNode
      nameLabel.text = hitNodeName.capitalized
      selectionLevel = 2
      isCelestialRotating = true
    }
    
    makeZoomedScene(Config.selectedPlanetSystem!)
  }
  
  
  private func zoomInOutCelestial(_ selectedCelestial: SCNNode, distance selectedDistance: Float) {
    let newDistance = selectedDistance / (selectedCelestial.name == "saturn" ? 1.57 : (selectedCelestial.name == "uranus" ? 2.09 : 2.47))
    let verticalPosition = selectedDistance / (selectedCelestial.name == "saturn" ? 9.4 : (selectedCelestial.name == "uranus" ? 11.7 : 7.60))
    let zoomCase: Float = Config.slelectedCelestialZoomed ? -1 : 1
    let move = SCNAction.move(by: SCNVector3(x: +selectedDistance / 140 * zoomCase,
                                             y: -verticalPosition * zoomCase,
                                             z: newDistance * zoomCase),
                              duration: 0.5)
    selectedCelestial.runAction(move)
    Config.slelectedCelestialZoomed.toggle()
  }
  
  
  private func makeZoomedScene(_ celectialNode: SCNNode) {
    let radius, verticalPosition: Float!
    if celectialNode.name == Celestial.uranus.rawValue || celectialNode.name == Celestial.saturn.rawValue {
      let ringsNode = celectialNode.childNodes.first { $0.name == celectialNode.name! + "-rings"}
      radius = Float((ringsNode!.geometry as! SCNBox).width/2) * 0.65 //0.68   // fit Uranus rings in the screen
      verticalPosition = radius / (celectialNode.name == Celestial.saturn.rawValue ? 3.0 : 4.0)
    } else {
      if let celestial = Celestial.allCases.first(where: { $0.rawValue + " system" == celectialNode.name }) {
        let satellitesNode = celectialNode.childNodes.first { $0.name == celestial.rawValue + "-satellites"}
        let outerOrbitNode = satellitesNode?.childNodes.last { $0.geometry is SCNTorus}
        radius = Float((outerOrbitNode?.geometry as! SCNTorus).ringRadius) * 0.95   // fit outer satellite orbit in the screen
        verticalPosition = radius / 4.0
      } else {
        radius = Float((celectialNode.geometry as! SCNSphere).radius)   // just fit the planet/sun  in the screen
        verticalPosition = radius / 2.5
      }
    }
    Config.selectedDistance = radius * 3.3
    celectialNode.position =  SCNVector3(x: 0,  //-Config.selectedDistance! / 85
                                         y: verticalPosition,
                                         z: -Config.selectedDistance! )
    if Config.selectedCelestialLevel2 == nil {
      levelOneZoom(celectialNode) }
    else {
      levelTwoZoom(celectialNode) }
  }
  
  
  private func levelOneZoom(_ celectialNode: SCNNode) {
    let lights = SCNNode()
    lights.position = SCNVector3(-2, 0, 1)
    lights.addChildNode(Config.sunOmniLightNode())
    Config.solSunLight.categoryBitMask = 0
    
    if celectialNode.name == "sun" { celectialNode.addSunBloom() }
    
    Config.solarSystem.runAction(Config.fadeOutAction) {
      Config.selectedPlanetSystemCenter = SCNNode()
      Config.selectedPlanetSystemCenter!.position = SCNVector3(0, 0, 0)
      Config.selectedPlanetSystemCenter!.addChildNode(celectialNode)
      Config.selectedPlanetSystemCenter!.addChildNode(lights)
      self.sceneView.pointOfView?.opacity = 0
      self.sceneView.pointOfView?.addChildNode(Config.selectedPlanetSystemCenter!)
      self.sceneView.pointOfView?.runAction(Config.fadeInAction)
      self.toggleButtons()
      if Config.selectedPlanetLevel1 != nil {
        DispatchQueue.main.async {
          self.configInfoView(for: celectialNode)
          self.infoView.isHidden = false
          self.instructionView.isHidden = true
          self.labelsButton.isHidden = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
          self.sliderGradientView.clearSliderGradient()
          self.sliderGradientView.addSliderGradient(colors:[.clear, .black])
        }
      }
    }
    
  }
  
  
  private func levelTwoZoom(_ celectialNode: SCNNode) {
    Config.selectedPlanetSystemCenter?.runAction(Config.fadeOutAction) {
      Config.selectedCelestialLevel2Center = SCNNode()
      Config.selectedCelestialLevel2Center!.position = SCNVector3(0, 0, 0)
      Config.selectedCelestialLevel2Center!.addChildNode(celectialNode)
      self.sceneView.pointOfView?.opacity = 0
      self.sceneView.pointOfView?.addChildNode(Config.selectedCelestialLevel2Center!)
      self.sceneView.pointOfView?.runAction(Config.fadeInAction)
      DispatchQueue.main.async {
        self.nameLabel.text = Config.selectedCelestialLevel2?.name?.capitalized
        self.instructionView.isHidden = true
        self.configInfoView(for: celectialNode)
        self.infoView.isHidden = false
        self.labelsButton.isHidden = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
        self.sliderGradientView.clearSliderGradient()
        self.sliderGradientView.addSliderGradient(colors:[.clear, .black])
      }
    }
  }
  
  
  private func configInfoView(for celestialNode: SCNNode ) {
    infoView.celestial = Celestial.allCases.first { $0.rawValue == celestialNode.name }
  }
}


// MARK: In-App Purchase

extension PlanetARium: SKPaymentTransactionObserver {
  var licenseUpgraded: Bool {
    return UserDefaults.standard.bool(forKey: productID)
  }
  
  private func configLicensedContent() {
    let licenseUpgraded = licenseUpgraded
    upgradeButton.isHidden = licenseUpgraded
    sliderView.alpha = licenseUpgraded ? 1 : 0.3
    sliderView.isUserInteractionEnabled = licenseUpgraded
    resetButton.isEnabled = licenseUpgraded
    labelsButton.isEnabled = licenseUpgraded
    resetButton.alpha = licenseUpgraded ? 1 : 0.5
    labelsButton.alpha = licenseUpgraded ? 1 : 0.5
    pauseResetUI.isUserInteractionEnabled = true
    instructionLabel.text = "Tap on " + (licenseUpgraded ? "celestial body" : "inner planet") + " to zoom in"
  }
  
  private var productID: String {
    return getAPI(forKey: "ProductID")
  }
  
  private func getAPI(forKey: String) -> String {
    let dataFilePath = Bundle.main.url(forResource: "Private", withExtension: "plist")
    let data = try! Data(contentsOf: dataFilePath!)
    let result = try! PropertyListDecoder().decode([String:String].self, from: data)
    return result[forKey]!
  }
  
  @objc func buyUpgrade() {
    if SKPaymentQueue.canMakePayments() {
      let paymentRequest = SKMutablePayment()
      paymentRequest.productIdentifier = productID
      togglePopupView(upgradeButton)
      SKPaymentQueue.default().add(paymentRequest)
    } else {
      let alert = UIAlertController(title: "User not allowed to make payments", message: nil, preferredStyle: UIAlertController.Style.alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel))
      present(alert, animated: true)
    }
  }
  
  @objc func restoreUpgrade() {
    togglePopupView(upgradeButton)
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
  
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions where transaction.payment.productIdentifier == productID {
      if transaction.transactionState == .purchased || transaction.transactionState == .restored {
        UserDefaults.standard.setValue(true, forKey: productID)
        configLicensedContent()
        SKPaymentQueue.default().finishTransaction(transaction)
      } else if transaction.transactionState == .failed {
        print("Payment failed: \(transaction.error?.localizedDescription ?? "???")")
        SKPaymentQueue.default().finishTransaction(transaction)
      }
    }
  }

}
