import CoreFoundation
import SceneKit

enum Celestial: String, Identifiable, CaseIterable {
  var id: Int { hashValue }
  
  case sun, mercury, venus, earth, mars, jupiter, saturn, uranus, neptune
  case moon, io, europa, ganymede, callisto, titan, triton
  
  static let allNames = allCases.map { $0.rawValue }
  static let planets = allCases.filter { $0.type != .satellite }.map { $0.rawValue }
  
  var solR: CGFloat { return CGFloat(Config.solarSystemRadius) }
  
  static let earthRadius: Int = 6_371    //   km
  static let earthMass: (base: Double, power: Int) = (5.97217, 21)   // t
  static let earthGravity: Float = 9.8  //   m/s2
  
  enum CelestialType {
    case star, planet, satellite
  }
  
  var type: CelestialType {
    switch self {
    case .sun: return .star
    case _ where Celestial.sun.satellites!.contains(self) : return .planet
    default: return .satellite
    }
  }
  
  var radius: CGFloat {
    switch self {
    case .sun:      return solR / 10
    case .mercury:  return solR * 0.7  / 150        //  0.4 E
    case .venus:    return solR * 1.15 / 150        //  1.0 E
    case .earth:    return solR * 1.2  / 150
    case .mars:     return solR * 0.8  / 150        //  0.5 E
    case .jupiter:  return solR * 5.5  / 150        // 44.0 E
    case .saturn:   return solR * 3.2  / 150        //  9.3 E
    case .uranus:   return solR * 2.5  / 150        //  4.0 E
    case .neptune:  return solR * 2.4  / 150        //  3.9 E
      
    case .moon:       return solR * 0.5   / 150       //  0.3 E
    case .io:         return solR * 0.6   / 150       //  0.3 E
    case .europa:     return solR * 0.55  / 150       //  0.25 E
    case .ganymede:   return solR * 0.7   / 150       //  0.4 E
    case .callisto:   return solR * 0.7   / 150       //  0.4 E
    case .titan:      return solR * 0.7   / 150       //  0.4 E
    case .triton:     return solR * 0.5   / 150       //  0.2 E
    }
  }
  
  var orbit: CGFloat {
    switch self {
    case .sun:      return 0
    case .mercury:  return solR * 0.14
    case .venus:    return solR * 0.18
    case .earth:    return solR * 0.25
    case .mars:     return solR * 0.32
    case .jupiter:  return solR * 0.45
    case .saturn:   return solR * 0.70
    case .uranus:   return solR * 0.88
    case .neptune:  return solR * 1.00
      
    case .moon:       return solR * 0.035
    case .io:         return solR * 0.055
    case .europa:     return solR * 0.065
    case .ganymede:   return solR * 0.08
    case .callisto:   return solR * 0.10
    case .titan:      return solR * 0.075
    case .triton:     return solR * 0.055
    }
  }
  
  var angle: Int {
    switch self {
    case .sun:      return    0
    case .mercury:  return -160
    case .venus:    return  130
    case .earth:    return  -90
    case .mars:     return -100
    case .jupiter:  return -150
    case .saturn:   return  130
    case .uranus:   return -135
    case .neptune:  return  175
      
    case .moon:       return -120
    case .io:         return -120
    case .europa:     return -70
    case .ganymede:   return 40
    case .callisto:   return 110
    case .titan:      return -100
    case .triton:     return 20
    }
  }
  
  var orbitFullCircle: Float {
    switch self {
    case .sun:      return 0
    case .mercury:  return 88 / 2
    case .venus:    return 224 / 3
    case .earth:    return 365 / 3
    case .mars:     return 687 / 5
    case .jupiter:  return 12 * 365 / 24
    case .saturn:   return 29 * 365 / 50
    case .uranus:   return 84 * 365 / 135
    case .neptune:  return 164 * 365 / 240
      
    case .moon:       return 27 * 3
    case .io:         return  2 * 20
    case .europa:     return  4 * 20
    case .ganymede:   return  8 * 15
    case .callisto:   return 17 * 9
    case .titan:      return 16 * 7
    case .triton:     return  6 * 15
    }
  }
  
  var axialTilt: Int {
    switch self {
    case .mercury:  return 2
    case .venus:    return 2
    case .earth:    return -7
    case .mars:     return 25
    case .jupiter:  return -3
    case .saturn:   return -27
    case .uranus:   return 82
    case .neptune:  return 28
    default: return 0
    }
  }
  
  var orbitInclination: Int {
    switch self {
    case .triton: return -(180-129)
    default: return 0
    }
  }
  
  var satellites: [Celestial]? {
    switch self {
    case .sun:      return [.mercury, .venus, .earth, .mars, .jupiter, .saturn, .uranus, .neptune]
    case .earth:    return [.moon]
    case .jupiter:  return [.io, .europa, .ganymede, .callisto]
    case .saturn:   return [.titan]
    case .neptune:  return [.triton]
    default: return nil
    }
  }
  
  var hasRings: Bool {
    switch self {
    case .saturn, .uranus: return true
    default: return false
    }
  }
  
  var labelsScale: CGFloat {
    var koef = CGFloat(Config.solarSystemRadius)
    switch self {
    case .moon: koef *= 0.15
    case .io, .europa, .ganymede, .callisto: koef *= 0.4
    case .titan: koef *= 0.35
    case .triton: koef *= 0.25
    default: koef *= 1
    }
    return koef
  }
  
  var info: CelestialInfo {
    switch self {
    case .sun:      return CelestialInfo(radius: 109.00, mass: 332_950, gravity: 28.00, orbitalRadius: nil,
                                         orbitalPeriod: nil, rotationPeriod: 25, satellites: nil,
                                         url: "https://en.wikipedia.org/wiki/Sun")
    case .mercury:  return CelestialInfo(radius: 0.38, mass: 0.06, gravity: 0.38, orbitalRadius: 57.9,
                                         orbitalPeriod: 116, rotationPeriod: 59, satellites: nil,
                                         url: "https://en.wikipedia.org/wiki/Mercury_(planet)")
    case .venus:    return CelestialInfo(radius: 0.95, mass: 0.82, gravity: 0.90, orbitalRadius: 108.2,
                                         orbitalPeriod: 225, rotationPeriod: -243, satellites: nil,
                                         url: "https://en.wikipedia.org/wiki/Venus")
    case .earth:    return CelestialInfo(radius: 1, mass: 1, gravity: 1, orbitalRadius: 149.6,
                                         orbitalPeriod: 365, rotationPeriod: 0.9973, satellites: self.satellites!.map { $0.rawValue.capitalized },
                                         url: "https://en.wikipedia.org/wiki/Earth")
    case .mars:     return CelestialInfo(radius: 0.53, mass: 0.11, gravity: 0.38, orbitalRadius: 227.9,
                                         orbitalPeriod: 687, rotationPeriod: 1.026, satellites: nil,
                                         url: "https://en.wikipedia.org/wiki/Mars")
    case .jupiter:  return CelestialInfo(radius: 10.97, mass: 318, gravity: 2.53, orbitalRadius: 778.4,
                                         orbitalPeriod: 4_332, rotationPeriod: 0.4135, satellites: self.satellites!.map { $0.rawValue.capitalized },
                                         url: "https://en.wikipedia.org/wiki/Jupiter")
    case .saturn:   return CelestialInfo(radius: 9.14, mass: 95, gravity: 1.06, orbitalRadius: 1_433,
                                         orbitalPeriod: 10_759, rotationPeriod: 0.4396, satellites: self.satellites!.map { $0.rawValue.capitalized },
                                         url: "https://en.wikipedia.org/wiki/Saturn")
    case .uranus:   return CelestialInfo(radius: 4.00, mass: 15, gravity: 0.89, orbitalRadius: 2_871,
                                         orbitalPeriod: 30_688, rotationPeriod: -0.7181, satellites: nil,
                                         url: "https://en.wikipedia.org/wiki/Uranus")
    case .neptune:  return CelestialInfo(radius: 3.86, mass: 17, gravity: 1.14, orbitalRadius: 4_500,
                                         orbitalPeriod: 60_195 , rotationPeriod: 0.6713, satellites: self.satellites!.map { $0.rawValue.capitalized },
                                         url: "https://en.wikipedia.org/wiki/Neptune")
    
    case .moon:  return CelestialInfo(radius: 0.27, mass: 0.01, gravity: 0.16, orbitalRadius: 0.384399,
                                      orbitalPeriod: 27, rotationPeriod: 27, satellites: nil,
                                      url: "https://en.wikipedia.org/wiki/Moon")
    case .io:  return CelestialInfo(radius: 0.29, mass: 0.02, gravity: 0.18, orbitalRadius: 0.421700,
                                      orbitalPeriod: 1.7691, rotationPeriod: 1.7691, satellites: nil,
                                    url: "https://en.wikipedia.org/wiki/Io_(moon)")
    case .europa:  return CelestialInfo(radius: 0.24, mass: 0.008, gravity: 0.13, orbitalRadius: 0.670900,
                                      orbitalPeriod: 4, rotationPeriod: 4, satellites: nil,
                                        url: "https://en.wikipedia.org/wiki/Europa_(moon)")
    case .ganymede:  return CelestialInfo(radius: 0.41, mass: 0.03, gravity: 0.15, orbitalRadius: 1.1,
                                      orbitalPeriod: 7, rotationPeriod: 7, satellites: nil,
                                          url: "https://en.wikipedia.org/wiki/Ganymede_(moon)")
    case .callisto:  return CelestialInfo(radius: 0.38, mass: 0.02, gravity: 0.13, orbitalRadius: 1.9,
                                      orbitalPeriod: 17, rotationPeriod: 17, satellites: nil,
                                          url: "https://en.wikipedia.org/wiki/Callisto_(moon)")
    case .titan:  return CelestialInfo(radius: 0.40, mass: 0.02, gravity: 0.14, orbitalRadius: 1.2,
                                      orbitalPeriod: 16, rotationPeriod: 16, satellites: nil,
                                       url: "https://en.wikipedia.org/wiki/Titan_(moon)")
    case .triton:  return CelestialInfo(radius: 0.21, mass: 0.003, gravity: 0.08, orbitalRadius: 0.354759,
                                      orbitalPeriod: 6, rotationPeriod: 6, satellites: nil,
                                        url: "https://en.wikipedia.org/wiki/Triton_(moon)")
    }
  }
}
