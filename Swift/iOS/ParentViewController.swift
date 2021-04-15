/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages the child view controllers: Products and Purchases. Displays a Restore button that allows you to restore all previously purchased
 non-consumable and auto-renewable subscription products. Requests product information about a list of product identifiers using StoreManager. Calls
 StoreObserver to implement the restoration of purchases.
*/

import UIKit

class ParentViewController: UIViewController {
    // MARK: - Types
    
    fileprivate enum Segment: Int {
        case products, purchases
    }
    
    // MARK: - Properties
    
    @IBOutlet weak fileprivate var containerView: UIView!
    @IBOutlet weak fileprivate var segmentedControl: UISegmentedControl!
    @IBOutlet weak fileprivate var restoreButton: UIBarButtonItem!
    
    fileprivate var utility = UI_Utilities()
    
    fileprivate lazy var products: Products = {
        let identifier = ViewControllerIdentifiers.products
        guard let controller = storyboard?.instantiateViewController(withIdentifier: identifier) as? Products
            else { fatalError("\(Messages.unableToInstantiateProducts)") }
        return controller
    }()
    
    fileprivate lazy var purchases: Purchases = {
        let identifier = ViewControllerIdentifiers.purchases
        guard let controller = storyboard?.instantiateViewController(withIdentifier: identifier) as? Purchases
            else { fatalError("\(Messages.unableToInstantiatePurchases)") }
        return controller
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable or hide the button.
        restoreButton.disable()
        
        StoreManager.shared.delegate = self
        StoreObserver.shared.delegate = self
        
        // Fetch product information.
        fetchProductInformation()
    }
    
    // MARK: - Switching Between View Controllers
    
    /// Adds a child view controller to the container.
    fileprivate func addBaseViewController(_ viewController: BaseViewController) {
        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.frame = containerView.bounds
        containerView.addSubview(viewController.view)
        
        NSLayoutConstraint.activate([viewController.view.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
                                     viewController.view.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
                                     viewController.view.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
                                     viewController.view.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor)])
        viewController.didMove(toParent: self)
    }
    
    /// Removes a child view controller from the container.
    fileprivate func removeBaseViewController(_ viewController: BaseViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    /// Switches between the Products and Purchases view controllers.
    fileprivate func switchToViewController(segment: Segment) {
        switch segment {
        case .products:
            removeBaseViewController(purchases)
            addBaseViewController(products)
        case .purchases:
            removeBaseViewController(products)
            addBaseViewController(purchases)
        }
    }
    
    // MARK: - Fetch Product Information
    
    /// Retrieves product information from the App Store.
    fileprivate func fetchProductInformation() {
        // First, let's check whether the user is allowed to make purchases. Proceed if they are allowed. Display an alert, otherwise.
        if StoreObserver.shared.isAuthorizedForPayments {
            restoreButton.enable()
            
            // hard code IPA identifiers
            let identifiers = ["com.temporary.renew" , "not_exist_iap_id" , "com.temporary.c" , "com.temporary.nc"]
            
                    // UI switch
                    switchToViewController(segment: .products)
                    // Refresh the UI with identifiers to be queried.
                    products.reload(with: [Section(type: .invalidProductIdentifiers, elements: identifiers)])
            
            // Fetch product information.
            StoreManager.shared.startProductRequest(with: identifiers)

        } else {
            // Warn the user that they are not allowed to make purchases.
            alert(with: Messages.status, message: Messages.cannotMakePayments)
        }
    }
    
    // MARK: - Display Alert
    
    /// Creates and displays an alert.
    fileprivate func alert(with title: String, message: String) {
        let alertController = Utils.alert(title, message: message)
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Restore All Appropriate Purchases
    
    /// Called when tapping the "Restore" button in the UI.
    @IBAction func restore(_ sender: UIBarButtonItem) {
        // Calls StoreObserver to restore all restorable purchases.
        StoreObserver.shared.restore()
    }
    
    // MARK: - Handle Segmented Control Tap
    
    /// Called when tapping any segmented control in the UI.
    @IBAction func segmentedControlSelectionDidChange(_ sender: UISegmentedControl) {
        guard let segment = Segment(rawValue: sender.selectedSegmentIndex)
            else { fatalError("\(Messages.unknownSelectedSegmentIndex)\(sender.selectedSegmentIndex)).") }
        
        switchToViewController(segment: segment)
        
        switch segment {
        case .products: fetchProductInformation()
        case .purchases: purchases.reload(with: utility.dataSourceForPurchasesUI)
        }
    }
    
    // MARK: - Handle Restored Transactions
    
    /// Handles successful restored transactions. Switches to the Purchases view.
    fileprivate func handleRestoredSucceededTransaction() {
        utility.restoreWasCalled = true
        
        // Refresh the Purchases view with the restored purchases.
        switchToViewController(segment: .purchases)
        purchases.reload(with: utility.dataSourceForPurchasesUI)
        segmentedControl.selectedSegmentIndex = 1
    }
}

// MARK: - StoreManagerDelegate

/// Extends ParentViewController to conform to StoreManagerDelegate.
extension ParentViewController: StoreManagerDelegate {
    func storeManagerDidReceiveResponse(_ response: [Section]) {
        switchToViewController(segment: .products)
        // Switch to the Products view controller.
        products.reload(with: response)
        segmentedControl.selectedSegmentIndex = 0
    }
    
    func storeManagerDidReceiveMessage(_ message: String) {
        alert(with: Messages.productRequestStatus, message: message)
    }
}

// MARK: - StoreObserverDelegate

/// Extends ParentViewController to conform to StoreObserverDelegate.
extension ParentViewController: StoreObserverDelegate {
    func storeObserverDidReceiveMessage(_ message: String) {
        // when
        //   error in purchase,
        //   error in restore,
        //   all restorable transactions have been processed
        // we have filtered the user-cancel-payment message
        alert(with: Messages.purchaseStatus, message: message)
    }
    
    func storeObserverRestoreDidSucceed(_ productID: String) {
        print( "restore \(productID) successfully")
        handleRestoredSucceededTransaction()
    }
    func storeObserverPurchaseSucceed(_ productID: String) {
        print( "purchase \(productID) successfully")
    }
}
