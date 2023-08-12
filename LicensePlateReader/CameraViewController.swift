//
//  CameraViewController.swift
//  LicensePlateReader
//
//  Created by Arda Doğantemur on 12.08.2023.
//

import AVFoundation
import UIKit
import UIKit

class CameraViewController: UIViewController ,AVCaptureVideoDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate{
    
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var permissionGranted = false // Flag for permission

    //AVFoundation Video Image
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput",
                                                     qos: .userInitiated,
                                                     attributes: [],
                                                     autoreleaseFrequency: .workItem)

    // License Plate Rectangle
    var rectangleOverlayView: RectangleOverlayView!

    // Object Recognition
    var objectRecognition:ModelObjectRecognise?
    var licensePlateRecognition:LicensePlateRecognise?
    
    // Timer
    var timer = Timer()
    
    override func viewDidLoad() {
          checkPermission()
          sessionQueue.async { [unowned self] in
              guard permissionGranted else { return }
              self.setupCaptureSession()
              objectRecognition = ModelObjectRecognise(model: CP_1().model)
              licensePlateRecognition = LicensePlateRecognise()
              self.captureSession.startRunning()
          }
    }
    
    // MARK: - Setup
    // ===============================================================================
    func setupCaptureSession() {
        // Access camera
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera,for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        let videoDataOutput = AVCaptureVideoDataOutput()

        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480

        
        // Add video input
        guard captureSession.canAddInput(videoDeviceInput) else {
            print("Could not add video device input to the session")
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(videoDeviceInput)

        // Add video output
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            captureSession.commitConfiguration()
            return
        }
        
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        
        // Get buffer size to allow for determining recognized license plate positions
        // relative to the video ouput buffer size
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.unlockForConfiguration()
        } catch {
            print(error)
        }
        
        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            photoOutput.isHighResolutionCaptureEnabled = true
            captureSession.addOutput(photoOutput)
        }
    
        captureSession.commitConfiguration()
        
        //Preview Layer
        let screenRect = UIScreen.main.bounds
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
        previewLayer.connection?.videoOrientation = .portrait
        
        DispatchQueue.main.async { [weak self] in
            self?.view.layer.addSublayer(self!.previewLayer)
            self?.rectangleOverlayView = RectangleOverlayView(frame: self!.previewLayer.bounds)
            self?.rectangleOverlayView.backgroundColor = .clear
            self?.view.addSubview(self!.rectangleOverlayView)
        }
    }
    
    // MARK: - Video Delegate
    // ===============================================================================
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        objectRecognition?.startMLRequest(sampleBuffer: sampleBuffer, completion: { results in
            DispatchQueue.main.async {
                let rects = results.map { item in
                    let width = self.previewLayer.bounds.width
                    let height = self.previewLayer.bounds.height
                    let offsetY = (self.previewLayer.bounds.height - height) / 2
                    let scale = CGAffineTransform.identity.scaledBy(x: width, y: height)
                    let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -height - offsetY)
                    let rect = item.boundingBox.applying(scale).applying(transform)
                    return Helpers.addPadding(to: rect, padding: 15.0)
                }
                self.drawPlateRectangle(rects: rects)
            }
        })
    }
    
    // MARK: - Photo Capture Delegate
    // ===============================================================================
    internal func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // dispose system shutter sound
        AudioServicesDisposeSystemSoundID(1108)
    }
       
    internal func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
                
        guard let image = photo.cgImageRepresentation() else {
            return
        }
        
        licensePlateRecognition?.getLicensePlateNumber(image: image, completion: { resuls in
            self.rectangleOverlayView.labelText = resuls
        })
    }
    
    // MARK: - Draw Plate
    // ===============================================================================
    private func drawPlateRectangle(rects:[CGRect])
    {
        self.rectangleOverlayView.rectangleCoordinates = rects.first
        if(rects.first != nil)
        {
            readPlate()
        }
    }
    
    private func readPlate()
    {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = true
        if(timer.isTimePassed(milisec: 500))
        {
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    // MARK: - Permissions
    // ===============================================================================
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
            case .authorized:
                permissionGranted = true
                    
            // Permission has not been requested yet
            case .notDetermined:
                requestPermission()
                        
            default:
                permissionGranted = false
        }
    }
    
    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }

}

extension CGImagePropertyOrientation {
    static var currentRearCameraOrientation: CGImagePropertyOrientation {
        self.init(isUsingFrontFacingCamera: false)
    }
    
    init(isUsingFrontFacingCamera: Bool, deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation) {
        switch deviceOrientation {
        case .portrait:
            self = .right
        case .portraitUpsideDown:
            self = .left
        case .landscapeLeft:
            self = isUsingFrontFacingCamera ? .down : .up
        case .landscapeRight:
            self = isUsingFrontFacingCamera ? .up : .down
        default:
            self = .right
        }
    }
}
