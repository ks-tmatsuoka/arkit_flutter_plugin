import Foundation
import ARKit

class HDRCaptureWorker {
    static let shared = HDRCaptureWorker()
    
    private let workQueue = DispatchQueue(label: "com.arkitflutter.hdrcapture.worker", qos: .userInitiated)
    private let semaphore = DispatchSemaphore(value: 0)
    private var captureResult: Result<String, Error>?
    
    private init() {}
    
    func captureHDRWithARSessionPause(sceneView: ARSCNView) -> Result<String, Error> {
        // Reset previous result
        captureResult = nil
        
        // Execute capture on worker thread
        workQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Check AR session state
                let wasRunning = sceneView.session.currentFrame != nil
                
                // Pause AR session on main thread
                if wasRunning {
                    DispatchQueue.main.sync {
                        sceneView.session.pause()
                    }
                    // Wait for session to pause
                    Thread.sleep(forTimeInterval: 0.5)
                }
                
                // Perform HDR capture
                let filePath = try HDRCameraCaptureSync.captureHDRImageSync()
                
                // Resume AR session on main thread
                if wasRunning {
                    DispatchQueue.main.sync {
                        sceneView.session.run(sceneView.session.configuration ?? ARWorldTrackingConfiguration())
                    }
                }
                
                self.captureResult = .success(filePath)
                
            } catch {
                // Ensure AR session is resumed even on error
                let wasRunning = sceneView.session.currentFrame != nil
                if wasRunning {
                    DispatchQueue.main.sync {
                        sceneView.session.run(sceneView.session.configuration ?? ARWorldTrackingConfiguration())
                    }
                }
                
                self.captureResult = .failure(error)
            }
            
            // Signal completion
            self.semaphore.signal()
        }
        
        // Wait for capture to complete (with timeout)
        let timeout = DispatchTime.now() + .seconds(30)
        let waitResult = semaphore.wait(timeout: timeout)
        
        if waitResult == .timedOut {
            return .failure(HDRCaptureWorkerError.timeout)
        }
        
        return captureResult ?? .failure(HDRCaptureWorkerError.noResult)
    }
}

enum HDRCaptureWorkerError: LocalizedError {
    case timeout
    case noResult
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "HDR capture timed out after 30 seconds"
        case .noResult:
            return "HDR capture completed but no result was available"
        }
    }
}