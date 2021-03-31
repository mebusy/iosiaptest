# Offering, Completing, and Restoring In-App Purchases 
Fetch, complete, and restore transactions in your app.

## Overview
In-App Purchase allows users to purchase virtual goods within your app or directly from the App Store using the StoreKit framework.
This sample code demonstrates how to retrieve, display, and restore in-app purchases. First, you set up your app to register and use a single-transaction queue observer at launch. The transaction queue observer manages all payment transactions and handles all transactions states. Confirm that it’s a shared instance of a custom class that conforms to the [`SKPaymentTransactionObserver`][sect1_link1] protocol. Then, remove the transaction observer when the system is about to terminate the app. See [Setting Up the Transaction Observer and Payment Queue][sect1_link2] for more information.

This sample, which builds the `InAppPurchases` app, supports the iOS, macOS, and tvOS platforms. 
After launching, `InAppPurchases` queries the App Store about product identifiers saved in the `Products.plist` file. `InAppPurchases` updates its UI with the App Store's response, which may include available products for sale, unrecognized product identifiers, or both. The app also displays all available purchased and restored payment transactions in its UI.

[sect1_link1]:https://developer.apple.com/documentation/storekit/skpaymenttransactionobserver
[sect1_link2]:https://developer.apple.com/documentation/storekit/in-app_purchase/setting_up_the_transaction_observer_for_the_payment_queue

## Configure the Sample Code Project
Before you can run and test this sample, you need to:
1. Start with a completed app that supports in-app purchases and has some in-app purchases configured in App Store Connect. See 
steps 1 and 2 of [Workflow for configuring in-app purchases](https://help.apple.com/app-store-connect/#/devb57be10e7) for more information.

2. Create a sandbox test user account in the App Store Connect. See [Create a sandbox tester account](https://help.apple.com/app-store-connect/#/dev8b997bee1) for details.

3. Open this sample in Xcode, select the target that you wish to build, then change its _bundle ID_ to one that supports in-app purchase. Next, select
the right team to let Xcode automatically manage your provisioning profile. See [Assign a project to a team](https://help.apple.com/xcode/mac/current/#/dev23aab79b4) for details.

4. Open the _ProductIds.plist_ file in the sample and update its content with your existing in-app purchases’ product IDs.

5. For iOS and tvOS devices, build and run the InAppPurchases and `InAppPurchasestvOS` targets, respectively, which the sample uses to build `InAppPurchases`. Read [If a code signing error occurs](https://help.apple.com/xcode/mac/current/#/dev01865b392) if you're running into any code-signing issues.

6. For macOS, before building the `InAppPurchasesmacOS` target, sign out of the Mac App Store. Build the target, then launch the resulting app from the Finder the first time to obtain a receipt. See [`Testing In-App Purchase Transactions > Sign In to the App Store with Your Test Account`][sect2_link6] for details.

7. The `InAppPurchases` app queries the App Store about the product identifiers contained in _ProductIds.plist_ upon launching. When successful, it displays a list of products available for sale in the App Store. Tap any product in that list to purchase it. When prompted to authenticate the purchase, use your test user account created in step 2. When the product requests fails, see [invalidProductIdentifiers][sect2_link5]' discussion for various reasons why the App Store may return invalid product identifiers.

[sect2_link5]:https://developer.apple.com/documentation/storekit/skproductsresponse/1505985-invalidproductidentifiers
[sect2_link6]:https://developer.apple.com/documentation/storekit/in-app_purchase/testing_at_all_stages_of_development_with_xcode_and_sandbox


## Display Available Products for Sale with Localized Pricing
The sample configures the app so it confirms that the user is authorized to make payments on the device, before presenting products for sale.
``` swift
var isAuthorizedForPayments: Bool {
    return SKPaymentQueue.canMakePayments()
}
```

Once the app confirms authorization, it sends a products request to the App Store to fetch localized product information from the App Store. Querying the App Store ensures that the app only presents users with products available for purchase. The app initializes the products request with a list of product identifiers associated with products that it wishes to sell in its UI. See [Product ID](https://help.apple.com/app-store-connect/#/dev84b80958f) for more information. Be sure to keep a strong reference to the products request object; the system may release it before the request completes.
``` swift
fileprivate func fetchProducts(matchingIdentifiers identifiers: [String]) {
    // Create a set for the product identifiers.
    let productIdentifiers = Set(identifiers)
    
    // Initialize the product request with the above identifiers.
    productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
    productRequest.delegate = self
    
    // Send the request to the App Store.
    productRequest.start()
}
```
[View in Source](x-source-tag://FetchProductInformation)

The App Store responds to the products request with an [`SKProductsResponse`][sect3_link2] object. Its [`products`][sect3_link3] property contains information about all the products that are actually available for purchase in the App Store. The app uses this property to update its UI. The response's [`invalidProductIdentifiers`][sect3_link4] property includes all product identifiers that weren't recognized by the App Store. See the [`invalidProductIdentifiers`][sect3_link4]’ discussion for various reasons why the App Store may return invalid product identifiers.
``` swift
// products contains products whose identifiers have been recognized by the App Store. As such, they can be purchased.
if !response.products.isEmpty {
    availableProducts = response.products
}

// invalidProductIdentifiers contains all product identifiers not recognized by the App Store.
if !response.invalidProductIdentifiers.isEmpty {
    invalidProductIdentifiers = response.invalidProductIdentifiers
}
```
[View in Source](x-source-tag://ProductRequest) 

To display the price of a product in the UI, use the locale and currency returned by the App Store. For instance, consider a user who is logged into the French App Store and their device uses the United States locale. When attempting to purchase a product, the App Store displays the product's price in euros. Thus, converting and showing the product's price in U.S. dollars to match the device's locale in the UI would be incorrect.
``` swift
extension SKProduct {
    /// - returns: The cost of the product formatted in the local currency.
    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
}
```

[sect3_link2]:https://developer.apple.com/documentation/storekit/skproductsresponse
[sect3_link3]:https://developer.apple.com/documentation/storekit/skproductsresponse/1506047-products
[sect3_link4]:https://developer.apple.com/documentation/storekit/skproductsresponse/1505985-invalidproductidentifiers

## Interact with the App to Purchase Products
Tap any product available for sale in the UI to purchase it. The app allows users to restore non-consumable products and auto-renewable subscriptions. Use the `Restore` button and `Settings > Restore all restorable purchases` to implement this feature in the iOS and tvOS version of the app, respectively. Select the `Store > Restore` menu item to restore purchases in the macOS version of the app. Tapping any purchased item brings up purchase information such as product identifier, transaction identifier, and transaction date. When the purchased item is a hosted product, the purchase information additionally includes its content identifier, content version, and content length. When the purchase is a restored one, the purchase information also contains its original transaction's identifier and date. 

## Handle Payment Transaction States
When a transaction is pending in the payment queue, StoreKit notifies the app’s transaction observer by calling its [`paymentQueue(_:updatedTransactions:)`][sect5_link1] method. Every transaction has five possible states, including [`.purchasing`][sect5_link2], [`.purchased`][sect5_link3], [`.failed`][sect5_link4], [`.restored`][sect5_link5], and [`.deferred`][sect5_link6]; see [`SKPaymentTransactionState`][sect5_link7] for more information. Apps should make sure that their observer’s [`paymentQueue(_:updatedTransactions:)`][sect5_link1] can respond to any of these states at any time. They should implement the [`paymentQueue(_:updatedDownloads:)`][sect5_link8] method on their observer when providing products hosted by Apple.
``` swift
func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
        switch transaction.transactionState {
        case .purchasing: break
        // Do not block the UI. Allow the user to continue using the app.
        case .deferred: print(Messages.deferred)
        // The purchase was successful.
        case .purchased: handlePurchased(transaction)
        // The transaction failed.
        case .failed: handleFailed(transaction)
        // There're restored products.
        case .restored: handleRestored(transaction)
        @unknown default: fatalError(Messages.unknownPaymentTransaction)
        }
    }
}
```

When a transaction fails, inspect its [`error`][sect5_link9] property to determine what happened. Only display errors whose code is different from [`.paymentCancelled`][sect5_link10]. 
``` swift
// Do not send any notifications when the user cancels the purchase.
if (transaction.error as? SKError)?.code != .paymentCancelled {
    DispatchQueue.main.async {
        self.delegate?.storeObserverDidReceiveMessage(message)
    }
}
```

When the user defers a transaction, apps should allow them to continue using the UI while waiting for StoreKit to update the transaction.

[sect5_link1]:https://developer.apple.com/documentation/storekit/skpaymenttransactionobserver/1506107-paymentqueue
[sect5_link2]:https://developer.apple.com/documentation/storekit/skpaymenttransactionstate/purchasing
[sect5_link3]:https://developer.apple.com/documentation/storekit/skpaymenttransactionstate/purchased
[sect5_link4]:https://developer.apple.com/documentation/storekit/skpaymenttransactionstate/failed
[sect5_link5]:https://developer.apple.com/documentation/storekit/skpaymenttransactionstate/restored
[sect5_link6]:https://developer.apple.com/documentation/storekit/skpaymenttransactionstate/deferred
[sect5_link7]:https://developer.apple.com/documentation/storekit/skpaymenttransactionstate
[sect5_link8]:https://developer.apple.com/documentation/storekit/skpaymenttransactionobserver/1506073-paymentqueue
[sect5_link9]:https://developer.apple.com/documentation/storekit/skpaymenttransaction/1411269-error
[sect5_link10]:https://developer.apple.com/documentation/storekit/skerror/2330537-paymentcancelled


## Restore Completed Purchases
When users purchase non-consumables, auto-renewable subscriptions, or non-renewing subscriptions, they expect them to be available on all their devices and indefinitely. See [`In-App Purchase > Understand Product Types`][sect6_link2] for more information. The app provides a UI that allows users to restore their past purchases.

``` swift
@IBAction func restore(_ sender: UIBarButtonItem) {
    // Calls StoreObserver to restore all restorable purchases.
    StoreObserver.shared.restore()
}
```

Use [`SKPaymentQueue`][sect6_link1]’s [`restoreCompletedTransactions`][sect6_link3] to restore non-consumables and auto-renewable subscriptions. StoreKit notifies the app’s transaction observer by calling [`paymentQueue(_:updatedTransactions:)`][sect5_link1] with a transaction state of [`.restored`][sect5_link5] for each restored transaction. If restoring fails, see [`restoreCompletedTransactions`][sect6_link3]’ discussion for details on how to resolve it. Restoring non-renewing subscriptions isn’t within the scope of this sample.

[sect6_link1]:https://developer.apple.com/documentation/storekit/skpaymentqueue
[sect6_link2]:https://developer.apple.com/documentation/storekit/in-app_purchase
[sect6_link3]:https://developer.apple.com/documentation/storekit/skpaymentqueue/1506123-restorecompletedtransactions

## Provide Content and Finish the Transaction
Apps must deliver the content or unlock the purchased functionality after receiving a transaction whose state is [`.purchased`][sect5_link3] or [`.restored`][sect5_link5]. These states indicate that the App Store has received a payment for a product from the user. When the purchased product includes hosted content from the App Store, call [`SKPaymentQueue`][sect6_link1]’s [`start(_:)`][sect7_link1] to download the content.

Unfinished transactions stay in the payment queue. StoreKit calls the app’s persistent observer’s [`paymentQueue(_:updatedTransactions:)`][sect5_link1] every time upon launching or resuming from the background until the app finishes these transactions. As a result, the App Store may repeatedly prompt users to authenticate their purchases or prevent them from purchasing products from the app.

Call [`finishTransaction(_:)`][sect7_link2] on transactions whose state is [`.failed`][sect5_link4], [`.purchased`][sect5_link3], or [`.restored`][sect5_link5] to remove them from the queue. Finished transactions aren’t recoverable. Therefore, apps must provide the purchased content, download all Apple-hosted content of a product, or complete their purchase process before finishing transactions.
``` swift
// Finish the successful transaction.
SKPaymentQueue.default().finishTransaction(transaction)
```

[sect7_link1]:https://developer.apple.com/documentation/storekit/skpaymentqueue/1505998-start
[sect7_link2]:https://developer.apple.com/documentation/storekit/skpaymentqueue/1506003-finishtransaction
