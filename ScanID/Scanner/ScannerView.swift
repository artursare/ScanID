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
    @State var photoEnabled = false

    var body: some View {
        let captureView = CaptureView(captureData: $imageData, documentVisible: $photoEnabled)
        VStack {
            captureView

            Spacer()

            Image(uiImage: UIImage(data: imageData) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fit)

            Spacer()

            let text = photoEnabled ? "Take Photo" : "Try finding better angle"
            Button(text, action: captureView.capture)
                .disabled(!photoEnabled)
        }
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
