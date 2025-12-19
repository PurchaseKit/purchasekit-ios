# PurchaseKit iOS

Swift package for StoreKit 2 integration with Hotwire Native.

## Structure

- `Sources/Components/PaywallComponent.swift` - Bridge component for prices and purchases
- `Sources/Environment.swift` - Detects sandbox vs production environment

## PaywallComponent

Hotwire Native bridge component that handles:

| Message | Request | Response |
|---------|---------|----------|
| `prices` | Product IDs | Localized prices + environment |
| `purchase` | Product ID + correlation UUID | Status (success/pending/cancelled/error) |

### Prices flow

1. Web sends `prices` message with product IDs
2. Component fetches from StoreKit via `Product.products(for:)`
3. Returns localized `displayPrice` for each product
4. Includes `environment` (sandbox/production) for the web to pass to SaaS

### Purchase flow

1. Web sends `purchase` message with `storeProductId` and `correlationId` (UUID)
2. Component calls `product.purchase(options: [.appAccountToken(uuid)])`
3. UUID links the purchase to the SaaS Purchase::Intent
4. Returns status to web (success keeps spinner, cancelled re-enables form)

## Environment detection

`Environment.current` returns `.sandbox` or `.production`:

| Build type | Environment |
|------------|-------------|
| Simulator | sandbox |
| Development (has embedded.mobileprovision) | sandbox |
| TestFlight (sandboxReceipt) | sandbox |
| App Store | production |

Detection logic:
- Simulator: Always sandbox (can't be App Store)
- Has `embedded.mobileprovision`: Development/Ad-hoc build → sandbox
- Receipt path is `sandboxReceipt`: TestFlight → sandbox
- Otherwise: App Store → production

## StoreKit notes

- Uses StoreKit 2 async/await APIs
- Requires iOS 15.0+
- `appAccountToken` must be a valid UUID
- Transaction verification uses `VerificationResult`
