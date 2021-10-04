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

    @State private var showingSheet = false

    var body: some View {
        let captureView = CaptureView(captureData: $vm.imageData,
                                      documentVisible: $vm.photoEnabled)
        VStack {

            Text("Scanner type set to \(vm.type.code)")

            captureView

            Button(vm.captureButtonText, action: captureView.capture)
                .disabled(!vm.photoEnabled)
                .frame(height: 44)

            Image(uiImage: vm.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)

            Button("Use this photo", action: {
                vm.sendPhoto()
                showingSheet.toggle()
            })
            .frame(height: 44)
            .opacity(vm.canSend ? 1 : 0)
            .padding(.bottom)

        }
        .padding()
        .sheet(isPresented: $showingSheet) {
            DetailsView(vm: DetailsViewModel(document: vm.document))
        }
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView(vm: ScannerViewModel())
    }
}
