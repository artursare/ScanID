//
//  IdentificationDocumentAPI.swift
//  ScanID
//
//  Created by Artūrs Āre on 02/10/2021.
//

import Foundation
import Combine
import Networking


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
        return client
    }()

    func validate(photoData: Data, type: IDType) -> AnyPublisher<Validatation, Error> {
        let document = photoData.base64EncodedString()
        let digest = ""
        return post("/validate", params: ["document" : document, "digest" : digest, "type" : type.code])
    }
}
