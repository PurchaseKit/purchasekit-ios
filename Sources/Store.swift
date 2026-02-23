import StoreKit

enum Store {
    private nonisolated static let transactionListener: Void = {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
            }
        }
    }()

    nonisolated static func startTransactionListener() {
        _ = transactionListener
    }

    static func prices(for ids: [String]) async throws -> [String: String] {
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

        return prices
    }

    static func currentSubscriptionIds() async -> [String] {
        var ids: [String] = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                ids.append(String(transaction.originalID))
            }
        }
        return ids
    }

    static func purchase(id: String, token: UUID) async throws -> (PurchaseStatus, Transaction?) {
        let products = try await Product.products(for: [id])
        guard let product = products.first else {
            throw PaywallError.unknownProducts([id])
        }

        switch try await product.purchase(options: [.appAccountToken(token)]) {
        case .success(let verification):
            let transaction = try verified(verification)
            await transaction.finish()
            return (.success, transaction)

        case .userCancelled:
            return (.cancelled, nil)

        case .pending:
            return (.pending, nil)

        @unknown default:
            throw StoreKitError.unknown
        }
    }

    private static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signed):
            return signed
        case .unverified(_, let error):
            throw error
        }
    }
}

enum PurchaseStatus: String, Encodable {
    case success
    case pending
    case cancelled
    case error
}
