
import SceneKit

extension SCNNode {
  
  func addSunBloom() {
    let bloomFilter = CIFilter(name:"CIBloom")!
    bloomFilter.setValue(3, forKey: "inputIntensity")
    bloomFilter.setValue(20, forKey: "inputRadius")
    self.filters = [bloomFilter]
  }
  
  
  func addLabel(for celelestial: Celestial) -> SCNNode {
    let textGeometry = SCNText(string: celelestial.rawValue.capitalized, extrusionDepth: celelestial.labelsScale * 20)
    textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
    
    let front = SCNMaterial()
    front.diffuse.contents = UIColor.cyan
    front.isDoubleSided = true
    front.lightingModel = .constant
    let sides = SCNMaterial()
    sides.diffuse.contents = UIColor.systemIndigo
    sides.isDoubleSided = true
    sides.lightingModel = .constant
    
    textGeometry.insertMaterial(front, at: 0)
    textGeometry.insertMaterial(sides, at: 2)
    textGeometry.font = UIFont(name: "Helvetica", size: celelestial.labelsScale * 100)
    
    
    let textNode = SCNNode(geometry: textGeometry)

    let (minB, maxB) = textNode.boundingBox
    textNode.pivot = SCNMatrix4MakeTranslation((minB.x + maxB.x)/2, (minB.y + maxB.y)/2, 0)       // базова точка в центъра на текста

    textNode.position = SCNVector3 (0, max(celelestial.radius * 2, celelestial.labelsScale * 0.05), 0)
    textNode.scale = SCNVector3(0.0002, 0.0002, 0.0002)
     
    let billboardConstraint = SCNBillboardConstraint()
    billboardConstraint.freeAxes = SCNBillboardAxis.Y
    textNode.constraints = [billboardConstraint]
    textNode.name = celelestial.rawValue + "-label"
    
    self.addChildNode(textNode)
    return textNode
  }
  
  
  // 15 sec for planet/sattelite spin       //  30 sec for sun spin
  func rotateAnimation(duration:  Float, retro: Bool = false) {
    let rotateOne = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2 * (retro ? -1 : 1)), z: 0, duration: TimeInterval(duration))
    self.runAction(SCNAction.repeatForever(rotateOne))
  }
  
  
  func tiltAxis(angle: Int) {
    let angleRadians = Float(angle) * Float.pi / 180
    let orientation = self.orientation
    var quat_rot = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
    let multiplier = GLKQuaternionMakeWithAngleAndAxis(angleRadians, 0, 0, 1)
    quat_rot = GLKQuaternionMultiply(quat_rot, multiplier)
    self.orientation = SCNQuaternion(quat_rot.x, quat_rot.y, quat_rot.z, quat_rot.w)
  }
  
  
  func addSatellitesOrbits(for celelestial: Celestial) {
    guard let satellites = celelestial.satellites else { return }
    for sat in satellites {
      let orbitRing = SCNTorus(ringRadius: sat.orbit, pipeRadius: CGFloat(Config.solarSystemRadius) / (celelestial.type == .star ? 5000 : 7500))
      orbitRing.firstMaterial?.diffuse.contents = UIColor.cyan
      orbitRing.firstMaterial?.lightingModel = .constant
      orbitRing.ringSegmentCount = celelestial.type == .planet ? 200 : 100
      
      let orbitRingNode = SCNNode()
      orbitRingNode.position = SCNVector3(0, 0, 0)
      orbitRingNode.geometry = orbitRing
      orbitRingNode.categoryBitMask = Config.sunLightCategoryBitmask
      orbitRingNode.name = celelestial.rawValue + "-lineOrbit"
      if sat.orbitInclination != 0 {
        orbitRingNode.tiltAxis(angle: sat.orbitInclination)
      }
      self.addChildNode(orbitRingNode)
    }
  }
  
  
  // planet axis
  func buildLineInTwoPointsWithRotation(from startPoint: SCNVector3,
                                        to endPoint: SCNVector3,
                                        radius: CGFloat,
                                        color: UIColor) -> SCNNode {
    let w = SCNVector3(x: endPoint.x-startPoint.x,
                       y: endPoint.y-startPoint.y,
                       z: endPoint.z-startPoint.z)
    let length = CGFloat(sqrt(w.x * w.x + w.y * w.y + w.z * w.z))
    
    // two points together
    if length == 0.0 {
      let sphere = SCNSphere(radius: radius)
      sphere.firstMaterial?.diffuse.contents = color
      self.geometry = sphere
      self.position = startPoint
      return self
    }
    
    let cyl = SCNCylinder(radius: radius, height: length)
    cyl.firstMaterial?.diffuse.contents = color
    cyl.firstMaterial?.lightingModel = .constant
    
    self.geometry = cyl
    
    //original vector of cylinder above 0,0,0
    let ov = SCNVector3(0, length/2.0,0)
    //target vector, in new coordination
    let nv = SCNVector3((endPoint.x - startPoint.x)/2.0, (endPoint.y - startPoint.y)/2.0,
                        (endPoint.z-startPoint.z)/2.0)
    
    // axis between two vector
    let av = SCNVector3( (ov.x + nv.x)/2.0, (ov.y+nv.y)/2.0, (ov.z+nv.z)/2.0)
    
    //normalized axis vector
    let av_normalized = {
      let length = sqrt(av.x * av.x + av.y * av.y + av.z * av.z)
      if length == 0 { return SCNVector3(0.0, 0.0, 0.0) }
      return SCNVector3( av.x / length, av.y / length, av.z / length)
    }()
    let q0 = Float(0.0) //cos(angel/2), angle is always 180 or M_PI
    let q1 = Float(av_normalized.x) // x' * sin(angle/2)
    let q2 = Float(av_normalized.y) // y' * sin(angle/2)
    let q3 = Float(av_normalized.z) // z' * sin(angle/2)
    
    let r_m11 = q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3
    let r_m12 = 2 * q1 * q2 + 2 * q0 * q3
    let r_m13 = 2 * q1 * q3 - 2 * q0 * q2
    let r_m21 = 2 * q1 * q2 - 2 * q0 * q3
    let r_m22 = q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3
    let r_m23 = 2 * q2 * q3 + 2 * q0 * q1
    let r_m31 = 2 * q1 * q3 + 2 * q0 * q2
    let r_m32 = 2 * q2 * q3 - 2 * q0 * q1
    let r_m33 = q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3
    
    self.transform.m11 = r_m11
    self.transform.m12 = r_m12
    self.transform.m13 = r_m13
    self.transform.m14 = 0.0
    
    self.transform.m21 = r_m21
    self.transform.m22 = r_m22
    self.transform.m23 = r_m23
    self.transform.m24 = 0.0
    
    self.transform.m31 = r_m31
    self.transform.m32 = r_m32
    self.transform.m33 = r_m33
    self.transform.m34 = 0.0
    
    self.transform.m41 = (startPoint.x + endPoint.x) / 2.0
    self.transform.m42 = (startPoint.y + endPoint.y) / 2.0
    self.transform.m43 = (startPoint.z + endPoint.z) / 2.0
    self.transform.m44 = 1.0
    return self
  }
}
