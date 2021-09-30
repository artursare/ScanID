//
//  CaptureView.swift
//  DocumentScanner
//
//  Created by Artūrs Āre on 30/09/2021.
//

import SwiftUI

protocol CaptureViewDelegte {
    func dataReceived(data: Data)
}

/// SwiftUI wrapper for UIViewController working with AVCaptureSession
public struct CaptureView: UIViewControllerRepresentable, CaptureViewDelegte {

    @Binding var captureData: Data

    private let embeddedVC: CaptureViewController

    public init(captureData: Binding<Data>) {
        _captureData = captureData

        let vc = CaptureViewController()
        embeddedVC = vc
        vc.delegate = self
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        embeddedVC
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    public func capture() {
        embeddedVC.capturePhoto()
    }

    func dataReceived(data: Data) {
        captureData = data
    }
}
