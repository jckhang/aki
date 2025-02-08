import Foundation

class ImageGenerationService {
    static let shared = ImageGenerationService()
    private let openAIKey = Configuration.openAIKey

    private init() {}

    func enhancePrompt(_ prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let openAIURL = URL(string: "https://api.openai.com/v1/chat/completions")!

        var request = URLRequest(url: openAIURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
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
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case invalidResponse
}
