//
//  Document.swift
//  ScanID
//
//  Created by Artūrs Āre on 04/10/2021.
//

import Foundation
import Networking

/*
 data =     {
     birthdate = 230105;
     country = LVA;
     "document_expires" = string;
     "document_number" = string;
     "document_type" = I;
     "document_valid" = 1;
     "given_names" = ARTURS;
     nationality = LVA;
     "personal_number" = "string";
     sex = M;
     surname = ARE;
 };
 */

struct Validatation: Decodable, NetworkingJSONDecodable {
    let data: Document
}

struct Document: Decodable, NetworkingJSONDecodable {
    let givenNames: String
    let surname: String
    let personalNumber: String
    let birthdate: String
}

/// Snake case support
extension Decodable where Self: NetworkingJSONDecodable {
    static func decode(_ json: Any) throws -> Self {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        let model = try decoder.decode(Self.self, from: data)
        return model
    }
}
