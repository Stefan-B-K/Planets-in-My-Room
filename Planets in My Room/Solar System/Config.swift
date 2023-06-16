
import SceneKit
import ARKit

enum Config {
  
  static var solarSystemRadius: Float = 1
  static var modelCenter: SCNNode!
  static var solarSystem: SCNNode!
  static var solOrbits = [Celestial:SCNNode]()
  static var solSunLight: SCNLight!
  static let sunLightCategoryBitmask = 1
  static var labelsPlanet = [SCNNode]()
  static var labelsSatellite = [SCNNode]()
  
  static var selectedPlanetSystem: SCNNode?
  static var selectedPlanetSystemsOrbits = [Celestial:SCNNode]()
  static var selectedSatellitesLabels = [SCNNode]()
  static var selectedPlanetLevel1: SCNNode?
  static var selectedCelestialLevel2: SCNNode?
  static var selectedDistance: Float?
  static var slelectedCelestialZoomed = false
  static var selectedPlanetSystemCenter: SCNNode?
  static var selectedCelestialLevel2Center: SCNNode?
  
  static let fadeOutAction = SCNAction.fadeOut(duration: 0.5)
  static let fadeInAction = SCNAction.fadeIn(duration: 0.5)
  
  static var backgroundNode: SCNNode!
  

  static func composeSolarSystem(in sceneView: ARSCNView, radius: UITextField, onFinish: @escaping () -> () ) {
    solarSystemRadius = radius.text != "" ? Float(radius.text!.replacingOccurrences(of: ",", with: "."))! : 1
    setSolCenter(relativeToCamera: sceneView.pointOfView!)
    solarSystem = SCNNode()
    solarSystem.position = SCNVector3(0, 0, 0)
    let sunLightNode = Config.sunOmniLightNode()
    solSunLight = sunLightNode.light
    solarSystem.addChildNode(sunLightNode)
    solarSystem.addSatellitesOrbits(for: .sun)
    addCelestial(.sun)
    for celestial in Celestial.sun.satellites! {
      addCelestial(celestial)
    }
    backgroundNode = addBackground()
    backgroundNode.isHidden = true
    modelCenter.addChildNode(backgroundNode)
    modelCenter.addChildNode(solarSystem)
   
    sceneView.scene.rootNode.addChildNode(modelCenter)
    onFinish()
  }
  
  
  static func resetSolarSystem() {
    solarSystemRadius = 1
    modelCenter.removeFromParentNode()
    modelCenter = nil
    solOrbits = [:]
  }
  
  static func resetLevel1Selection() {
    selectedPlanetSystem = nil
    selectedPlanetLevel1 = nil
    selectedDistance = nil
    slelectedCelestialZoomed = false
    selectedPlanetSystemCenter = nil
  }
  
  static func resetLevel2Selection() {
    selectedCelestialLevel2 = nil
    slelectedCelestialZoomed = false
  }
  
  static func addCelestial(_ celestial: Celestial) {
    let material = SCNMaterial()
    material.diffuse.contents = UIImage(named: celestial.rawValue)
    
    
    if celestial == .earth {    // night earth texture for the dark side
      let emissionTexture = UIImage(named: "earthNight")!
      let emission = SCNMaterialProperty(contents: emissionTexture)
      material.setValue(emission, forKey: "emissionTexture")
      let shaderModifier =
      """
      uniform sampler2D emissionTexture;
      
      vec3 light = _lightingContribution.diffuse;
      float lum = max(0.0, 1 - (0.2126*light.r + 0.7152*light.g + 0.0722*light.b));
      vec4 emission = texture2D(emissionTexture, _surface.diffuseTexcoord) * lum;
      _output.color += emission;
      """
      material.shaderModifiers = [.fragment: shaderModifier]
    }
    
    if celestial == .sun { material.lightingModel = .constant }
    
    let sphere = SCNSphere(radius: celestial.radius)
    sphere.materials = [material]
    sphere.segmentCount = 200
    
    guard celestial != .sun else {
      let celestialNode = SCNNode()
      celestialNode.position = SCNVector3(0, 0, 0)
      celestialNode.geometry = sphere
      celestialNode.name = celestial.rawValue
      celestialNode.addSunBloom()
      
      solarSystem.addChildNode(celestialNode)
      labelsPlanet.append(solarSystem.addLabel(for: celestial))
      celestialNode.rotateAnimation(duration: celestial == .sun ? 30 : 0)
      
      return
    }
    
    let celestialOrbitNode = SCNNode()
    celestialOrbitNode.position = SCNVector3(0, 0, 0)
    
    let celestialNode = setCelestialPosition(relativeTo: celestialOrbitNode, angle: celestial.angle, orbit: celestial.orbit)
    celestialNode.name = celestial.rawValue + " system"
    let planetNode = SCNNode()
    planetNode.position = SCNVector3(0, 0, 0)
    planetNode.geometry = sphere
    planetNode.name = celestial.rawValue
    planetNode.categoryBitMask = sunLightCategoryBitmask
    
    var axisNode = SCNNode()
    axisNode.name = celestial.rawValue + "-axis"
    axisNode.categoryBitMask = sunLightCategoryBitmask
    let axisY = celestial.radius * 1.2
    axisNode = axisNode.buildLineInTwoPointsWithRotation(from: SCNVector3(0, -axisY, 0), to: SCNVector3(0, axisY, 0), radius: CGFloat(solarSystemRadius)/30000, color: .cyan)
    planetNode.addChildNode(axisNode)
    
    if celestial.hasRings { planetNode.addChildNode(addRings(celestial: celestial)) }
    
    if celestial.axialTilt != 0 { planetNode.tiltAxis(angle: celestial.axialTilt) }
  
    if let satellites = celestial.satellites {
      let satellitesNode = SCNNode()
      satellitesNode.position = SCNVector3(0, 0, 0)
      satellitesNode.name = celestial.rawValue + "-satellites"
      satellitesNode.addSatellitesOrbits(for: celestial)
      for sat in satellites {
        addSatellite(sat, to: satellitesNode)
      }
      satellitesNode.tiltAxis(angle: celestial.axialTilt)
      celestialNode.addChildNode(satellitesNode)
    }
    
    celestialNode.addChildNode(planetNode)
    celestialOrbitNode.addChildNode(celestialNode)
    labelsPlanet.append(celestialNode.addLabel(for: celestial))
    solarSystem.addChildNode(celestialOrbitNode)
    
    celestialOrbitNode.rotateAnimation(duration: celestial.orbitFullCircle)
    planetNode.rotateAnimation(duration: 15.0, retro: celestial.info.rotationPeriod < 0)
    
    solOrbits[celestial] = celestialOrbitNode
  }
  
  
  static func addSatellite(_ satellite: Celestial, to celestialNode: SCNNode) {
    let sphere = SCNSphere(radius: satellite.radius)
    sphere.firstMaterial?.diffuse.contents = UIImage(named: satellite.rawValue)
    
    let satelliteOrbitNode = SCNNode()
    satelliteOrbitNode.position = SCNVector3(0, 0, 0)
    satelliteOrbitNode.name = satellite.rawValue + "-orbit"
    
    let satelliteNode = setCelestialPosition(relativeTo: satelliteOrbitNode, angle: satellite.angle, orbit: satellite.orbit)
    satelliteNode.geometry = sphere
    satelliteNode.categoryBitMask = Config.sunLightCategoryBitmask
    satelliteNode.name = satellite.rawValue
    
    if satellite.orbitInclination != 0 {
      satelliteOrbitNode.tiltAxis(angle: satellite.orbitInclination)
    }
    
    satelliteOrbitNode.addChildNode(satelliteNode)
    celestialNode.addChildNode(satelliteOrbitNode)
    
    satelliteOrbitNode.rotateAnimation(duration: satellite.orbitFullCircle)
    satelliteNode.rotateAnimation(duration: 10.0)
    
    let satLabel = satelliteNode.addLabel(for: satellite)
    satLabel.isHidden = satellite.type == .satellite
    labelsSatellite.append(satLabel)
  }
  
  static func addRings(celestial: Celestial) -> SCNNode {
    let radius = celestial.radius
    let ringsSize = radius * (celestial == .saturn ? 5 : 3.5)
    let ringsLoop = SCNBox(width: ringsSize, height: 0, length: ringsSize, chamferRadius: 0)
    ringsLoop.firstMaterial?.diffuse.contents = UIImage(named: celestial.rawValue + "Ring")
    ringsLoop.firstMaterial?.lightingModel = .constant
    
    let loopNode = SCNNode(geometry: ringsLoop)
    loopNode.position = SCNVector3(x:0,y:0,z:0)
    loopNode.categoryBitMask = sunLightCategoryBitmask
    loopNode.name = celestial.rawValue + "-rings"
    return loopNode
  }
  
  
  static func setCelestialPosition(relativeTo referenceNode: SCNNode, angle: Int = 0, orbit: CGFloat = 0) -> SCNNode {         // angle in degrees
    let celestialNode = SCNNode()
    
    let solCenterTransform = matrix_float4x4(referenceNode.transform)
    
    let angleRadians = -Float(angle) * Float.pi / 180
    
    var translationMatrix = matrix_identity_float4x4
    translationMatrix.columns.3.x = Float(orbit) * cos(angleRadians)
    translationMatrix.columns.3.y = 0
    translationMatrix.columns.3.z = Float(orbit) * sin(angleRadians)
    
    let updatedTransform = matrix_multiply(solCenterTransform, translationMatrix)
    celestialNode.transform = SCNMatrix4(updatedTransform)
    
    return celestialNode
  }
  
  
  static func setSolCenter(relativeToCamera cameraNode: SCNNode) {
    modelCenter = SCNNode()
    
    let cameraNodeTransform = matrix_float4x4(cameraNode.transform)
    
    var translationMatrix = matrix_identity_float4x4
    translationMatrix.columns.3.x = 0
    translationMatrix.columns.3.y = 0
    translationMatrix.columns.3.z = -(solarSystemRadius + 0.2)
    
    let updatedTransform = matrix_multiply(cameraNodeTransform, translationMatrix)
    modelCenter.transform = SCNMatrix4(updatedTransform)
    modelCenter.orientation = .init(0, 0, 0, 1)
  }
  
  
  static func sunOmniLightNode() -> SCNNode {
    let light                    = SCNLight()
    light.type                   = .omni
    light.intensity              = 1000
    light.color                  = UIColor.white
    light.categoryBitMask        = sunLightCategoryBitmask
    
    let omniLightNode = SCNNode()
    omniLightNode.position = SCNVector3(0, 0, 0)
    omniLightNode.light = light
    omniLightNode.name = "sunLight"
    
    return omniLightNode
  }
  
  static func addBackground() -> SCNNode {
    let backSphere = SCNSphere(radius: CGFloat(solarSystemRadius * 5))
    backSphere.segmentCount = 200
    backSphere.materials.first?.diffuse.contents = UIImage(named: "stars")
    backSphere.materials.first?.lightingModel = .constant
    backSphere.materials.first?.isDoubleSided = true
    
    let backNode = SCNNode()
    backNode.geometry = backSphere
    return backNode
  }
  
}
