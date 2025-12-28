# PurchaseKit iOS

Swift package providing a Hotwire Native bridge component for StoreKit purchases via [PurchaseKit](https://purchasekit.dev).

## Installation

Add the package to your Xcode project via Swift Package Manager:

```
https://github.com/purchasekit/purchasekit-ios
```

## Usage

Register the bridge component with Hotwire Native:

```swift
import PurchaseKit

Hotwire.registerBridgeComponents([
    PaywallComponent.self
])
```

The component automatically listens for StoreKit transactions and finishes them immediately. PurchaseKit handles fulfillment via webhooks.

## Web setup

Use the [purchasekit-pay gem](https://github.com/purchasekit/purchasekit-pay) to set up the web-side bridge component. It provides:

- Rails helper to render a paywall
- SDK to interact with the PurchaseKit dashboard
- Automatic message handling with the native component
- `Pay::Subscription` updates from webhook responses

## Bridge component

The `paywall` bridge component handles the following messages from the web:

| Message | Description |
|---------|-------------|
| `prices` | Returns localized prices for requested product IDs |
| `purchase` | Initiates StoreKit purchase flow with `storeProductId` and `correlationId` |

### Prices

Request:
```json
{ "products": [{ "appleStoreProductId": "monthly" }, { "appleStoreProductId": "yearly" }] }
```

Response:
```json
{
  "prices": { "monthly": "$9.99", "yearly": "$99.99" },
  "environment": "sandbox"
}
```

Environment is `sandbox` (development, TestFlight) or `production` (App Store).

### Purchase

Request:
```json
{ "storeProductId": "monthly", "correlationId": "uuid" }
```

Response:
```json
{ "status": "success" }
```

Status values: `success`, `pending`, `cancelled`, `error`

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Hotwire Native iOS 1.2.0+

## Releasing

```bash
bin/release 1.2.0
```

This bumps the version in `Sources/Version.swift`, commits, tags, and pushes. Swift Package Manager picks up the new version automatically from the git tag.
