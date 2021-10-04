//
//  DetailsViewModel.swift
//  ScanID
//
//  Created by Artūrs Āre on 28/09/2021.
//

import Foundation
import Combine

final class DetailsViewModel: ObservableObject {

    @Published var isLoading = true
    @Published var listDataSource = [String]()
    @Published var loadingText = "Let us 🦭 your data securely..."

    private var bag = Set<AnyCancellable>()

    init(document: PassthroughSubject<Document, Error>) {

        document.sink(receiveCompletion: { [weak self] completion in
            if case let .failure(error) = completion {
                self?.loadingText = "Error: " + error.localizedDescription
            }
        }, receiveValue: { [weak self] document in
            self?.isLoading = false
            self?.listDataSource = document.listDescription.map { $0.0 + $0.1 }
        }).store(in: &bag)
    }
}

extension Document {
    var listDescription: [(String, String)] {
        [
            ("Name: ", givenNames),
            ("Surname: ", surname),
            ("Birth date: ", birthdate),
            ("ID: ", personalNumber)
        ]
    }
}
