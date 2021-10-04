//
//  ScannerViewModel.swift
//  ScanID
//
//  Created by Artūrs Āre on 28/09/2021.
//

import UIKit
import Combine

final class ScannerViewModel: ObservableObject {

    @Published var imageData = Data()
    @Published var photoEnabled = false
    @Published var captureButtonText = ""
    @Published var image = UIImage()
    @Published var canSend = false

    private let api = IdentificationDocumentAPI()

    private var bag = Set<AnyCancellable>()

    init() {
        $photoEnabled.sink { isEnabled in
            self.captureButtonText = isEnabled ? "Take Photo" : "Try finding better angle"
        }.store(in: &bag)

        $imageData.sink { data in
            guard let image = UIImage(data: data) else { return }
            self.image = image
            self.canSend = true
        }.store(in: &bag)
    }

    func sendPhoto() {
        let type = IDType(type: .id, country: "lv", side: .rev)
        api.validate(photoData: imageData, type: type)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            }) { validation in
                let json = try? JSONSerialization.jsonObject(with: validation, options: [])
                print(json)
            }.store(in: &bag)
    }
}
