//
//  CaptureViewController.swift
//  DocumentScanner
//
//  Created by Artūrs Āre on 28/09/2021.
//
//  Based on SPM dependencies/MRZScanner/Example/Example/ViewController.swift


import UIKit
import AVFoundation
import MRZScanner

class CaptureViewController: UIViewController {

    /// 💥😑 due to how swiftui handles views, I always ended up with not running AVCaptureSession
    /// After full day lost found the solution here https://stackoverflow.com/a/65414698
    /// it makes sense and keeps the session alive
    static let shared = CaptureViewController()

    var delegate: CaptureViewDelegte? = nil

    // MARK: UI objects
    private let previewView = PreviewView()
    private let cutoutView = UIView()
    private let maskLayer = CAShapeLayer()

    // MARK: Scanning related
    private weak var clearTimer: Timer?
    private let scanner = LiveMRZScanner()
    private var scanningIsEnabled = true {
        didSet {
            scanningIsEnabled ? captureSession.startRunning() : captureSession.stopRunning()

            if !scanningIsEnabled {
                removeBoxes()
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: Capture related objects
    private let captureSession = AVCaptureSession()
    private let captureSessionQueue = DispatchQueue(label: "com.aita.mrzExample.captureSessionQueue")

    private var captureDevice: AVCaptureDevice?

    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "com.aita.mrzExample.videoDataOutputQueue")

    private let photoOutput = AVCapturePhotoOutput()

    /// Device orientation. Updated whenever the orientation changes to a different supported orientation.
    private var currentOrientation = UIDeviceOrientation.portrait

    private func checkCaptureDeviceAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        default:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else { fatalError("To work, you need to give access to the camera.") }
                return
            }
        }
    }

    // MARK: Region of interest (ROI) and text orientation
    // Region of video data output buffer that recognition should be run on.
    // Gets recalculated once the bounds of the preview layer are known.
    var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    // Orientation of text to search for in the region of interest.
    var textOrientation = CGImagePropertyOrientation.up

    // MARK: Coordinate transforms
    var bufferAspectRatio: Double!
    // Transform from UI orientation to buffer orientation.
    var uiRotationTransform = CGAffineTransform.identity
    // Transform bottom-left coordinates to top-left.
    var bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
    // Transform coordinates in ROI to global coordinates (still normalized).
    var roiToGlobalTransform = CGAffineTransform.identity

    // Vision -> AVF coordinate transform.
    var visionToAVFTransform = CGAffineTransform.identity

    // MARK: View controller methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()

        checkCaptureDeviceAuthorization()

        // Set up preview view.
        previewView.session = captureSession
        previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        // Set up cutout view.
        cutoutView.backgroundColor = UIColor.gray.withAlphaComponent(0.1)
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.fillRule = .evenOdd
        cutoutView.layer.mask = maskLayer

        // Starting the capture session is a blocking call. Perform setup using
        // a dedicated serial dispatch queue to prevent blocking the main thread.
        captureSessionQueue.async {
            self.setupCamera()

            // Calculate region of interest now that the camera is setup.
            DispatchQueue.main.async {
                // Figure out initial ROI.
                self.calculateRegionOfInterest()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCutout()
    }

    // MARK: Setup
    private func setup() {
        view.insetsLayoutMarginsFromSafeArea = false
        previewView.translatesAutoresizingMaskIntoConstraints = false
        cutoutView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        view.addSubview(cutoutView)

        NSLayoutConstraint.activate([

            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.heightAnchor.constraint(equalTo: previewView.widthAnchor, multiplier: 1.0/1.6),

            cutoutView.topAnchor.constraint(equalTo: previewView.topAnchor),
            cutoutView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),
            cutoutView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            cutoutView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor)
        ])
    }

    private func calculateRegionOfInterest() {
        // In landscape orientation the desired ROI is specified as the ratio of
        // buffer width to height. When the UI is rotated to portrait, keep the
        // vertical size the same (in buffer pixels). Also try to keep the
        // horizontal size the same up to a maximum ratio.
        let desiredHeightRatio = 0.2
        let desiredWidthRatio = 0.9
        let maxPortraitWidth = 0.9

        // Figure out size of ROI.
        let size: CGSize
        if currentOrientation.isPortrait || currentOrientation == .unknown {
            size = CGSize(width: min(desiredWidthRatio * bufferAspectRatio, maxPortraitWidth),
                          height: desiredHeightRatio / bufferAspectRatio)
        } else {
            size = CGSize(width: desiredWidthRatio, height: desiredHeightRatio)
        }

        regionOfInterest.origin = CGPoint(x: (1 - size.width) / 2, y: (1 - size.height) / 2.6)
        regionOfInterest.size = size

        // ROI changed, update transform.
        setupOrientationAndTransform()

        // Update the cutout to match the new ROI.
        DispatchQueue.main.async {
            // Wait for the next run cycle before updating the cutout. This
            // ensures that the preview layer already has its new orientation.
            self.updateCutout()
        }
    }

    private func updateCutout() {
        // Figure out where the cutout ends up in layer coordinates.
        let roiRectTransform = bottomToTopTransform.concatenating(uiRotationTransform)
        let cutout = previewView.videoPreviewLayer.layerRectConverted(
            fromMetadataOutputRect: regionOfInterest
                .applying(roiRectTransform)
        )

        // Create the mask.
        let path = UIBezierPath(rect: cutoutView.frame)
        path.append(UIBezierPath(rect: cutout))
        maskLayer.path = path.cgPath
    }

    private func setupOrientationAndTransform() {
        // Recalculate the affine transform between Vision coordinates and AVF coordinates.

        // Compensate for region of interest.
        let roi = regionOfInterest
        roiToGlobalTransform = CGAffineTransform(translationX: roi.origin.x,
                                                 y: roi.origin.y)
            .scaledBy(x: roi.width, y: roi.height)

        // Compensate for orientation (buffers always come in the same orientation).
        switch currentOrientation {
        case .landscapeLeft:
            textOrientation = CGImagePropertyOrientation.up
            uiRotationTransform = CGAffineTransform.identity
        case .landscapeRight:
            textOrientation = CGImagePropertyOrientation.down
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 1).rotated(by: CGFloat.pi)
        case .portraitUpsideDown:
            textOrientation = CGImagePropertyOrientation.left
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 0).rotated(by: CGFloat.pi / 2)
        default: // We default everything else to .portraitUp
            textOrientation = CGImagePropertyOrientation.right
            uiRotationTransform = CGAffineTransform(translationX: 0, y: 1).rotated(by: -CGFloat.pi / 2)
        }

        // Full Vision ROI to AVF transform.
        visionToAVFTransform = roiToGlobalTransform
            .concatenating(bottomToTopTransform)
            .concatenating(uiRotationTransform)
    }

    private func setupCamera() {
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                          for: AVMediaType.video,
                                                          position: .back) else {
            fatalError("Could not create capture device.")
        }
        self.captureDevice = captureDevice

        // NOTE:
        // Requesting 4k buffers allows recognition of smaller text but will
        // consume more power. Use the smallest buffer size necessary to keep
        // down battery usage.
        if captureDevice.supportsSessionPreset(.hd4K3840x2160) {
            captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
            bufferAspectRatio = 3840.0 / 2160.0
        } else {
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
            bufferAspectRatio = 1920.0 / 1080.0
        }

        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            fatalError("Could not create device input.")
        }

        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }

        // Configure video data output.
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput.videoSettings =
            [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            // NOTE:
            // There is a trade-off to be made here. Enabling stabilization will
            // give temporally more stable results and should help the recognizer
            // converge. But if it's enabled the VideoDataOutput buffers don't
            // match what's displayed on screen, which makes drawing bounding
            // boxes very hard. Disable it in this app to allow drawing detected
            // bounding boxes on screen.
            videoDataOutput.connection(with: AVMediaType.video)?.preferredVideoStabilizationMode = .off
        } else {
            fatalError("Could not add VDO output")
        }

        // Add photo output.
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)

            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = false
        } else {
            fatalError("Could not add photo output to the session")
        }

        // Set zoom and autofocus to help focus on very small text.
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.videoZoomFactor = 1.5
            captureDevice.autoFocusRangeRestriction = .near
            captureDevice.unlockForConfiguration()
        } catch {
            fatalError("Could not set zoom level due to error: \(error)")
        }

        captureSession.startRunning()
    }

    func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = true

        if let firstAvailablePreviewPhotoPixelFormatTypes = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: firstAvailablePreviewPhotoPixelFormatTypes]
        }

        photoOutput.capturePhoto(with: photoSettings, delegate: self)

    }

    // MARK: Bounding box drawing

    private func showBoundingRects(valid validRects: [CGRect], invalid invalidRects: [CGRect]) {
        let layer = self.previewView.videoPreviewLayer
        self.removeBoxes()

        for rect in invalidRects {
            let rect = layer.layerRectConverted(fromMetadataOutputRect: rect.applying(visionToAVFTransform))
            self.draw(rect: rect, color: UIColor.red.cgColor)
        }
        for rect in validRects {
            let rect = layer.layerRectConverted(fromMetadataOutputRect: rect.applying(visionToAVFTransform))
            self.draw(rect: rect, color: UIColor.green.cgColor)
        }
    }

    // Draw a box on screen. Must be called from main queue.
    private var boxLayer = [CAShapeLayer]()
    private func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = color
        layer.borderWidth = 1
        layer.frame = rect
        boxLayer.append(layer)
        previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
    }

    // Remove all drawn boxes. Must be called on main queue.
    private func removeBoxes() {
        for layer in boxLayer {
            layer.removeFromSuperlayer()
        }
        boxLayer.removeAll()
    }

    // MARK: Alert displaying

    private func displayError(_ error: Error) {
        let alertController = UIAlertController(
            title: "Can't read MRZ code",
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        addAlertActionAndPresent(alertController)
    }

    private func addAlertActionAndPresent(_ alertController: UIAlertController) {
        alertController.addAction(.init(title: "OK", style: .cancel, handler: { [ unowned self ] _ in
            self.scanningIsEnabled = true
        }))

        if scanningIsEnabled {
            present(alertController, animated: true)
            scanningIsEnabled = false
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func startClearTimer() {
        clearTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
            self.delegate?.documentVisible(false)
            self.showBoundingRects(valid: [], invalid: [])
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), scanningIsEnabled {
            scanner.scanFrame(
                scanningImage: .pixelBuffer(pixelBuffer),
                orientation: textOrientation,
                regionOfInterest: regionOfInterest,
                minimumTextHeight: 0.1,
                foundBoundingRectsHandler: nil,
                completionHandler: { [weak self] result in
                    switch result {
                    case .success(let scanningResult):
                        print(scanningResult.result)
                        self?.delegate?.documentVisible(true)
                        self?.clearTimer?.invalidate()
                        self?.startClearTimer()
                        self?.showBoundingRects(
                            valid: scanningResult.boundingRects.valid,
                            invalid: scanningResult.boundingRects.invalid
                        )
                    case .failure(let error):
                        self?.displayError(error)
                    }
                }
            )
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate Methods
extension CaptureViewController: AVCapturePhotoCaptureDelegate {


    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            return
        }

        let img = cropCameraImage(image: image, previewLayer: previewView.videoPreviewLayer)
        delegate?.dataReceived(data: img?.pngData() ?? Data())
    }

    func cropCameraImage(image: UIImage, previewLayer: AVCaptureVideoPreviewLayer) -> UIImage? {
        let originalSize: CGSize
        let visibleLayerFrame = previewView.bounds

        // Calculate the fractional size that is shown in the preview
        let metaRect = previewLayer.metadataOutputRectConverted(fromLayerRect: visibleLayerFrame)

        if (image.imageOrientation == .left || image.imageOrientation == .right) {
            // For these images (which are portrait), swap the size of the
            // image, because here the output image is actually rotated
            // relative to what you see on screen.
            originalSize = CGSize(width: image.size.height, height: image.size.width)
        } else {
            originalSize = image.size
        }

        let cropRect: CGRect = CGRect(x: metaRect.origin.x * originalSize.width, y: metaRect.origin.y * originalSize.height, width: metaRect.size.width * originalSize.width, height: metaRect.size.height * originalSize.height).integral

        if let finalCgImage = image.cgImage?.cropping(to: cropRect) {
            let finalImage = UIImage(cgImage: finalCgImage, scale: 1.0, orientation: image.imageOrientation)

            return finalImage.rotate(radians: 0)
        }

        return nil
    }
}

// MARK: - Utility extensions

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeRight
        case .landscapeRight:
            self = .landscapeLeft
        default:
            return nil
        }
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
