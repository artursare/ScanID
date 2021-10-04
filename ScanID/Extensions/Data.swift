//
//  Data.swift
//  ScanID
//
//  Created by Artūrs Āre on 04/10/2021.
//

import Foundation
import CryptoKit

extension Data {
    var sha1Digest: String {
        Insecure.SHA1.hash(data: self).map { String(format: "%02x", $0) }.joined()
    }
}
