//
//  ConsentStringBuilder.swift
//  Consent String SDK Swift
//
//  Created by Alexander Edge on 17/05/2019.
//  Copyright © 2019 Interactive Advertising Bureau. All rights reserved.
//

import Foundation

public protocol RangeEntry {

    /// Size of range entry in bits
    var size: Int { get }

    /// Append this range entry to the bit buffer
    ///
    /// - Parameters:
    ///   - data: bit buffer
    ///   - currentOffset: currentOffset current offset in the buffer
    /// - Returns: new offset
    func append(to data: Data, currentOffset: Int) -> Int

    /// Check if range entry is valid for the specified max vendor id
    ///
    /// - Parameter maxVendorId: max vendor id
    /// - Returns: true if range entry is valid, false otherwise
    func isValid(maxVendorId: Int) -> Bool
}

public struct ConsentStringBuilder {

    enum Error: Swift.Error {
        case invalidRangeEntry(RangeEntry)
        case invalidIntegerSize
    }

    /// Epoch deciseconds when record was created
    let created: Date

    /// Epoch deciseconds when consent string was last updated
    let updated: Date

    /// Consent Manager Provider ID that last updated the consent string
    let cmpIdentifier: Int

    /// Consent Manager Provider version
    let cmpVersion: Int

    /// Screen number in the CMP where consent was given
    let consentScreenID: Int

    /// Two-letter ISO639-1 language code that CMP asked for consent in
    let consentLanguage: String

    /// Version of vendor list used in most recent consent string update
    let vendorListVersion: Int

    /// The maximum VendorId for which consent values are given.
    let maxVendorId: Int

    /// Vendor encoding type
    let vendorEncodingType: VendorEncodingType

    /// Set of allowed purposes
    let allowedPurposes: Set<Int>

    /// Set of VendorIds for which the vendors have consent
    let vendorsBitField: Set<Int> // used when bit field encoding is used

    /// List of VendorIds or a range of VendorIds for which the vendors have consent
    let rangeEntries: [RangeEntry] // used when range entry encoding is used

    /// Default consent for VendorIds not covered by a RangeEntry. false=No Consent true=Consent
    let defaultConsent: Bool

    func build() throws -> String {

        // Calculate size of bit buffer in bits
        var bitBufferSizeInBits: Int
        switch vendorEncodingType {
        case .range:
            // check if each range entry is valid
            if let invalidRangeEntry = rangeEntries.first(where: { !$0.isValid(maxVendorId: maxVendorId) }) {
                throw Error.invalidRangeEntry(invalidRangeEntry)
            }
            bitBufferSizeInBits = Constants.rangeEntryOffset + rangeEntries.reduce(into: 0) { $0 + $1.size }
        case .bitfield:
            bitBufferSizeInBits = Constants.vendorBitFieldOffset + maxVendorId
        }

        // Create new bit buffer
        let (byteCount, bitRemainder) = bitBufferSizeInBits.quotientAndRemainder(dividingBy: 8)
        let totalBytes = byteCount + (bitRemainder > 0 ? 1 : 0)
        var data = Data(repeating: 0, count: totalBytes)

        var consentString = String(repeating: "0", count: totalBytes * 8)

        consentString.replaceSubrange(Range(Constants.version, in: consentString)!, with: String(1, radix: 2).pad(toLength: Constants.version.length))
        consentString.replaceSubrange(Range(Constants.created, in: consentString)!, with: String(Int(created.timeIntervalSince1970 * 1000 / 100), radix: 2).pad(toLength: Constants.created.length))
        consentString.replaceSubrange(Range(Constants.updated, in: consentString)!, with: String(Int(updated.timeIntervalSince1970 * 1000 / 100), radix: 2).pad(toLength: Constants.updated.length))
        consentString.replaceSubrange(Range(Constants.cmpIdentifier, in: consentString)!, with: String(cmpIdentifier, radix: 2).pad(toLength: Constants.cmpIdentifier.length))
        consentString.replaceSubrange(Range(Constants.cmpVersion, in: consentString)!, with: String(cmpVersion, radix: 2).pad(toLength: Constants.cmpVersion.length))
        consentString.replaceSubrange(Range(Constants.consentScreen, in: consentString)!, with: String(consentScreenID, radix: 2).pad(toLength: Constants.consentScreen.length))

        let language = String(consentLanguage[consentLanguage.index(consentLanguage.startIndex, offsetBy: 0)].asciiValue! - 65, radix: 2).pad(toLength: 6) + String(consentLanguage[consentLanguage.index(consentLanguage.startIndex, offsetBy: 1)].asciiValue! - 65, radix: 2).pad(toLength: 6)
        consentString.replaceSubrange(Range(Constants.consentLanguage, in: consentString)!, with: language)
        consentString.replaceSubrange(Range(Constants.vendorListVersion, in: consentString)!, with: String(vendorListVersion, radix: 2).pad(toLength: Constants.vendorListVersion.length))

        // purposes
        for i in 0..<Constants.purposes.length {
            guard let range = Range(NSRange(location: Constants.purposes.location + i, length: 1), in: consentString) else { continue }
            if allowedPurposes.contains(i + 1) {
                consentString.replaceSubrange(range, with: "1")
            } else {
                consentString.replaceSubrange(range, with: "0")
            }
        }

        consentString.replaceSubrange(Range(Constants.maxVendorIdentifier, in: consentString)!, with: String(maxVendorId, radix: 2).pad(toLength: Constants.maxVendorIdentifier.length))
        consentString.replaceSubrange(Range(Constants.encodingType, in: consentString)!, with: String(vendorEncodingType.rawValue, radix: 2).pad(toLength: Constants.encodingType.length))

        // range sections
        if vendorEncodingType == .range {
            // range encoding
        } else {
            // bit field encoding
            for i in 0..<maxVendorId {
                guard let range = Range(NSRange(location: Constants.vendorBitFieldOffset + i, length: 1), in: consentString) else { continue }
                if vendorsBitField.contains(i + 1) {
                    consentString.replaceSubrange(range, with: "1")
                } else {
                    consentString.replaceSubrange(range, with: "0")
                }
            }
        }

        return consentString
    }

}

extension String {
    func pad(with character: String = "0", toLength length: Int) -> String {
        let padCount = length - count
        guard padCount > 0 else { return self }
        return String(repeating: character, count: padCount) + self
    }
}

