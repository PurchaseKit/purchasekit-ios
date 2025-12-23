import Foundation
import HotwireNative
import StoreKit

public enum PaywallError: Error {
    case unknownProducts([String])
}

extension PaywallError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknownProducts(let ids): "Could not find product with ID(s): \(ids)"
        }
    }
}

public final class PaywallComponent: BridgeComponent {
    override nonisolated public class var name: String { "paywall" }

    override public func onReceive(message: HotwireNative.Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .prices: Task { await prices(via: message) }
        case .purchase: Task { await purchase(via: message) }
        }
    }

    private func prices(via message: HotwireNative.Message) async {
        guard let data: Prices.Request = message.data() else { return }

        do {
            let response = try await prices(for: data.products.map { $0.storeProductId })
            try await reply(to: message.event, with: response)
        } catch {
            print("Failed to load prices for \(data.products.map { $0.storeProductId }):", error.localizedDescription)
            _ = try? await reply(to: message.event, with: Prices.Response(error: error.localizedDescription))
        }
    }

    private func prices(for ids: [String]) async throws -> Prices.Response {
        let products = try await Product.products(for: ids)

        var prices: [String: String] = [:]
        for product in products {
            prices[product.id] = product.displayPrice
        }

        let foundIds = Set(products.map(\.id))
        let requestedIds = Set(ids)
        let missingIds = Array(requestedIds.subtracting(foundIds)).sorted()

        if !missingIds.isEmpty {
            throw PaywallError.unknownProducts(missingIds)
        }

        return .init(prices: prices, environment: .current)
    }

    private func purchase(via message: HotwireNative.Message) async {
        guard let data: Purchase.Request = message.data() else { return }

        do {
            let response = try await purchase(id: data.storeProductId, token: data.correlationId)
            try await reply(to: message.event, with: response)
        } catch {
            print("Failed to purchase \(data.storeProductId):", error.localizedDescription)
            _ = try? await reply(to: message.event, with: Purchase.Response(error: error.localizedDescription))
        }
    }

    private func purchase(id: String, token: UUID) async throws -> Purchase.Response {
        let products = try await Product.products(for: [id])
        guard let product = products.first else {
            throw PaywallError.unknownProducts([id])
        }

        switch try await product.purchase(options: [.appAccountToken(token)]) {
        case .success(let verification):
            let transaction = try verified(verification)
            await transaction.finish()
            return .init(.success)

        case .userCancelled:
            return .init(.cancelled)

        case .pending:
            return .init(.pending)

        @unknown default:
            throw StoreKitError.unknown
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signed):
            return signed
        case .unverified(_, let error):
            throw error
        }
    }
}

private extension PaywallComponent {
    enum Event: String {
        case prices
        case purchase
    }

    enum Prices {
        struct Request: Decodable {
            let products: [Product]
        }

        struct Product: Decodable {
            let storeProductId: String

            enum CodingKeys: String, CodingKey {
                case storeProductId = "appleStoreProductId"
            }
        }

        struct Response: Encodable {
            let prices: [String: String]?
            let environment: PurchaseKit.Environment?
            let error: String?

            init(prices: [String: String]? = nil, environment: PurchaseKit.Environment? = nil, error: String? = nil) {
                self.prices = prices
                self.environment = environment
                self.error = error
            }
        }
    }

    enum Purchase {
        struct Request: Decodable {
            let storeProductId: String
            let correlationId: UUID

            enum CodingKeys: String, CodingKey {
                case storeProductId = "appleStoreProductId"
                case correlationId
            }
        }

        struct Response: Encodable {
            let status: Status
            let error: String?

            init(_ status: Status) {
                self.status = status
                self.error = nil
            }

            init(error: String) {
                self.status = .error
                self.error = error
            }
        }

        enum Status: String, Encodable {
            case success
            case pending
            case cancelled
            case error
        }
    }
}
