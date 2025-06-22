import Foundation
import AVFoundation
import CoreImage

class HDRCameraCapture: NSObject {
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentDevice: AVCaptureDevice?
    private var completionHandler: ((Result<String, Error>) -> Void)?
    
    override init() {
        super.init()
    }
    
    func captureHDRImage(completion: @escaping (Result<String, Error>) -> Void) {
        self.completionHandler = completion
        
        setupCaptureSession { [weak self] result in
            switch result {
            case .success:
                self?.takeHDRPhoto()
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func setupCaptureSession(completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            
            // Set highest quality preset for maximum resolution
            if session.canSetSessionPreset(.photo) {
                session.sessionPreset = .photo
            } else if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
            }
            
            // Get the best camera device (preferably ultra-wide or wide camera)
            guard let device = self.getBestCameraDevice() else {
                DispatchQueue.main.async {
                    completion(.failure(HDRCaptureError.cameraNotAvailable))
                }
                return
            }
            
            self.currentDevice = device
            
            do {
                // Configure camera for HDR
                try device.lockForConfiguration()
                
                // Enable HDR mode if available
                if device.activeFormat.isVideoHDRSupported {
                    device.isVideoHDREnabled = true
                }
                
                // Set exposure mode for better HDR capture
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                
                // Set focus mode
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                
                // Enable wide color capture if supported
                if device.activeFormat.supportedColorSpaces.contains(.P3_D65) {
                    device.activeColorSpace = .P3_D65
                }
                
                device.unlockForConfiguration()
                
                // Create input
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                } else {
                    throw HDRCaptureError.inputNotSupported
                }
                
                // Create photo output
                let photoOutput = AVCapturePhotoOutput()
                
                // Configure photo output for HDR
                if photoOutput.isHDRSupported {
                    photoOutput.isHDREnabled = true
                }
                
                // Enable high resolution capture
                photoOutput.isHighResolutionCaptureEnabled = true
                
                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                    self.photoOutput = photoOutput
                } else {
                    throw HDRCaptureError.outputNotSupported
                }
                
                self.captureSession = session
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func getBestCameraDevice() -> AVCaptureDevice? {
        // Try to get the best available camera
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInUltraWideCamera,
            .builtInWideAngleCamera,
            .builtInTelephotoCamera
        ]
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .back
        )
        
        // Prefer ultra-wide camera for maximum field of view
        for deviceType in deviceTypes {
            if let device = discoverySession.devices.first(where: { $0.deviceType == deviceType }) {
                return device
            }
        }
        
        return nil
    }
    
    private func takeHDRPhoto() {
        guard let photoOutput = self.photoOutput,
              let captureSession = self.captureSession else {
            completionHandler?(.failure(HDRCaptureError.sessionNotReady))
            return
        }
        
        // Start session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            captureSession.startRunning()
            
            // Wait a moment for the session to stabilize
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.performCapture()
            }
        }
    }
    
    private func performCapture() {
        guard let photoOutput = self.photoOutput else {
            completionHandler?(.failure(HDRCaptureError.outputNotReady))
            return
        }
        
        // Configure photo settings for HDR
        let photoSettings = AVCapturePhotoSettings()
        
        // Use HEIF format for better HDR support
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings.format = [AVVideoCodecKey: AVVideoCodecType.hevc]
        }
        
        // Enable HDR
        if photoOutput.isHDRSupported {
            photoSettings.isHDREnabled = true
        }
        
        // Enable high resolution
        photoSettings.isHighResolutionPhotoEnabled = true
        
        // Capture photo
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    private func cleanup() {
        captureSession?.stopRunning()
        captureSession = nil
        photoOutput = nil
        currentDevice = nil
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension HDRCameraCapture: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { cleanup() }
        
        if let error = error {
            completionHandler?(.failure(error))
            return
        }
        
        // Process the captured photo to HDR binary format
        processHDRPhoto(photo) { [weak self] result in
            self?.completionHandler?(result)
        }
    }
    
    private func processHDRPhoto(_ photo: AVCapturePhoto, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Get the image data
                guard let imageData = photo.fileDataRepresentation() else {
                    throw HDRCaptureError.imageDataNotAvailable
                }
                
                // Create CIImage from the captured photo
                guard let ciImage = CIImage(data: imageData) else {
                    throw HDRCaptureError.imageProcessingFailed
                }
                
                // Create CIContext with extended color space for HDR processing
                let ciContext = CIContext(options: [
                    .workingColorSpace: CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!,
                    .outputColorSpace: CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
                ])
                
                // Get image dimensions
                let extent = ciImage.extent
                let width = Int(extent.width)
                let height = Int(extent.height)
                
                // Create buffer for float32 RGBA data
                let bytesPerPixel = 16 // 4 channels * 4 bytes per float
                let bytesPerRow = width * bytesPerPixel
                
                // Allocate buffer for HDR pixel data
                let pixelData = UnsafeMutablePointer<Float>.allocate(capacity: width * height * 4)
                defer { pixelData.deallocate() }
                
                // Create bitmap context with float components
                let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!
                let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
                
                guard let context = CGContext(
                    data: pixelData,
                    width: width,
                    height: height,
                    bitsPerComponent: 32,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo.rawValue
                ) else {
                    throw HDRCaptureError.contextCreationFailed
                }
                
                // Render the image to the float context
                let cgImage = ciContext.createCGImage(ciImage, from: extent, format: .RGBAf, colorSpace: colorSpace)!
                context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
                
                // Create temporary file path
                let tempDir = NSTemporaryDirectory()
                let fileName = "hdr_camera_capture_\(UUID().uuidString).hdrbin"
                let filePath = (tempDir as NSString).appendingPathComponent(fileName)
                
                // Save using HDRBinWriter
                try HDRBinWriter.writeHDRImage(
                    toPath: filePath,
                    width: width,
                    height: height,
                    pixelData: pixelData
                )
                
                DispatchQueue.main.async {
                    completion(.success(filePath))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Error Types
enum HDRCaptureError: Error, LocalizedError {
    case cameraNotAvailable
    case inputNotSupported
    case outputNotSupported
    case sessionNotReady
    case outputNotReady
    case imageDataNotAvailable
    case imageProcessingFailed
    case contextCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera not available for HDR capture"
        case .inputNotSupported:
            return "Camera input not supported"
        case .outputNotSupported:
            return "Photo output not supported"
        case .sessionNotReady:
            return "Capture session not ready"
        case .outputNotReady:
            return "Photo output not ready"
        case .imageDataNotAvailable:
            return "Image data not available from captured photo"
        case .imageProcessingFailed:
            return "Failed to process captured image"
        case .contextCreationFailed:
            return "Failed to create HDR processing context"
        }
    }
}