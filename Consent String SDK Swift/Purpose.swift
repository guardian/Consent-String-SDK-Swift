//
//  Purpose.swift
//  Consent String SDK Swift
//
//  Created by Alexander Edge on 17/05/2019.
//  Copyright © 2019 Interactive Advertising Bureau. All rights reserved.
//

import Foundation

/// Purposes are listed in the global Vendor List. Resultant consent value is the "AND" of the applicable bit(s) from this field and a vendor's specific consent bit. Purpose #1 maps to the first (most significant) bit, purpose #24 maps to the last (least significant) bit.
public struct Purposes: OptionSet {

    public static let storageAndAccess = Purposes(rawValue: 1 << 23)
    public static let personalization = Purposes(rawValue: 1 << 22)
    public static let adSelection = Purposes(rawValue: 1 << 21)
    public static let contentDelivery = Purposes(rawValue: 1 << 20)
    public static let measurement = Purposes(rawValue: 1 << 19)

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
