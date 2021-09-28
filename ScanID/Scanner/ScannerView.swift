//
//  ScannerView.swift
//  ScanID
//
//  Created by Artūrs Āre on 28/09/2021.
//

import SwiftUI
import DocumentScanner

struct ScannerView: View {
    var body: some View {
        DocumentScanner.ScannerView()
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
