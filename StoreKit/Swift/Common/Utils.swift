//
//  Utils.swift
//  InAppPurchases
//
//  Created by mebusy on 2021/4/15.
//  Copyright © 2021 Apple. All rights reserved.
//

import StoreKit
#if os (macOS)
import Cocoa
#else
import UIKit
#endif

class Utils {
    
    // MARK: - Create Alert

    #if os (iOS) || os (tvOS)
    /// - returns: An alert with a given title and message.
    static func alert(_ title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString(Messages.okButton, comment: Messages.emptyString),
                                   style: .default, handler: nil)
        alertController.addAction(action)
        return alertController
    }
    #endif
}


extension Data {
    // Data, byte array to hex string
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}



