import Foundation
import AVFoundation
import CoreImage
import UIKit
import Photos

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var currentFrame: CGImage?
    @Published var activeFilter: String = "None"

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let context = CIContext()

    // CoreImage Filters based on LUTs
    var luts: [String: CIFilter] = [:]

    override init() {
        super.init()
        setupSession()
        loadLUTs()
    }

    func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoInput) else {
            captureSession.commitConfiguration()
            return
        }

        captureSession.addInput(videoInput)

        if captureSession.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            // Specify BGRA for CoreImage processing
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            captureSession.addOutput(videoOutput)

            // Fix orientation
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }

        captureSession.commitConfiguration()
    }

    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    // Parses a .cube file and returns a CIColorCube filter
    func parseCubeFile(url: URL) -> CIFilter? {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)

            var size = 0
            // CoreImage expects data in BGRA format where R varies fastest, but .cube files vary R fastest too.
            // Wait, actually, CoreImage CIColorCube expects the elements to be organized such that:
            // "The data must be organized in memory such that the blue component changes most rapidly."
            // But standard .cube files have Red changing most rapidly.

            var rawCubeData = [[Float]]()

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("LUT_3D_SIZE") {
                    let parts = trimmed.components(separatedBy: .whitespaces)
                    if parts.count == 2, let s = Int(parts[1]) {
                        size = s
                    }
                } else if let firstChar = trimmed.first, firstChar.isNumber || firstChar == "-" || firstChar == "." {
                    let components = trimmed.components(separatedBy: .whitespaces).compactMap { Float($0) }
                    if components.count == 3 {
                        rawCubeData.append(components)
                    }
                }
            }

            guard size > 0, rawCubeData.count == size * size * size else { return nil }

            var sortedCubeData = [Float]()
            // Rearrange from .cube (R fastest) to CIColorCube (R, G, B order, but B varies fastest in 3D memory)
            for r in 0..<size {
                for g in 0..<size {
                    for b in 0..<size {
                        let originalIndex = r + g * size + b * size * size
                        let components = rawCubeData[originalIndex]
                        // CoreImage expects R, G, B, A order for each pixel
                        sortedCubeData.append(components[0]) // R
                        sortedCubeData.append(components[1]) // G
                        sortedCubeData.append(components[2]) // B
                        sortedCubeData.append(1.0)           // A
                    }
                }
            }

            // Safe copy of data to avoid dangling pointers
            let data = sortedCubeData.withUnsafeBufferPointer { Data(buffer: $0) }

            let filter = CIFilter(name: "CIColorCube")
            filter?.setValue(size, forKey: "inputCubeDimension")
            filter?.setValue(data, forKey: "inputCubeData")

            return filter
        } catch {
            print("Error reading cube file: \(error)")
            return nil
        }
    }

    func loadLUTs() {
        let countries = ["Japan", "Netherlands", "Taiwan", "Germany", "France"]
        for country in countries {
            if let lutUrl = Bundle.main.url(forResource: "\(country)Filter", withExtension: "cube") {
                if let filter = parseCubeFile(url: lutUrl) {
                    luts[country] = filter
                } else {
                    print("Failed to parse LUT for \(country)")
                }
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Apply active filter
        if activeFilter != "None", let filter = luts[activeFilter] {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            if let outputImage = filter.outputImage {
                ciImage = outputImage
            }
        }

        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            DispatchQueue.main.async {
                self.currentFrame = cgImage
            }
        }
    }

    func takePhoto() {
        guard let currentFrame = currentFrame else { return }

        let image = UIImage(cgImage: currentFrame)

        // Request authorization for Photo Library (Read/Write)
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    if success {
                        print("Successfully saved photo to library")
                    } else if let error = error {
                        print("Error saving photo: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Photo library access denied")
            }
        }
    }
}
