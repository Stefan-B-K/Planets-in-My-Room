
import UIKit.UIView
import AVFoundation.AVCaptureInput
import StoreKit

extension UIViewController {
  
  // MARK: Camera
  func checkCamera(onComplete: @escaping (Bool)->()) {
    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    switch authStatus {
    case .authorized: onComplete(true)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
          onComplete(granted)
      }
    default:
      let alert = UIAlertController(title: "Camera Access",
                                    message: "Augumented Reality needs access to the camera for the app to work.",
                                    preferredStyle: UIAlertController.Style.alert)
      alert.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ -> Void in
        self.view.isHidden = true
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
      })
      alert.addAction(UIAlertAction(title: "Exit App", style: .default) { _ in
        exit(0)
      })
      present(alert, animated: true)
    }
  }
  
  

  
}
