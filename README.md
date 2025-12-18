# PurchaseKit iOS

Swift package providing a Hotwire Native bridge component for StoreKit purchases.

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

## Bridge component

The `paywall` bridge component handles the following messages from the web:

| Message | Description |
|---------|-------------|
| `prices` | Returns localized prices for requested product IDs |
| `purchase` | Initiates StoreKit purchase flow with `storeProductId` and `correlationId` |

### Prices

Request:
```json
{ "storeProductIds": ["monthly", "yearly"] }
```

Response:
```json
{ "prices": { "monthly": "$9.99", "yearly": "$99.99" } }
```

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

- iOS 15.0+
- Xcode 15.0+
- Hotwire Native iOS 1.2.0+
