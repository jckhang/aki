import AVFoundation

class MockCameraAuthorization {
    static var authorizationStatus: AVAuthorizationStatus = .notDetermined

    static func requestAccess(completion: @escaping (Bool) -> Void) {
        switch authorizationStatus {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            authorizationStatus = .authorized
            completion(true)
        @unknown default:
            completion(false)
        }
    }
}
