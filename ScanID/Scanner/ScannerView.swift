//
//  ScannerView.swift
//  ScanID
//
//  Created by Artūrs Āre on 28/09/2021.
//

import SwiftUI
import DocumentScanner

struct ScannerView: View {

    @State var imageData = Data()

    var body: some View {

        let captureView = DocumentScanner.ScannerView(captureData: $imageData)
        VStack {
            captureView

            Spacer()

            Button("Take Photo", action: captureView.capture)
        }
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
