//
//  IdentificationDocumentAPI.swift
//  ScanID
//
//  Created by Artūrs Āre on 02/10/2021.
//

import Foundation
import Combine
import Networking

struct IdentificationDocumentAPI: NetworkingService {
    private static let apiKey = "tgxCPECR6A1sn09PoCSxXaAMQoLnVRT889ejeLCW"

    let network: NetworkingClient = {
        var client = NetworkingClient(baseURL: "https://api.identiway.com/docs")
        client.headers["x-api-key"] = apiKey
        client.parameterEncoding = .json
        return client
    }()

    func validate(photoData: Data, type: IDType) -> AnyPublisher<Validatation, Error> {
        let document = photoData.base64EncodedString()
        let digest =  photoData.sha1Digest

        return post("/validate", params: ["document" : document, "digest" : digest, "type" : type.code])
    }
}
