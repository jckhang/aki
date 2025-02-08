import SwiftUI

struct ImageGenerationView: View {
    @State private var userPrompt: String = ""
    @State private var enhancedPrompt: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isShowingError = false

    var body: some View {
        VStack {
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
        }
        .padding()
        .alert("Error", isPresented: $isShowingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

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
}
