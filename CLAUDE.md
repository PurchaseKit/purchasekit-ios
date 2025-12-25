# PurchaseKit iOS

Swift package for StoreKit 2 integration with Hotwire Native.

## Structure

- `Sources/Components/PaywallComponent.swift` - Bridge component (thin routing layer)
- `Sources/Store.swift` - StoreKit operations (prices, purchases, transaction listener)
- `Sources/Environment.swift` - Detects sandbox vs production environment
- `Sources/APIClient.swift` - HTTP client for SaaS communication
- `Sources/Version.swift` - Package version constant

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
- Requires iOS 16.0+ (for `Transaction.environment`)
- `appAccountToken` must be a valid UUID
- Transaction verification uses `VerificationResult`
- Transaction listener auto-starts when component is registered (via `name` property access)
- Listener finishes all verified transactions immediately - fulfillment happens via webhooks

## Sandbox testing

**Requirements for real Apple webhooks:**
- Real iOS device (not simulator - StoreKit Config files don't send webhooks)
- Sandbox Apple ID
- SaaS accessible from internet (use ngrok for local development)
- App Store Connect configured with webhook URL

**Sandbox subscription durations:**

| Production duration | Sandbox duration |
|---------------------|------------------|
| 1 week | 3 minutes |
| 1 month | 5 minutes |
| 2 months | 10 minutes |
| 3 months | 15 minutes |
| 6 months | 30 minutes |
| 1 year | 1 hour |

**Resetting sandbox purchases:**
- Easiest: Create a new sandbox tester in App Store Connect
- On device: Settings → App Store → sign out, sign in with different sandbox account
- Cancel subscription: App Store Connect → Users and Access → Sandbox → Manage (expires based on duration above)

**Xcode StoreKit testing (local only, no webhooks):**
- Debug → StoreKit → Manage Transactions (delete transactions)
- Debug → StoreKit → Clear Purchase History

## Xcode StoreKit testing

For local development without Apple webhooks, the package auto-completes purchases made with Xcode StoreKit Configuration files.

### How it works

1. When `transaction.environment == .xcode`, the package POSTs to the SaaS completion endpoint
2. SaaS marks the intent as completed and sends webhook to host app
3. Same redirect flow as production, but without waiting for Apple

### Setup

1. Create a StoreKit Configuration file in Xcode (File → New → File → StoreKit Configuration)
2. Add products matching your PurchaseKit product IDs
3. Edit scheme → Run → Options → StoreKit Configuration → select your file
4. Run the app in simulator

### Limitations

- Only works with StoreKit Configuration files (not sandbox or production)
- Webhook from Apple is never received (SaaS simulates it)
- Environment is recorded as "xcode" in the purchase intent
