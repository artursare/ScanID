//
//  CaptureView.swift
//  DocumentScanner
//
//  Created by Artūrs Āre on 30/09/2021.
//

import SwiftUI

protocol CaptureViewDelegte {
    func dataReceived(data: Data)
    func documentVisible(_ isVisible: Bool)
}

/// SwiftUI wrapper for UIViewController working with AVCaptureSession
public struct CaptureView: UIViewControllerRepresentable, CaptureViewDelegte {

    @Binding var captureData: Data
    @Binding var documentVisible: Bool

    private let embeddedVC: CaptureViewController

    public init(captureData: Binding<Data>, documentVisible: Binding<Bool>) {
        _captureData = captureData
        _documentVisible = documentVisible

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

    func documentVisible(_ isVisible: Bool) {
        documentVisible = isVisible
    }
}
