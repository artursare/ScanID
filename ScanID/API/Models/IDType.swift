//
//  IDType.swift
//  ScanID
//
//  Created by Artūrs Āre on 04/10/2021.
//

import Foundation

struct IDType {
    let type: Type
    let country: String
    let side: Side

    enum Side: String {
        case av
        case rev
    }

    enum `Type`: String {
        case id
        case pass
    }

    var code: String {
        "\(country)_\(type.rawValue)_\(side.rawValue)"
    }
}
