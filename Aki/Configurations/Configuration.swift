import Foundation

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static var stepAPIKey: String {
        let key = ProcessInfo.processInfo.environment["STEP_API_KEY"] ??
                  Bundle.main.object(forInfoDictionaryKey: "STEP_API_KEY") as? String ??
                  value(for: "STEP_API_KEY")

        guard let key = key, !key.isEmpty else {
            print("⚠️ STEP_API_KEY is empty or missing")
            print("- Environment variables: \(ProcessInfo.processInfo.environment.keys.joined(separator: ", "))")
            print("- Info.plist keys: \(Bundle.main.infoDictionary?.keys.joined(separator: ", ") ?? "none")")
            fatalError("STEP_API_KEY not found in any configuration source")
        }

        print("🔑 Using Step API Key: \(key.prefix(4))...")
        return key
    }

    static var openAIKey: String {
        // First try environment variable
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            print("🔑 OpenAI Key loaded from environment: \(key.prefix(4))...")
            return key
        }

        // Then try Info.plist
        if let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String {
            print("🔑 OpenAI Key loaded from Info.plist: \(key.prefix(4))...")
            return key
        }

        // Finally try Debug.xcconfig
        if let key = value(for: "OPENAI_API_KEY") {
            print("🔑 OpenAI Key loaded from xcconfig: \(key.prefix(4))...")
            return key
        }

        print("⚠️ OPENAI_API_KEY not found in:")
        print("- Environment variables: \(ProcessInfo.processInfo.environment.keys.joined(separator: ", "))")
        print("- Info.plist keys: \(Bundle.main.infoDictionary?.keys.joined(separator: ", ") ?? "none")")
        fatalError("OPENAI_API_KEY not found in any configuration source")
    }

    static func value(for key: String) -> String? {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            return nil
        }

        switch object {
        case let value as String:
            return value
        default:
            return nil
        }
    }
}
