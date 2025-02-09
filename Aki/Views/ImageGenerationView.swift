import SwiftUI
import AVFoundation

#if DEBUG
var cameraAuthorizationProvider: () -> AVAuthorizationStatus = {
    AVCaptureDevice.authorizationStatus(for: .video)
}

var cameraAuthorizationRequester: (@escaping (Bool) -> Void) -> Void = { completion in
    AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
}
#endif

struct ImageGenerationView: View {
    // Make state variables internal for testing in DEBUG mode
    #if DEBUG
    @State var userPrompt: String = ""
    @State var enhancedPrompt: String = ""
    @State var sourceImage: UIImage?
    @State var generatedImage: UIImage?
    @State var isLoading = false
    @State var errorMessage: String?
    @State var isShowingError = false
    @State var isShowingImagePicker = false
    @State var isShowingCamera = false
    @State var isCheckingPermissions = false
    #else
    @State private var userPrompt: String = ""
    @State private var enhancedPrompt: String = ""
    @State private var sourceImage: UIImage?
    @State private var generatedImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isShowingError = false
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var isCheckingPermissions = false
    #endif

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image source selection
                HStack {
                    Button("Camera") {
                        if !isCheckingPermissions {
                            isCheckingPermissions = true
                            checkCameraPermissionSafely()
                        }
                    }
                    .disabled(isCheckingPermissions)
                    .sheet(isPresented: $isShowingCamera) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            ImagePicker(image: $sourceImage, sourceType: .camera)
                        }
                    }

                    Button("Photo Library") {
                        isShowingImagePicker = true
                    }
                    .sheet(isPresented: $isShowingImagePicker) {
                        ImagePicker(image: $sourceImage, sourceType: .photoLibrary)
                    }
                }

                // Source image display
                if let sourceImage = sourceImage {
                    Image(uiImage: sourceImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }

                // Prompt input
                TextField("Enter your prompt", text: $userPrompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Enhance prompt button
                Button(action: enhancePrompt) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text(isLoading ? "Enhancing..." : "Enhance Prompt")
                    }
                }
                .disabled(userPrompt.isEmpty || isLoading)
                .padding()

                // Enhanced prompt display
                if !enhancedPrompt.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Enhanced prompt:")
                            .font(.headline)
                        Text(enhancedPrompt)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                }

                // Generate button
                Button(action: generateImage) {
                    Text(isLoading ? "Generating..." : "Generate Image")
                }
                .disabled(sourceImage == nil || (enhancedPrompt.isEmpty && userPrompt.isEmpty) || isLoading)
                .padding()

                // Generated image display
                if let generatedImage = generatedImage {
                    Image(uiImage: generatedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
            }
        }
        .padding()
        .alert("Error", isPresented: $isShowingError) {
            Button("OK") {
                errorMessage = nil
                isCheckingPermissions = false
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    #if DEBUG
    func checkCameraPermissionSafely() {
        print("📸 Starting camera permission check")

        // First check if camera is available on the device
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            DispatchQueue.main.async {
                self.errorMessage = "Camera is not available on this device"
                self.isShowingError = true
                self.isCheckingPermissions = false
            }
            return
        }

        // Check if we have the required privacy description
        guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
            print("⚠️ Missing NSCameraUsageDescription in Info.plist")
            DispatchQueue.main.async {
                self.errorMessage = "Camera permission not properly configured"
                self.isShowingError = true
                self.isCheckingPermissions = false
            }
            return
        }

        print("📝 Camera usage description found in Info.plist")

        DispatchQueue.main.async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            print("📱 Current camera authorization status: \(status)")

            switch status {
            case .notDetermined:
                print("⚠️ Permission not determined, requesting access...")
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    print("🎯 Permission request result: \(granted)")
                    DispatchQueue.main.async {
                        if granted {
                            self.isShowingCamera = true
                        } else {
                            self.errorMessage = "Camera access denied"
                            self.isShowingError = true
                        }
                        self.isCheckingPermissions = false
                    }
                }

            case .restricted:
                self.errorMessage = "Camera access is restricted"
                self.isShowingError = true
                self.isCheckingPermissions = false

            case .denied:
                self.errorMessage = "Please enable camera access in Settings to use this feature"
                self.isShowingError = true
                self.isCheckingPermissions = false

            case .authorized:
                self.isShowingCamera = true
                self.isCheckingPermissions = false

            @unknown default:
                self.errorMessage = "Unexpected camera authorization status"
                self.isShowingError = true
                self.isCheckingPermissions = false
            }
        }
    }
    #else
    private func checkCameraPermissionSafely() {
        print("📸 Starting camera permission check")

        // First check if camera is available on the device
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            DispatchQueue.main.async {
                self.errorMessage = "Camera is not available on this device"
                self.isShowingError = true
                self.isCheckingPermissions = false
            }
            return
        }

        // Check if we have the required privacy description
        guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
            print("⚠️ Missing NSCameraUsageDescription in Info.plist")
            DispatchQueue.main.async {
                self.errorMessage = "Camera permission not properly configured"
                self.isShowingError = true
                self.isCheckingPermissions = false
            }
            return
        }

        print("📝 Camera usage description found in Info.plist")

        DispatchQueue.main.async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            print("📱 Current camera authorization status: \(status)")

            switch status {
            case .notDetermined:
                print("⚠️ Permission not determined, requesting access...")
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    print("🎯 Permission request result: \(granted)")
                    DispatchQueue.main.async {
                        if granted {
                            self.isShowingCamera = true
                        } else {
                            self.errorMessage = "Camera access denied"
                            self.isShowingError = true
                        }
                        self.isCheckingPermissions = false
                    }
                }

            case .restricted:
                self.errorMessage = "Camera access is restricted"
                self.isShowingError = true
                self.isCheckingPermissions = false

            case .denied:
                self.errorMessage = "Please enable camera access in Settings to use this feature"
                self.isShowingError = true
                self.isCheckingPermissions = false

            case .authorized:
                self.isShowingCamera = true
                self.isCheckingPermissions = false

            @unknown default:
                self.errorMessage = "Unexpected camera authorization status"
                self.isShowingError = true
                self.isCheckingPermissions = false
            }
        }
    }
    #endif

    private func enhancePrompt() {
        isLoading = true
        ImageGenerationService.shared.enhancePrompt(userPrompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let enhanced):
                    self.enhancedPrompt = enhanced
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isShowingError = true
                }
            }
        }
    }

    private func generateImage() {
        guard let sourceImage = sourceImage else { return }

        isLoading = true
        let promptToUse = enhancedPrompt.isEmpty ? userPrompt : enhancedPrompt

        ImageGenerationService.shared.generateImage(sourceImage: sourceImage, prompt: promptToUse) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let image):
                    self.generatedImage = image
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isShowingError = true
                }
            }
        }
    }

    #if DEBUG
    var debugMenu: some View {
        Menu("Debug") {
            Button("Test Camera") {
                checkCameraPermissionSafely()
            }
            Button("Print Auth Status") {
                print(AVCaptureDevice.authorizationStatus(for: .video))
            }
            Button("Reset State") {
                sourceImage = nil
                enhancedPrompt = ""
                generatedImage = nil
            }
        }
    }
    #endif
}
