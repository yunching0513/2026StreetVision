import Foundation
import CoreImage

enum FilmStyle: String, CaseIterable {
    case none = "None"
    case kodakPortra400 = "Portra 400"
    case fujiSuperia400 = "Superia 400"
    case kodakGold200 = "Gold 200"
    case fujiPro400H = "Pro 400H"
    case ilfordHP5 = "Ilford HP5"

    struct FilterParams {
        var brightness: Float
        var contrast: Float
        var saturation: Float
        var sepia: Float
        var grain: Float
    }

    var params: FilterParams? {
        switch self {
        case .none:
            return nil
        case .kodakPortra400:
            return FilterParams(brightness: 1.05, contrast: 0.95, saturation: 0.90, sepia: 0.15, grain: 0.15)
        case .fujiSuperia400:
            return FilterParams(brightness: 1.0, contrast: 1.10, saturation: 1.15, sepia: 0.05, grain: 0.25)
        case .kodakGold200:
            return FilterParams(brightness: 1.10, contrast: 1.05, saturation: 1.20, sepia: 0.25, grain: 0.20)
        case .fujiPro400H:
            return FilterParams(brightness: 1.15, contrast: 0.85, saturation: 0.80, sepia: 0.0, grain: 0.10)
        case .ilfordHP5:
            return FilterParams(brightness: 1.0, contrast: 1.25, saturation: 0.0, sepia: 0.0, grain: 0.35)
        }
    }

    func apply(to image: CIImage) -> CIImage? {
        guard let p = params else { return image }

        // 1. Color Controls
        let colorFilter = CIFilter(name: "CIColorControls")
        colorFilter?.setValue(image, forKey: kCIInputImageKey)
        // CoreImage Brightness is an offset (-1 to 1). We convert 1.0 -> 0.0, 1.05 -> 0.05
        colorFilter?.setValue(p.brightness - 1.0, forKey: kCIInputBrightnessKey)
        colorFilter?.setValue(p.contrast, forKey: kCIInputContrastKey)
        colorFilter?.setValue(p.saturation, forKey: kCIInputSaturationKey)

        guard let colorOutput = colorFilter?.outputImage else { return nil }

        // 2. Sepia Tone
        var sepiaOutput = colorOutput
        if p.sepia > 0 {
            let sepiaFilter = CIFilter(name: "CISepiaTone")
            sepiaFilter?.setValue(colorOutput, forKey: kCIInputImageKey)
            sepiaFilter?.setValue(p.sepia, forKey: kCIInputIntensityKey)
            if let output = sepiaFilter?.outputImage {
                sepiaOutput = output
            }
        }

        // 3. Film Grain (Noise)
        if p.grain > 0 {
            let noiseFilter = CIFilter(name: "CIRandomGenerator")
            guard let noiseImage = noiseFilter?.outputImage else { return sepiaOutput }

            // Convert random noise (colored) to grayscale and adjust intensity
            let noiseColorFilter = CIFilter(name: "CIColorMatrix")
            let grayVector = CIVector(x: 0, y: 1, z: 0, w: 0)
            noiseColorFilter?.setValue(noiseImage, forKey: kCIInputImageKey)
            noiseColorFilter?.setValue(grayVector, forKey: "inputRVector")
            noiseColorFilter?.setValue(grayVector, forKey: "inputGVector")
            noiseColorFilter?.setValue(grayVector, forKey: "inputBVector")
            let alphaVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(p.grain))
            noiseColorFilter?.setValue(alphaVector, forKey: "inputAVector")

            guard let grayNoise = noiseColorFilter?.outputImage else { return sepiaOutput }

            // Blend noise over image using Hard Light or Overlay
            let blendFilter = CIFilter(name: "CIHardLightBlendMode")
            blendFilter?.setValue(grayNoise.cropped(to: sepiaOutput.extent), forKey: kCIInputImageKey)
            blendFilter?.setValue(sepiaOutput, forKey: kCIInputBackgroundImageKey)

            return blendFilter?.outputImage ?? sepiaOutput
        }

        return sepiaOutput
    }
}
