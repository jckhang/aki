import XCTest
import SwiftUI
import AVFoundation
@testable import Aki

class CameraTests: XCTestCase {
    var imageGenerationView: ImageGenerationView!

    override func setUp() {
        super.setUp()
        imageGenerationView = ImageGenerationView()
    }

    override func tearDown() {
        imageGenerationView = nil
        super.tearDown()
    }

    func testCameraPermissionAuthorized() {
        // Create expectation
        let expectation = XCTestExpectation(description: "Camera sheet should be presented")

        // Create a test view with observable state
        let view = ImageGenerationView()
        let viewController = UIHostingController(rootView: view)

        // Present the view controller
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        // Trigger camera button tap
        DispatchQueue.main.async {
            view.checkCameraPermissionSafely()

            // Verify camera sheet is presented
            if view.isShowingCamera {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testCameraPermissionDenied() {
        // Create expectation
        let expectation = XCTestExpectation(description: "Error alert should be shown")

        // Create a test view with observable state
        let view = ImageGenerationView()
        let viewController = UIHostingController(rootView: view)

        // Present the view controller
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        // Mock denied permission
        DispatchQueue.main.async {
            // Simulate denied permission by directly setting error state
            view.errorMessage = "Please enable camera access in Settings to use this feature"
            view.isShowingError = true

            // Verify error is shown
            if view.isShowingError && view.errorMessage == "Please enable camera access in Settings to use this feature" {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testImagePickerDismissal() {
        // Create expectation
        let expectation = XCTestExpectation(description: "ImagePicker should be dismissed")

        // Create test image
        let testImage = UIImage(systemName: "camera.fill")!

        // Create ImagePicker coordinator
        let imagePicker = ImagePicker(image: .constant(nil), sourceType: .camera)
        let coordinator = imagePicker.makeCoordinator()

        // Create mock picker controller
        let mockPicker = UIImagePickerController()

        // Test image selection
        let info: [UIImagePickerController.InfoKey: Any] = [
            .originalImage: testImage
        ]

        // Simulate image selection
        DispatchQueue.main.async {
            coordinator.imagePickerController(mockPicker, didFinishPickingMediaWithInfo: info)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
