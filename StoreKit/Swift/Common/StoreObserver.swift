/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom observer class to handle changes to the payment queue:
Implements the SKPaymentTransactionObserver protocol. Handles purchasing and restoring products using paymentQueue:updatedTransactions:.
 
How to use:
 
 func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
     // Attach an observer to the payment queue.
     SKPaymentQueue.default().add(StoreObserver.shared)
     return true
 }
 
 func applicationWillTerminate(_ application: UIApplication) {
     // Remove the observer.
     SKPaymentQueue.default().remove(StoreObserver.shared)
 }
*/

import StoreKit
import Foundation

class StoreObserver: NSObject {
    // MARK: - Types
    
    static let shared = StoreObserver()
    
    // MARK: - Properties
    
    /**
     Indicates whether the user is allowed to make payments.
     - returns: true if the user is allowed to make payments and false, otherwise. Tell StoreManager to query the App Store when the user is
     allowed to make payments and there are product identifiers to be queried.
     */
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
 
    // MARK: - Initializer
    
    private override init() {}
    
    
    // MARK: - Bookmark
    
    /// Keeps track of all purchases.
    var purchased = [SKPaymentTransaction]()
    
    /// Keeps track of all restored purchases.
    var restored = [SKPaymentTransaction]()
    
    /// Indicates whether there are restorable purchases.
    fileprivate var hasRestorablePurchases = false
    
    weak var delegate: StoreObserverDelegate?
    

    
    // MARK: - Submit Payment Request
    
    /// Create and add a payment request to the payment queue.
    func buy(_ product: SKProduct) {
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // MARK: - Restore All Restorable Purchases
    
    /// Restores all previously completed purchases.
    func restore() {
        if !restored.isEmpty {
            restored.removeAll()
        }
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - Handle Payment Transactions
    
    /// Handles successful purchase transactions.
    fileprivate func handlePurchased(_ transaction: SKPaymentTransaction) {
        purchased.append(transaction)
        
        // state: ase purchased = 1, restored = 3
        print( "Transaction: pid:\(transaction.payment.productIdentifier) status:\(transaction.transactionState.rawValue)" )
        if transaction.transactionState.rawValue == 1 {
            print("\t to deliver content...")
        }
        
        
        let bValid = verifyTransaction( transaction );
        DispatchQueue.main.async {
            if bValid {
                self.delegate?.storeObserverPurchaseSucceed( transaction.payment.productIdentifier )
            } else {
                self.delegate?.storeObserverDidReceiveMessage( Messages.verifyFailed )
                return // prevent from invoking finish Transaction
            }
        }
        
        // Finish the successful transaction.
        // if finish Transaction() failed to invoke.
        //    this transaction will keep in queue
        //    StoreKit will try re-trigger and continue this transiaction every time
        //    upon launching or purchasing same product until the app finishes these transactions.
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    /// Handles failed purchase transactions.
    fileprivate func handleFailed(_ transaction: SKPaymentTransaction) {
        var message = "\(Messages.purchaseOf) \(transaction.payment.productIdentifier) \(Messages.failed)"
        
        if let error = transaction.error {
            message += "\n\(Messages.error) \(error.localizedDescription)"
            print("\(Messages.error) \(error.localizedDescription)")
        }
        
        // Do not send any notifications when the user cancels the purchase.
        if (transaction.error as? SKError)?.code != .paymentCancelled {
            DispatchQueue.main.async {
                self.delegate?.storeObserverDidReceiveMessage(message)
            }
        }
        // Finish the failed transaction.
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    /// Handles restored purchase transactions.
    fileprivate func handleRestored(_ transaction: SKPaymentTransaction) {
        hasRestorablePurchases = true
        restored.append(transaction)
                
        // Finishes the restored transaction, for restore, finish it at once
        SKPaymentQueue.default().finishTransaction(transaction)
        
        // state: ase purchased = 1, restored = 3
        print( "Transaction: pid:\(transaction.payment.productIdentifier) status:\(transaction.transactionState.rawValue)" )
        print("\t to restore content for \(transaction.payment.productIdentifier).")
        
        let bValid = verifyTransaction( transaction );
        DispatchQueue.main.async {
            if bValid {
                self.delegate?.storeObserverRestoreDidSucceed( transaction.payment.productIdentifier )
            } else {
                self.delegate?.storeObserverDidReceiveMessage( Messages.verifyFailed )
            }
        }
 

    }
    
    func getDeviceIdentifier() -> Data {
          let device = UIDevice.current
          var uuid = device.identifierForVendor!.uuid
          let addr = withUnsafePointer(to: &uuid) { (p) -> UnsafeRawPointer in
            UnsafeRawPointer(p)
          }
          let data = Data(bytes: addr, count: 16)
          return data
    }
    
    fileprivate func verifyTransaction(_ transaction: SKPaymentTransaction) -> Bool {
        
        let identifierData = getDeviceIdentifier()
        print( "device id:", identifierData.hexDescription )
        
        print( "using certificate: \(String(describing: transaction.payment.requestData))" )
        // Get the receipt if it's available
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
            FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {

            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                print(receiptData)

                let receiptString = receiptData.base64EncodedString(options: [])
                print( receiptString )
                // Read receiptData
            }
            catch { print("Couldn't read receipt data with error: " + error.localizedDescription) }
        }


        // TODO
        return true;
    }
}

// MARK: - SKPaymentTransactionObserver

/// Extends StoreObserver to conform to SKPaymentTransactionObserver.
extension StoreObserver: SKPaymentTransactionObserver {
    /// Called when there are transactions in the payment queue.
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                print( "purchasing, to prompt UI" )
                break
            // Do not block the UI. Allow the user to continue using the app.
            case .deferred:
                print( "deferred: Allow the user to continue using your app." )
            // The purchase was successful.
            case .purchased:
                handlePurchased(transaction)
            // The transaction failed.
            case .failed:
                handleFailed(transaction)
            // There're restored products.
            case .restored:
                handleRestored(transaction)
            @unknown default: fatalError(Messages.unknownPaymentTransaction)
            }
        }
    }
    
    /// Logs all transactions that have been removed from the payment queue.
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            print("[queue] \(transaction.payment.productIdentifier) was removed from the payment queue.")
        }
    }
    
    /// Called when an error occur while restoring purchases. Notify the user about the error.
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        if let error = error as? SKError, error.code != .paymentCancelled {
            DispatchQueue.main.async {
                self.delegate?.storeObserverDidReceiveMessage(error.localizedDescription)
            }
        }
    }
    
    /// Called when all restorable transactions have been processed by the payment queue.
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if !hasRestorablePurchases {
            DispatchQueue.main.async {
                // mainly for dev debug purpose
                self.delegate?.storeObserverDidReceiveMessage( Messages.noRestorablePurchases )
            }
        } else {
            print("[queue] all restorable transactions have been processed by the payment queue.")
        }
    }
    
    public func paymentQueue(
      _ queue: SKPaymentQueue,
      didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]
    ) {
      for identifier in productIdentifiers {
        //purchasedProductIdentifiers.remove(identifier)
        //UserDefaults.standard.removeObject(forKey: identifier)
        //deliverPurchaseNotificationFor(identifier: identifier)
        // TODO
        print( "product \(identifier) revoked!!!" )
      }
    }
    
    // MARK: - SKReceiptRefreshRequest
    
    /*
    , SKRequestDelegate
 
    // If you can’t find the receipt, you should request it. This requires you to have an internet connection and be logged in to the App Store.
    let request = SKReceiptRefreshRequest()
    request.delegate = self
    request.start()

    
    func requestDidFinish(_ request: SKRequest) {
        print("requestDidFinish")
    }

    @available(iOS 3.0, *)
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("requst(_:didFailWithError:)")
        print( error )
    }
    */
}
