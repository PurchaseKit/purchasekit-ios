import Foundation

public enum Environment: String, Encodable {
    case sandbox
    case production
}

public extension Environment {
    static var current: Environment {
        isAppStore ? .production : .sandbox
    }

    private static var isAppStore: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if isAppStoreReceiptSandbox || hasEmbeddedMobileProvision {
            return false
        }
        return true
        #endif
    }

    private static var isAppStoreReceiptSandbox: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    private static var hasEmbeddedMobileProvision: Bool {
        Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil
    }
}
