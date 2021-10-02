//
//  ScannerView.swift
//  ScanID
//
//  Created by Artūrs Āre on 28/09/2021.
//

import SwiftUI
import DocumentScanner

struct ScannerView: View {

    @ObservedObject var vm: ScannerViewModel

    var body: some View {
        let captureView = CaptureView(captureData: $vm.imageData,
                                      documentVisible: $vm.photoEnabled)
        VStack {
            captureView

            Button(vm.captureButtonText, action: captureView.capture)
                .disabled(!vm.photoEnabled)

//            Spacer()

            Image(uiImage: vm.image)
                .resizable()
                .aspectRatio(contentMode: .fit)

//            Spacer()

            Button("Use this photo", action: vm.sendPhoto)
                .opacity(vm.canSend ? 1 : 0)

        }
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView(vm: ScannerViewModel())
    }
}
