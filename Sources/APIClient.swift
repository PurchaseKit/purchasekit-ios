import Foundation

enum APIClient {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "PurchaseKit-iOS/\(PurchaseKitVersion.current)"
        ]
        return URLSession(configuration: config)
    }()

    static func post(url: String) async {
        guard let url = URL(string: url) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        _ = try? await session.data(for: request)
    }
}
