import Foundation

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
