# PurchaseKit iOS

Swift package providing a Hotwire Native bridge component for StoreKit purchases via [PurchaseKit](https://purchasekit.com).

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

Use the [purchasekit gem](https://github.com/purchasekit/purchasekit) to add the paywall to your Rails app. The gem handles all communication with the native component automatically.

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Hotwire Native iOS 1.2.0+

## Releasing

```bash
bin/release 1.2.0
```

This bumps the version in `Sources/Version.swift`, commits, tags, and pushes. Swift Package Manager picks up the new version automatically from the git tag.
