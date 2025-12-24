import HotwireNative
import StoreKit

public final class PaywallComponent: BridgeComponent {
    override public nonisolated class var name: String {
        Store.startTransactionListener()
        return "paywall"
    }

    override public func onReceive(message: HotwireNative.Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .prices: Task { await handlePrices(message) }
        case .purchase: Task { await handlePurchase(message) }
        }
    }

    private func handlePrices(_ message: HotwireNative.Message) async {
        guard let data: PricesRequest = message.data() else { return }
        let ids = data.products.map { $0.storeProductId }

        do {
            let prices = try await Store.prices(for: ids)
            let response = PricesResponse(prices: prices, environment: .current)
            try await reply(to: message.event, with: response)
        } catch {
            print("Failed to load prices for \(ids):", error.localizedDescription)
            _ = try? await reply(to: message.event, with: PricesResponse(error: error.localizedDescription))
        }
    }

    private func handlePurchase(_ message: HotwireNative.Message) async {
        guard let data: PurchaseRequest = message.data() else { return }

        do {
            let status = try await Store.purchase(id: data.storeProductId, token: data.correlationId)
            try await reply(to: message.event, with: PurchaseResponse(status))
        } catch {
            print("Failed to purchase \(data.storeProductId):", error.localizedDescription)
            _ = try? await reply(to: message.event, with: PurchaseResponse(error: error.localizedDescription))
        }
    }
}

private extension PaywallComponent {
    enum Event: String {
        case prices
        case purchase
    }

    struct PricesRequest: Decodable {
        let products: [Product]

        struct Product: Decodable {
            let storeProductId: String

            enum CodingKeys: String, CodingKey {
                case storeProductId = "appleStoreProductId"
            }
        }
    }

    struct PricesResponse: Encodable {
        let prices: [String: String]?
        let environment: PurchaseKit.Environment?
        let error: String?

        init(prices: [String: String]? = nil, environment: PurchaseKit.Environment? = nil, error: String? = nil) {
            self.prices = prices
            self.environment = environment
            self.error = error
        }
    }

    struct PurchaseRequest: Decodable {
        let storeProductId: String
        let correlationId: UUID

        enum CodingKeys: String, CodingKey {
            case storeProductId = "appleStoreProductId"
            case correlationId
        }
    }

    struct PurchaseResponse: Encodable {
        let status: PurchaseStatus
        let error: String?

        init(_ status: PurchaseStatus) {
            self.status = status
            self.error = nil
        }

        init(error: String) {
            self.status = .error
            self.error = error
        }
    }
}
