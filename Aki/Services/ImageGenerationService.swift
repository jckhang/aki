import Foundation
import UIKit

class ImageGenerationService {
    static let shared = ImageGenerationService()
    private let stepAPIKey = Configuration.stepAPIKey
    private let baseURL = "https://api.stepfun.com/v1/images/image2image"

    // Add size limits as constants
    private let maxWidth: CGFloat = 2048
    private let maxHeight: CGFloat = 2048
    private let maxFileSize: Int = 10_485_760 // 10MB in bytes

    private init() {}

    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let originalSize = image.size
        print("📏 Original image size: \(originalSize.width) x \(originalSize.height)")

        // Check if resize is needed
        if originalSize.width <= maxWidth && originalSize.height <= maxHeight {
            print("✅ Image is within size limits")
            return image
        }

        // Calculate scale factor to fit within limits
        let widthRatio = maxWidth / originalSize.width
        let heightRatio = maxHeight / originalSize.height
        let scale = min(widthRatio, heightRatio)

        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        print("📏 Resizing image to: \(newSize.width) x \(newSize.height)")

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    func enhancePrompt(_ prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let openAIURL = URL(string: "https://api.openai.com/v1/chat/completions")!

        var request = URLRequest(url: openAIURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(stepAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrompt = """
        You are an expert at writing image generation prompts.
        Enhance the given prompt to be more detailed and effective for image generation.
        Focus on adding:
        - Visual details
        - Style descriptions
        - Lighting and atmosphere
        - Composition elements
        Return only the enhanced prompt without any explanations.
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let enhancedPrompt = message["content"] as? String {
                    completion(.success(enhancedPrompt.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    completion(.failure(NetworkError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func generateImage(sourceImage: UIImage, prompt: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        print("🌐 Starting API request to: \(baseURL)")
        print("📝 Prompt: \(prompt)")

        // Resize image first
        let resizedImage = resizeImageIfNeeded(sourceImage)
        print("🖼 Resized image size: \(resizedImage.size)")

        // Validate URL
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(stepAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Convert resized image to base64
        guard let imageBase64 = resizedImage.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            print("❌ Failed to convert image to base64")
            completion(.failure(NetworkError.imageConversionError))
            return
        }
        let sourceURL = "data:image/jpeg;base64,\(imageBase64)"
        print("📦 Base64 image size: \(imageBase64.count) characters")

        // Match the exact format from test.py
        let requestBody: [String: Any] = [
            "model": "step-1x-medium",
            "prompt": prompt,
            "source_url": sourceURL,
            "seed": 42,
            "source_weight": 0.7,
            "response_format": "b64_json"
        ]

        print("🔑 Using API Key: \(stepAPIKey.prefix(4))...")
        print("📤 Request body: \(requestBody)")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to serialize request body: \(error)")
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error)")
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response status: \(httpResponse.statusCode)")
                print("📡 Response headers: \(httpResponse.allHeaderFields)")
            }

            guard let data = data else {
                print("❌ No data received")
                completion(.failure(NetworkError.noData))
                return
            }

            print("📦 Received data size: \(data.count)")

            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response: \(responseString)")
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📋 Parsed JSON: \(json)")

                    if let imageData = json["data"] as? [[String: Any]],
                       let firstImage = imageData.first,
                       let b64Json = firstImage["b64_json"] as? String,
                       let imageData = Data(base64Encoded: b64Json),
                       let image = UIImage(data: imageData) {
                        completion(.success(image))
                    } else {
                        print("❌ Failed to parse image data from response")
                        completion(.failure(NetworkError.invalidResponse))
                    }
                } else {
                    print("❌ Failed to parse JSON response")
                    completion(.failure(NetworkError.invalidResponse))
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case invalidResponse
    case imageConversionError
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from server"
        case .invalidResponse:
            return "Invalid response from server"
        case .imageConversionError:
            return "Failed to process image"
        }
    }
}
