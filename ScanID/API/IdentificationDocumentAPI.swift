//
//  IdentificationDocumentAPI.swift
//  ScanID
//
//  Created by Artūrs Āre on 02/10/2021.
//

import Foundation
import Combine
import Networking
import CryptoKit

/*
 {
   "status" : "completed",
   "valid" : true,
   "validation_score" : 100.0,
   "ocr_texts" : ["string"],
   "ocr_labels" : [{
     "description" : "string",
     "score" : 100.0,
   }],
   "data": {
     "first_name" : "string",
     "last_name" : "string",
     "birthdate" : "string",
     "sex" : "string",
     "personal_number" : "string",
     "document_number" : "string",
     "document_expires" : "string",
     "document_valid" : true
   }
 }
 */

struct Document: Codable, NetworkingJSONDecodable {

}

struct Validatation: Codable, NetworkingJSONDecodable {

}

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

struct IdentificationDocumentAPI: NetworkingService {
    private static let apiKey = "tgxCPECR6A1sn09PoCSxXaAMQoLnVRT889ejeLCW"

    let network: NetworkingClient = {
        var client = NetworkingClient(baseURL: "https://api.identiway.com/docs")
        client.headers["x-api-key"] = apiKey
        client.parameterEncoding = .json
        return client
    }()

    func validate(photoData: Data, type: IDType) -> AnyPublisher<Data, Error> {
        let document = photoData.base64EncodedString()
        let digest = Insecure.SHA1.hash(data: photoData).map { String(format: "%02x", $0) }.joined()

        return post("/validate", params: ["document" : document, "digest" : digest, "type" : type.code])
    }
}
