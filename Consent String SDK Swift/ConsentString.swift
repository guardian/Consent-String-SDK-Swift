//
//  ConsentString.swift
//  gdprConsentStringSwift
//
//  Created by Daniel Kanaan on 4/17/18.
//  Copyright © 2018 Daniel Kanaan. All rights reserved.
//

import Foundation

class ConsentString:ConsentStringProtocol {

    enum Error: Swift.Error {
        case invalidEncodingType
    }

    /**
     The current Consent String.  Setting will allow replacement of the curr
 */
    public var consentString: String {
        
        //error correction in didSet resets old value if base64decoding fails
        didSet {
            guard let dataValue = Data(base64Encoded: consentString.base64Padded) else {
                print("New Consent String Value is not base64 decodable. Throwing away changes.")
                consentString = oldValue
                return
            }
            consentData = dataValue
        }
        
    }
    
    var consentData:Data
    
    /**
     Creates new instance of a ConsentString object
     
     - parameter consentString: web-safe base64 encoded consent string
    */
    public required init(consentString: String) throws {
        self.consentString = consentString
        guard let dataValue = Data(base64Encoded: self.consentString.base64Padded) else {
            throw ConsentStringError.base64DecodingFailed
        }
        consentData = dataValue
    }

    public var created: Date {
        return Date(timeIntervalSince1970: TimeInterval(consentData.intValue(for: Constants.created)) / 10)
    }

    public var updated: Date {
        return Date(timeIntervalSince1970: TimeInterval(consentData.intValue(for: Constants.updated)) / 10 )
    }
    
    public var cmpId: Int {
        return Int(consentData.intValue(for: Constants.cmpIdentifier))
    }

    public var cmpVersion: Int {
        return Int(consentData.intValue(for: Constants.cmpVersion))
    }
    
    public var consentScreen: Int {
        return Int(consentData.intValue(for: Constants.consentScreen))
    }
    
    public var consentLanguage: String {
        var data = consentData.data(for: Constants.consentLanguage)
        data.insert(0, at: 0)
        let string = data.base64EncodedString()
        return String(string[string.index(string.startIndex, offsetBy: 2)...])
    }
    
    public var purposesAllowed: [Int8] {
        var resultsArray = [Int8]()
        for purposeId in 1...Constants.purposes.length {
            let purposeBit = Int64(Constants.purposes.location - 1 + purposeId)
            let value = Int(consentData.intValue(fromBit: purposeBit, toBit: purposeBit))
            if value > 0 {
                resultsArray.append(Int8(purposeId))
            }
        }
        return resultsArray
    }
    
    public func purposeAllowed(forPurposeId purposeId: Int8) -> Bool {
        if purposeId > Constants.purposes.length || purposeId < 1 {
            return false
        }
        let purposeBit = Int64(Constants.purposes.location) - 1 + Int64(purposeId)
        let value = Int(consentData.intValue(fromBit: purposeBit, toBit: purposeBit))
        if value > 0 {
            return true
        }
        return false
    }

    public var vendorListVersion: Int {
        return Int(consentData.intValue(for: Constants.vendorListVersion))
    }
    
    //Used to determine whether we need to check for a vendor ID at all if it's greater than this value
    public var maxVendorId : Int {
        get {
            return Int(consentData.intValue(for: Constants.maxVendorIdentifier))
        }
    }

    public func encodingType() throws -> VendorEncodingType {
        guard let encodingType = VendorEncodingType(rawValue: Int(consentData.intValue(for: Constants.encodingType))) else {
            throw Error.invalidEncodingType
        }
        return encodingType
    }
    
    private var isBitField:Bool {
        get {
            let value = consentData.intValue(for: Constants.encodingType)
            return value == 0
        }
    }
    
    private var isRange:Bool {
        get {
            return !isBitField
        }
    }
    
    private let bitFieldVendorStart:Int64 = 173
    private let rangeDefaultConsent:Int64 = 173

    public var defaultConsent: Bool {
        return consentData.intValue(for: Constants.defaultConsent) == 0 ? false : true
    }

    public var allowedVendorIds: [Int16] {
        if isBitField {
            let vendorIds = (1...maxVendorId).compactMap { isVendorAllowed(vendorId: $0) ? Int16($0) : nil }
            return vendorIds
        } else {
            var vendorIds = [Int16]()
            let consentDataMaxBit = consentData.count * 8 - 1 //1 byte, last bit is 7, for 2 bytes, last is 15 etc...
            let numEntries = Int(consentData.intValue(for: Constants.numberOfEntries))
            let allVendorIds = Set(1...Int16(maxVendorId))
            var rangeStart = Int64(Constants.rangeEntryOffset)
            for _ in 0..<numEntries {
                let entryType = consentData.intValue(fromBit: rangeStart, toBit: rangeStart)
                if consentDataMaxBit < rangeStart + 16 + 1  + (entryType * 16) {//typebit + either 16 or 32
                    break
                }
                if entryType == 0 {//single
                    let thisVendorId = Int16(consentData.intValue(fromBit: rangeStart + 1, toBit: rangeStart + 16))
                    vendorIds.append(thisVendorId)
                    rangeStart += 17
                } else if entryType == 1 {//range
                    let vendorStart = consentData.intValue(fromBit: rangeStart + 1, toBit: rangeStart + 16)
                    let vendorFinish = consentData.intValue(fromBit: rangeStart + 18, toBit: rangeStart + 32)
                    for vendorId in vendorStart...vendorFinish {
                        vendorIds.append(Int16(vendorId))
                    }
                    rangeStart += 33
                }
            }

            if defaultConsent {
                let allowedVendorIds = allVendorIds.subtracting(vendorIds).sorted()
                return allowedVendorIds
            } else {
                return vendorIds
            }
        }
    }

    public func isVendorAllowed(vendorId: Int) -> Bool {
        if vendorId > maxVendorId {
            return false
        }
        if isBitField {
            let vendorBitField = bitFieldVendorStart + Int64(vendorId) - 1
            //not enough bits
            guard vendorBitField < consentData.count * 8 else {
                return false
            }
            let value = consentData.intValue(fromBit: vendorBitField, toBit: vendorBitField)
            if value == 0 {
                return false
            } else {
                return true
            }
        } else {
            let consentDataMaxBit = consentData.count * 8 - 1 //1 byte, last bit is 7, for 2 bytes, last is 15 etc...
            let defaultConsent = consentData.intValue(for: Constants.defaultConsent)
            let numEntries = Int(consentData.intValue(for: Constants.numberOfEntries))
            var rangeStart = Int64(Constants.rangeEntryOffset)
            for _ in 0..<numEntries {
                let entryType = consentData.intValue(fromBit: rangeStart, toBit: rangeStart)
                if consentDataMaxBit < rangeStart + 16 + 1  + (entryType * 16) {//typebit + either 16 or 32
                    break
                }
                if entryType == 0 {//single
                    let thisVendorId = consentData.intValue(fromBit: rangeStart + 1, toBit: rangeStart + 16)
                    if vendorId == thisVendorId {
                        //if vendorId matches this one, then return opposite of default consent
                        return defaultConsent == 1 ? false : true
                    }
                    rangeStart += 17
                } else if entryType == 1 {//range
                    let vendorStart = consentData.intValue(fromBit: rangeStart + 1, toBit: rangeStart + 16)
                    let vendorFinish = consentData.intValue(fromBit: rangeStart + 18, toBit: rangeStart + 32)
                    if vendorStart <= vendorId && vendorId <= vendorFinish {
                        //if vendorId falls within range, then return opposite of default consent
                        return defaultConsent == 1 ? false : true
                    }
                    rangeStart += 33
                }
            }
            return defaultConsent == 0 ? false : true
        }
    }
    
}
